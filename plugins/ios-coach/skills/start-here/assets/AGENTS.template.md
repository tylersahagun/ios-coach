<!-- ios-coach:setup-complete -->
# {{App name}}: notes for Codex

## What this app is
{{One short paragraph: what the app does, who it's for (just me / family and friends / App Store),
and where it stands (simulator only / on my iPhone / on TestFlight).}}

## About me
- Background: {{what I've built or coded before; languages I know}}
- New to: {{e.g. Swift, Xcode, git, signing}}
- Explanations: {{short | with the reasons}}
- I run the app by: {{the Play button in Xcode | asking Codex}}
- I also use ChatGPT for code: {{yes, and I paste it in | no}}

## How to work with me
1. Take small steps. Before a change that touches more than two files, say what you're about to
   do and why.
2. After every change, explain in three plain bullets: what changed, why, and how I can see it in
   the app.
3. Build before saying "done" (`$verify`). If it doesn't build, it isn't done.
4. When a new concept comes up, name it and define it in one sentence. Use comparisons to
   {{my background}} when they help.
5. Ask me before doing anything on the "Ask first" list below.
6. Never make a failing build or test pass by deleting code or tests, commenting things out, or
   silencing warnings. Explain the real problem instead.
7. If I paste in code from ChatGPT, check that it fits this project before using it.

## Commands (checked {{date}})
- Open in Xcode: `open {{Project}}.{{xcodeproj|xcworkspace}}`
- Build: `xcodebuild {{-project X.xcodeproj | -workspace X.xcworkspace}} -scheme {{Scheme}} -destination '{{destination}}' build`
- Test: {{the test command, or "no tests yet"}}
- Simulator: always use `{{destination}}`. It's pinned so a new Xcode or a beta iOS can't quietly
  change what we build against.

## Where things live
{{Short map of folders that exist: folder → what's in it.}}

## Ask first (never do these without a yes)
- Signing, team, bundle identifier, capabilities, or entitlements (Xcode's "Signing &
  Capabilities" tab).
- Changing how data is saved (`@Model` classes, or Core Data entities). On a phone that already has
  data, this can lose it or stop the app from opening. Explain the risk and the plan first.
- Deleting or renaming files, or moving folders.
- Hand-editing `project.pbxproj`. Prefer adding files inside folders Xcode already tracks.
- Adding a package or other outside dependency.
- API keys, passwords, or accounts. These never go into code or git.
- App Store Connect, TestFlight, or version and build numbers.

## App decisions
{{Only what's decided. For the flashcard app: characters (Simplified / Traditional), pinyin
format, audio, word source and its license, how the next card is chosen.}}

## Definition of done
1. It builds on the pinned simulator.
2. Tests pass, if there are any.
3. You told me how to check it in the app, and it works when I check.
4. You explained what changed.

## Known problems
{{Anything broken right now, with the error message.}}

## Open questions
{{"Not sure" answers to revisit later.}}

## Things I've learned
{{Concepts I've got the hang of, so explanations can build on them. Added over time by $teach-me.}}
