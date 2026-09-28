#!/usr/bin/env bash
# SessionStart hook. If the session is in an iOS project that iOS Coach hasn't set up yet,
# print a note that Codex adds to its context so it offers the setup interview.
# Read-only. Prints nothing (and so adds nothing) in any other folder.
set -u

MARKER="ios-coach:setup-complete"

# Only speak up inside an Apple-platform project (the project file sits at most one folder down).
if ! find . -maxdepth 2 \( -name "*.xcodeproj" -o -name "*.xcworkspace" -o -name "Package.swift" \) \
     -not -path "*/.build/*" 2>/dev/null | grep -q .; then
  exit 0
fi

if [ -f AGENTS.md ] && grep -q "$MARKER" AGENTS.md 2>/dev/null; then
  exit 0
fi

cat <<'EOF'
iOS Coach: this iOS project has not been set up with iOS Coach yet (there is no AGENTS.md containing the ios-coach setup marker).
Offer the $start-here setup interview once this session, in one or two sentences: it takes about 10 minutes, asks one question at a time, and writes an AGENTS.md so future sessions already know the app and how the user likes to work.
If the user's first message is a greeting or open-ended, offer it right away. If it is a specific task, do the task first and make the offer at the end of that reply. If they decline, do not offer again this session.
EOF
