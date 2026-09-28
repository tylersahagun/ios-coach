#!/usr/bin/env bash
# Build (and optionally test) an iOS app on a pinned simulator, then print a short summary.
# Usage: bash verify.sh [--test] [--scheme NAME] [--destination 'platform=iOS Simulator,name=…,OS=…'] [--project PATH]
# Run from the project root. Exits 0 when everything passed, 1 when something failed, 2 on bad usage.
set -u

DO_TEST=0; SCHEME=""; DEST=""; CONTAINER=""
while [ $# -gt 0 ]; do
  case "$1" in
    --test) DO_TEST=1 ;;
    --scheme) SCHEME="${2:-}"; shift ;;
    --destination) DEST="${2:-}"; shift ;;
    --project) CONTAINER="${2:-}"; shift ;;
    -h|--help) sed -n '2,4p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
  shift
done

case "$(xcode-select -p 2>/dev/null)" in
  *CommandLineTools*)
    echo "RESULT: FAIL"
    echo "xcodebuild points at CommandLineTools instead of Xcode."
    echo "Fix (needs the user's password): sudo xcode-select -s /Applications/Xcode.app"
    exit 1 ;;
esac

# Which project to build: a workspace wins over a project (CocoaPods and multi-project setups).
if [ -z "$CONTAINER" ]; then
  CONTAINER=$(find . -maxdepth 3 -name "*.xcworkspace" -not -path "*.xcodeproj/*" -not -path "*/.*/*" 2>/dev/null | head -1)
  [ -z "$CONTAINER" ] && CONTAINER=$(find . -maxdepth 3 -name "*.xcodeproj" -not -path "*/.*/*" 2>/dev/null | head -1)
fi
case "$CONTAINER" in
  *.xcworkspace) FLAG="-workspace" ;;
  *.xcodeproj) FLAG="-project" ;;
  *) echo "RESULT: FAIL"; echo "No .xcodeproj or .xcworkspace found. Run this from the project folder."; exit 1 ;;
esac

