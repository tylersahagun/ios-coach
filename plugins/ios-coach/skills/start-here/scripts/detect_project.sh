#!/usr/bin/env bash
# Read-only snapshot of an iOS project for the iOS Coach setup interview.
# Usage: bash detect_project.sh [project-root]   (defaults to the current folder)
# Changes nothing, so it's safe to run any time.
set -u
ROOT="${1:-.}"
cd "$ROOT" 2>/dev/null || { echo "Can't open folder: $ROOT"; exit 1; }

section() { printf '\n## %s\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

# NUL-separated list of files matching a find expression, skipping build output and dependencies.
files0() {
  find . \( \( -type d -name ".?*" \) -o -name DerivedData -o -name Pods -o -name node_modules \
         -o -name build -o -name "*.xcassets" -o -name "*.xcodeproj" \) -prune -o \( "$@" \) -type f -print0 2>/dev/null
}

echo "# iOS Coach project snapshot"
echo "Folder: $(pwd)"

# --- Xcode -------------------------------------------------------------------------------------
section "Xcode"
DEV_DIR=$(xcode-select -p 2>/dev/null || true)
echo "Active developer folder: ${DEV_DIR:-none}"
case "$DEV_DIR" in
  *CommandLineTools*)
    echo "PROBLEM: command-line tools point at CommandLineTools, not Xcode, so xcodebuild won't work."
    echo "Fix (needs the user's password): sudo xcode-select -s /Applications/Xcode.app" ;;
  *[Bb]eta*)
    echo "NOTE: the active Xcode is a beta. Beta builds can't be uploaded to TestFlight or the App Store." ;;
esac
SIM_SDK=""
if have xcodebuild && xcodebuild -version >/dev/null 2>&1; then
  xcodebuild -version 2>/dev/null | head -2
  SIM_SDK=$(xcrun --sdk iphonesimulator --show-sdk-version 2>/dev/null || true)
  echo "iOS Simulator SDK: ${SIM_SDK:-unknown}"
else
  echo "xcodebuild isn't usable here."
fi

# --- Projects ----------------------------------------------------------------------------------
section "Projects"
WORKSPACE=$(find . -maxdepth 3 -name "*.xcworkspace" -not -path "*.xcodeproj/*" -not -path "*/.*/*" 2>/dev/null | head -1)
PROJECT=$(find . -maxdepth 3 -name "*.xcodeproj" -not -path "*/.*/*" 2>/dev/null | head -1)
PACKAGE=$(find . -maxdepth 2 -name Package.swift -not -path "*/.*/*" 2>/dev/null | head -1)
[ -n "$WORKSPACE" ] && echo "Workspace: $WORKSPACE (open and build this one, not the .xcodeproj)"
[ -n "$PROJECT" ] && echo "Project: $PROJECT"
[ -n "$PACKAGE" ] && echo "Swift package: $PACKAGE"
[ -z "$WORKSPACE$PROJECT$PACKAGE" ] && echo "No Xcode project or Swift package found within 3 folders of here."

CONTAINER_FLAG=""; CONTAINER=""
if [ -n "$WORKSPACE" ]; then CONTAINER_FLAG="-workspace"; CONTAINER="$WORKSPACE"
elif [ -n "$PROJECT" ]; then CONTAINER_FLAG="-project"; CONTAINER="$PROJECT"; fi

