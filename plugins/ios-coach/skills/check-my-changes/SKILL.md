---
name: check-my-changes
description: Review the current changes before calling them done. Reads the diff, checks it against AGENTS.md's rules and the pitfalls that catch people new to iOS, runs verify, and gives a plain-English PASS or NEEDS WORK. Use when the user asks "is this ready", "review this", or "did you break anything", before committing, and after a big change from Codex or pasted-in ChatGPT code.
---

# Check my changes

You are the second pair of eyes. In this skill you review and run checks; you don't build
features.

## 1. Find what changed

Run `git status`, `git diff`, and `git diff --staged`. If the project isn't in git, say plainly
that git is the single biggest safety upgrade available (it makes every change undoable), and
offer to set it up: `git init`, a standard Xcode `.gitignore`, and a first commit. Then review the
files changed in this session.

## 2. Check against AGENTS.md

Read the standing rules and the "Ask first" list. If anything on that list changed without the
user saying yes, stop and ask before anything else.

## 3. Check the usual pitfalls

- **Saved data.** Did any `@Model` class or Core Data entity change? Could data already on the
  phone be lost, or stop the app from opening? A new property needs a default value, and a rename
  or removal needs a migration plan.
- **The project file.** Did `project.pbxproj` change? Was that expected (a new file was added), or
  a side effect?
- **Secrets.** Are there API keys, tokens, or passwords in code or in committed files? An OpenAI or
  other API key built into an app can be pulled out of the app by anyone who has it.
- **Code removed to make things work.** Look for deleted or commented-out code, removed tests, or
  silenced warnings.
- **Slow work on the main thread.** Loading a big word list or parsing a file inside a view's
  `body`, or anywhere on the main thread, makes the app stutter.
- **Chinese text,** if the app has it:
  - Text is cut up by number offsets (`NSString`, `utf16`) instead of `Character`s. Rare
    characters can be split in half.
  - Text isn't marked as `zh-Hans` or `zh-Hant`. A character shared by both scripts can then show
    the other region's shape.
  - The speech voice is wrong: `zh-CN` is mainland Mandarin, `zh-TW` is Taiwan Mandarin, and
    `zh-HK` is Cantonese.
- **Accessibility basics.** Body text uses fixed font sizes instead of Dynamic Type, or
  icon-only buttons have no VoiceOver label.
- **Leftovers.** Debug `print`s, commented-out blocks, or TODOs added in this session.

## 4. Run `$verify`

Build, and run tests if there are any.

## 5. Report

Start with **PASS** or **NEEDS WORK**, then a short list. For each item give the file and line,
what's wrong in plain English, how to fix it, and whether it blocks. Say what you didn't check.
End by offering to fix the blocking items.