if [ -z "$SCHEME" ]; then
  SCHEME=$(xcodebuild "$FLAG" "$CONTAINER" -list -json 2>/dev/null | NAME="$(basename "${CONTAINER%.*}")" python3 -c '
import json, os, sys
try:
    info = (lambda d: d.get("project") or d.get("workspace") or {})(json.load(sys.stdin))
except Exception:
    sys.exit(0)
schemes = info.get("schemes", [])
name = os.environ["NAME"]
print(name if name in schemes else (schemes[0] if schemes else ""))
')
  [ -z "$SCHEME" ] && { echo "RESULT: FAIL"; echo "Couldn't find a scheme in $CONTAINER. Pass one with --scheme."; exit 1; }
fi

if [ -z "$DEST" ]; then
  # Match the simulator to the iOS SDK in the active Xcode, so a newer beta runtime can't sneak in.
  DEST=$(xcrun simctl list devices available -j 2>/dev/null | SIM_SDK="$(xcrun --sdk iphonesimulator --show-sdk-version 2>/dev/null)" python3 -c '
import json, os, re, sys
try:
    devices = json.load(sys.stdin)["devices"]
except Exception:
    sys.exit(0)
runtimes = {}
for key, devs in devices.items():
    m = re.search(r"iOS-(\d+)-(\d+)", key)
    phones = [d["name"] for d in devs if d.get("name", "").startswith("iPhone")]
    if m and phones:
        runtimes[(int(m.group(1)), int(m.group(2)))] = phones
if not runtimes:
    sys.exit(0)
m = re.match(r"(\d+)\.(\d+)", os.environ.get("SIM_SDK", ""))
sdk = (int(m.group(1)), int(m.group(2))) if m else max(runtimes)
v = max([r for r in runtimes if r <= sdk] or runtimes)
order = ["iPhone 17", "iPhone 17 Pro", "iPhone 16", "iPhone 16 Pro", "iPhone 15"]
name = sorted(runtimes[v], key=lambda n: order.index(n) if n in order else len(order))[0]
print(f"platform=iOS Simulator,name={name},OS={v[0]}.{v[1]}")
')
  [ -z "$DEST" ] && { echo "RESULT: FAIL"; echo "No iPhone simulator is installed. Add one in Xcode > Settings > Components."; exit 1; }
  echo "(No --destination given; using $DEST. Pin it in AGENTS.md.)"
fi

ACTION="build"; [ "$DO_TEST" -eq 1 ] && ACTION="test"
LOG="$(mktemp -t ios-coach-verify).log"
echo "Running: xcodebuild $FLAG $CONTAINER -scheme $SCHEME -destination '$DEST' $ACTION"
echo "(This usually takes 1-5 minutes.)"
START=$(date +%s)
# Simulator builds don't need signing; turning it off avoids team and profile errors that aren't real problems.
xcodebuild "$FLAG" "$CONTAINER" -scheme "$SCHEME" -destination "$DEST" CODE_SIGNING_ALLOWED=NO "$ACTION" >"$LOG" 2>&1
STATUS=$?
ELAPSED=$(( $(date +%s) - START ))
# Show paths relative to the project. xcodebuild may report /tmp where pwd says /private/tmp.
REAL="$(pwd -P)/"
relpath() { sed -e "s#$(pwd)/##g" -e "s#$REAL##g" -e "s#${REAL#/private}##g"; }

echo
if [ "$STATUS" -eq 0 ]; then echo "RESULT: PASS"; else echo "RESULT: FAIL"; fi
echo "What ran: $ACTION, scheme $SCHEME, $DEST ($ELAPSED s)"

COMPILE_ERRORS=$(grep -E '^/.+:[0-9]+:[0-9]+: error: ' "$LOG" | relpath | sort -u)
if [ -n "$COMPILE_ERRORS" ]; then
  echo
  echo "Compile errors ($(printf '%s\n' "$COMPILE_ERRORS" | wc -l | tr -d ' ') unique, first 10). The first one often causes the rest:"
  printf '%s\n' "$COMPILE_ERRORS" | head -10 | sed 's/^/  /'
fi

OTHER_ERRORS=$(grep -E '^(xcodebuild: )?error:|^[[:space:]]*error: ' "$LOG" | grep -v -E '^/.+:[0-9]+:[0-9]+: error: ' | relpath | sort -u | head -6)
if [ -n "$OTHER_ERRORS" ]; then
  echo
  echo "Other errors:"
  printf '%s\n' "$OTHER_ERRORS" | sed 's/^/  /'
fi
if grep -q -E "Unable to find a (destination|device) matching" "$LOG"; then
  echo "Hint: that simulator isn't installed. See what is: xcrun simctl list devices available"
fi

if [ "$DO_TEST" -eq 1 ]; then
  echo
  XC_SUMMARY=$(grep -E 'Executed [0-9]+ tests?, with [0-9]+ failures?' "$LOG" | tail -1 | sed -E 's/^[[:space:]]+//')
  ST_SUMMARY=$(grep -E 'Test run with [0-9]+ tests?' "$LOG" | tail -1 | sed -E 's/^[[:space:]]+//')
  # Swift Testing projects still print an empty XCTest summary; only show it when XCTest ran something.
  case "$XC_SUMMARY" in "Executed 0 tests"*) [ -n "$ST_SUMMARY" ] && XC_SUMMARY="" ;; esac
  [ -n "$XC_SUMMARY" ] && echo "XCTest: $XC_SUMMARY"
  [ -n "$ST_SUMMARY" ] && echo "Swift Testing: $ST_SUMMARY"
  [ -z "$XC_SUMMARY$ST_SUMMARY" ] && echo "Tests: no test results found (the build may have failed first, or there are no tests)."
  FAILS=$( { grep -E "Test Case '.*' failed" "$LOG"; grep -E '✘ Test .*(failed|recorded an issue)' "$LOG" | grep -v '✘ Test run with'; } | relpath | sort -u | head -10)
  if [ -n "$FAILS" ]; then
    echo "Failing tests (first 10):"
    printf '%s\n' "$FAILS" | sed 's/^/  /'
  fi
fi

WARNINGS=$(grep -E ': warning: ' "$LOG" | sort -u | wc -l | tr -d ' ')
echo
echo "Warnings: $WARNINGS unique"
echo "Full log: $LOG"
[ "$STATUS" -eq 0 ] && exit 0 || exit 1