TEST_TARGETS=""
if [ -n "$CONTAINER" ] && have xcodebuild; then
  LIST_OUT=$(xcodebuild "$CONTAINER_FLAG" "$CONTAINER" -list -json 2>/dev/null | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    print("Could not read schemes (xcodebuild -list failed)."); sys.exit(0)
info = data.get("project") or data.get("workspace") or {}
print("Schemes: " + (", ".join(info.get("schemes", [])) or "none"))
targets = info.get("targets", [])
if targets:
    print("Targets: " + ", ".join(targets))
tests = [t for t in targets if "Tests" in t]
if tests:
    print("TEST_TARGETS=" + " ".join(tests))
')
  printf '%s\n' "$LIST_OUT" | grep -v '^TEST_TARGETS='
  TEST_TARGETS=$(printf '%s\n' "$LIST_OUT" | sed -n 's/^TEST_TARGETS=//p')
fi

if [ -n "$PROJECT" ] && [ -f "$PROJECT/project.pbxproj" ]; then
  PBX="$PROJECT/project.pbxproj"
  settings() { grep -o "$1 = [^;]*" "$PBX" | sed "s/$1 = //; s/\"//g" | sort -u | tr '\n' ' '; }
  echo "Minimum iOS: $(settings IPHONEOS_DEPLOYMENT_TARGET)"
  echo "Bundle IDs: $(settings PRODUCT_BUNDLE_IDENTIFIER)"
  echo "Swift language mode: $(settings SWIFT_VERSION)"
  if grep -q "DEVELOPMENT_TEAM = [A-Z0-9]" "$PBX"; then echo "Signing team: set"; else echo "Signing team: not set (fine for the simulator; needed for a real iPhone)"; fi
  if grep -q PBXFileSystemSynchronizedRootGroup "$PBX"; then
    echo "Folder syncing: on (Xcode 16+). New files inside the app's folders are picked up without editing project.pbxproj."
  else
    echo "Folder syncing: off. New files must be added to the target in Xcode, or project.pbxproj edited, or they won't build."
  fi
fi

# --- Code --------------------------------------------------------------------------------------
section "Code"
SWIFT_COUNT=$(files0 -name "*.swift" | tr -cd '\0' | wc -c | tr -d ' ')
echo "Swift files: $SWIFT_COUNT"
if [ "$SWIFT_COUNT" -gt 0 ]; then
  echo "Most-imported frameworks:"
  files0 -name "*.swift" | xargs -0 grep -h -E '^(@testable +)?import +[A-Za-z_]+' 2>/dev/null \
    | sed -E 's/^@testable +//; s/^import +//; s/[^A-Za-z_].*$//' | sort | uniq -c | sort -rn | head -12 | sed 's/^/  /'
  echo "Top-level folders with Swift code:"
  files0 -name "*.swift" | tr '\0' '\n' | awk -F/ 'NF>2 {print $2"/"$3} NF==2 {print "."}' \
    | sed -E 's#/[^/]*\.swift$##' | sort | uniq -c | sort -rn | head -12 | sed 's/^/  /'
fi

# --- Saved data --------------------------------------------------------------------------------
section "Saved data"
MODELS=$(files0 -name "*.swift" | xargs -0 grep -h -A3 "@Model" 2>/dev/null | grep -oE "class +[A-Za-z_]+" | awk '{print $2}' | sort -u | tr '\n' ' ')
[ -n "$MODELS" ] && echo "SwiftData @Model classes: $MODELS"
CD_MODELS=$(find . -name "*.xcdatamodeld" -not -path "*/.build/*" 2>/dev/null | tr '\n' ' ')
[ -n "$CD_MODELS" ] && echo "Core Data models: $CD_MODELS"
count_uses() { files0 -name "*.swift" | xargs -0 grep -l -E "$1" 2>/dev/null | wc -l | tr -d ' '; }
echo "Files using UserDefaults/@AppStorage: $(count_uses 'UserDefaults|@AppStorage')"
echo "Files using CloudKit/iCloud: $(count_uses 'CloudKit|cloudKitDatabase|NSUbiquitous')"
CD_CODE=$(count_uses 'NSPersistentContainer|NSPersistentCloudKitContainer|NSManagedObjectModel\(')
[ -z "$CD_MODELS" ] && [ "$CD_CODE" -gt 0 ] && echo "Core Data set up in code (no .xcdatamodeld): $CD_CODE files"
[ -z "$MODELS$CD_MODELS" ] && [ "$CD_CODE" -eq 0 ] && echo "No SwiftData or Core Data model found."
echo "Bundled data files (largest first):"
files0 \( -name "*.json" -o -name "*.csv" -o -name "*.tsv" -o -name "*.txt" -o -name "*.sqlite" -o -name "*.db" -o -name "*.u8" \) \
  | xargs -0 ls -lS 2>/dev/null | awk '{size=$5; $1=$2=$3=$4=$5=$6=$7=$8=""; sub(/^ +/, ""); printf "  %8.1f KB  %s\n", size/1024, $0}' | head -10

# --- Tests -------------------------------------------------------------------------------------
section "Tests"
TEST_FILES=$(files0 -name "*Tests.swift" | tr -cd '\0' | wc -c | tr -d ' ')
echo "Test files: $TEST_FILES"
[ -n "$TEST_TARGETS" ] && echo "Test targets: $TEST_TARGETS"
if [ "$TEST_FILES" -gt 0 ]; then
  echo "XCTest files: $(files0 -name "*.swift" | xargs -0 grep -l '^import XCTest' 2>/dev/null | wc -l | tr -d ' ')," \
       "Swift Testing files: $(files0 -name "*.swift" | xargs -0 grep -l '^import Testing' 2>/dev/null | wc -l | tr -d ' ')"
fi

# --- Chinese-language content ------------------------------------------------------------------
section "Chinese-language content"
files0 \( -name "*.swift" -o -name "*.json" -o -name "*.csv" -o -name "*.tsv" -o -name "*.txt" -o -name "*.u8" \
          -o -name "*.strings" -o -name "*.xcstrings" -o -name "*.plist" \) | python3 -c '
import sys, re, collections
paths = [p for p in sys.stdin.buffer.read().decode("utf-8", "replace").split("\0") if p]
cjk = re.compile(r"[㐀-䶿一-鿿]")
tone = re.compile(r"[āǎēěīǐōǒūǔǖǘǚǜ]")
tone_num = re.compile(r"\b(?:zh|ch|sh|[bpmfdtnlgkhjqxrzcsyw])?[aeiouüv]{1,3}(?:ng|n|r)?[1-5]\b")
# Everyday characters whose Simplified and Traditional forms differ.
simp, trad = set("们这说学语汉国爱书时会过还发东车见门长马鸟鱼"), set("們這說學語漢國愛書時會過還發東車見門長馬鳥魚")
keywords = ["pinyin", "hanzi", "CEDICT", "HSK", "zh-Hans", "zh-Hant", "AVSpeechSynthesizer"]
totals, s_count, t_count, tone_files, num_files = collections.Counter(), 0, 0, 0, 0
kw_hits, voices = collections.Counter(), set()
for p in paths:
    try:
        with open(p, "rb") as f:
            text = f.read(20_000_000).decode("utf-8", "ignore")
    except OSError:
        continue
    n = len(cjk.findall(text))
    if n:
        totals[p] = n
        s_count += sum(text.count(c) for c in simp)
        t_count += sum(text.count(c) for c in trad)
    if tone.search(text): tone_files += 1
    if n and len(tone_num.findall(text)) >= 5: num_files += 1
    for k in keywords:
        if k.lower() in text.lower(): kw_hits[k] += 1
    if p.endswith(".swift"):
        voices.update(re.findall(r"AVSpeechSynthesisVoice\(language:\s*\"([^\"]+)\"", text))
if not totals and not kw_hits:
    print("No Chinese text or Chinese-learning keywords found.")
    sys.exit(0)
print(f"Chinese characters found in {len(totals)} files. Most:")
for p, n in totals.most_common(6):
    print(f"  {n:>8}  {p}")
if s_count or t_count:
    lean = "mostly Simplified" if s_count > 3 * t_count else "mostly Traditional" if t_count > 3 * s_count else "a mix of Simplified and Traditional"
    print(f"Character forms: {lean} (sample counts: {s_count} Simplified, {t_count} Traditional)")
print(f"Files with tone-mark pinyin (mā): {tone_files}; files with Chinese and tone-number pinyin (ma1): {num_files}")
if kw_hits:
    print("Keywords: " + ", ".join(f"{k} ({v} files)" for k, v in kw_hits.most_common()))
if voices:
    print("Speech voices requested: " + ", ".join(sorted(voices)))
    if any(v.lower().startswith("zh-hk") for v in voices):
        print("NOTE: zh-HK is a Cantonese voice. Mandarin is zh-CN (mainland) or zh-TW (Taiwan).")
'

# --- Simulator ---------------------------------------------------------------------------------
section "Simulator to pin"
if have xcrun; then
  xcrun simctl list devices available -j 2>/dev/null | SIM_SDK="$SIM_SDK" python3 -c '
import json, os, re, sys
try:
    devices = json.load(sys.stdin)["devices"]
except Exception:
    print("Could not list simulators."); sys.exit(0)
def ver(key):
    m = re.search(r"iOS-(\d+)-(\d+)", key)
    return (int(m.group(1)), int(m.group(2))) if m else None
runtimes = {}
for key, devs in devices.items():
    v = ver(key)
    phones = [d["name"] for d in devs if d.get("name", "").startswith("iPhone")]
    if v and phones:
        runtimes[v] = phones
if not runtimes:
    print("No iPhone simulators installed. Install one in Xcode > Settings > Components."); sys.exit(0)
print("Installed iOS simulator versions: " + ", ".join(f"{a}.{b}" for a, b in sorted(runtimes)))
sdk = os.environ.get("SIM_SDK", "")
m = re.match(r"(\d+)\.(\d+)", sdk)
sdk_v = (int(m.group(1)), int(m.group(2))) if m else max(runtimes)
candidates = [v for v in runtimes if v <= sdk_v] or sorted(runtimes)
pick_v = max(candidates)
names = runtimes[pick_v]
def rank(name):
    order = ["iPhone 17", "iPhone 17 Pro", "iPhone 16", "iPhone 16 Pro", "iPhone 15"]
    return order.index(name) if name in order else len(order)
name = sorted(names, key=rank)[0]
print(f"Suggested pinned destination: platform=iOS Simulator,name={name},OS={pick_v[0]}.{pick_v[1]}")
newer = [v for v in runtimes if v > sdk_v]
if newer:
    print("NOTE: newer iOS " + ", ".join(f"{a}.{b}" for a, b in sorted(newer)) + " simulators are installed (likely betas). A destination without OS= would pick them silently.")
'
fi

# --- Git and secrets ---------------------------------------------------------------------------
section "Git"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Branch: $(git branch --show-current 2>/dev/null)"
  REMOTE=$(git remote get-url origin 2>/dev/null | sed -E 's#//[^/@]*@#//#')
  echo "Remote: ${REMOTE:-none (the code is only on this Mac)}"
  echo "Uncommitted changes: $(git status --porcelain 2>/dev/null | wc -l | tr -d ' ') files"
  echo "Last commit: $(git log -1 --format='%cr: %s' 2>/dev/null || echo none)"
  TRACKED=$(git ls-files 2>/dev/null | grep -i -E '(\.p8|\.p12|\.pem|\.mobileprovision|\.env|Secrets\.plist|GoogleService-Info\.plist)$' || true)
  [ -n "$TRACKED" ] && { echo "WARNING: files that usually hold secrets are committed to git:"; echo "$TRACKED" | sed 's/^/  /'; }
  [ -f .gitignore ] || echo "No .gitignore. Xcode's per-user files and build output may get committed."
else
  echo "Not a git repository. Changes can't be undone or backed up yet."
fi

section "Keys in code"
KEY_HITS=$(files0 \( -name "*.swift" -o -name "*.plist" -o -name "*.json" \) \
  | xargs -0 grep -H -n -E '(^|[^A-Za-z0-9_-])sk-(proj-)?[A-Za-z0-9_-]{20,}|AIza[0-9A-Za-z_-]{35}|-----BEGIN [A-Z ]*PRIVATE KEY-----' 2>/dev/null | cut -d: -f1,2)
if [ -n "$KEY_HITS" ]; then
  echo "WARNING: text that looks like an API key or private key (values not shown):"
  echo "$KEY_HITS" | sed 's/^/  /'
else
  echo "None found."
fi

# --- Existing agent notes ----------------------------------------------------------------------
section "Agent notes"
if [ -f AGENTS.md ]; then
  if grep -q "ios-coach:setup-complete" AGENTS.md; then echo "AGENTS.md: present, set up by iOS Coach ($(wc -l < AGENTS.md | tr -d ' ') lines)"
  else echo "AGENTS.md: present, not from iOS Coach ($(wc -l < AGENTS.md | tr -d ' ') lines). Merge into it; don't replace it."; fi
else
  echo "AGENTS.md: none yet"
fi
for f in CLAUDE.md .cursorrules .github/copilot-instructions.md; do [ -e "$f" ] && echo "Also found: $f"; done
[ -d .cursor/rules ] && echo "Also found: .cursor/rules/"
exit 0
