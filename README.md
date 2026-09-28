# iOS Coach

A Codex plugin for building your iOS app. It gets to know your project and how you like to work,
writes that down so every Codex session starts with it, checks that the app still builds, reviews
changes before you call them done, and explains things in plain English with a quick quiz if you
want one.

## Install (one time, about 5 minutes)

1. Open **Terminal** and paste:

   ```bash
   codex plugin marketplace add tylersahagun/ios-coach
   ```

   If Terminal says `command not found: codex`, use the copy of Codex inside the ChatGPT app:

   ```bash
   /Applications/ChatGPT.app/Contents/Resources/codex plugin marketplace add tylersahagun/ios-coach
   ```

2. Install the plugin. Either run `codex plugin add ios-coach@sahagun`, or in Codex open
   **Plugins**, choose **Sahagun Family**, and install **iOS Coach**.

3. While you're in Plugins, also install **Build iOS Apps** (from OpenAI). It lets Codex build,
   run, and take screenshots of your app in the simulator.

4. Start a **new** Codex chat with your app's folder open. The first time, Codex asks you to
   review iOS Coach's startup check (you can also type `/hooks`). Approve it. All it does is look
   for an AGENTS.md file to see whether setup has been done.

5. Say: **"Set up iOS Coach for my app."**

   It looks at your project, then asks about a dozen questions, one at a time. "Not sure" is
   always a fine answer. At the end it writes an `AGENTS.md` file into your project and gives you a
   short summary you can text to Tyler if you'd like.

## What you can ask for

| Say this | What happens |
|---|---|
| "Set up iOS Coach" / "update what you know about me" | The setup interview. It writes or updates `AGENTS.md`. |
| "Does it still build?" / "run the tests" | Builds the app on a fixed simulator and explains any error in plain English. |
| "Check my changes" / "is this ready?" | Reviews what changed, looking for common mistakes, before you call it done. |
| "Teach me what you just did" / "quiz me" | Explains using your own code, then offers a three-question check. |

You can also type `$` in Codex and pick an iOS Coach skill from the list.

## Getting updates

When Tyler says there's a new version:

```bash
codex plugin marketplace upgrade sahagun
codex plugin add ios-coach@sahagun
```

Then start a new chat.

---

## Maintaining (Tyler)

```
.agents/plugins/marketplace.json     # makes this repo a marketplace named "sahagun"
plugins/ios-coach/
  .codex-plugin/plugin.json          # manifest; bump "version" for each release
  hooks/hooks.json                   # SessionStart → session-start.sh (offers setup if not done)
  hooks/session-start.sh
  skills/start-here/                 # interview → AGENTS.md; scripts/detect_project.sh; assets/AGENTS.template.md
  skills/verify/                     # scripts/verify.sh: pinned-simulator build/test + summary
  skills/check-my-changes/           # review against AGENTS.md + beginner pitfalls
  skills/teach-me/                   # explain with his code, optional quiz
```

**Test locally without touching your real Codex config** (`codex` isn't on your PATH; it lives in
the ChatGPT app):

```bash
alias codex=/Applications/ChatGPT.app/Contents/Resources/codex
export CODEX_HOME="$(mktemp -d)"
codex plugin marketplace add ~/Developer/ios-coach
codex plugin add ios-coach@sahagun
cd <some iOS project> && codex debug prompt-input | grep ios-coach   # skills are visible to the model
```

**Validate the manifest** (the validator needs PyYAML):

```bash
python3 ~/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py plugins/ios-coach
```

**Scripts can be run directly** from any iOS project root:

```bash
bash plugins/ios-coach/skills/start-here/scripts/detect_project.sh
bash plugins/ios-coach/skills/verify/scripts/verify.sh --test
```

**Release:** bump `version` in `plugin.json`, push, and tell him to run the two update commands.

**Add later, when he actually needs them:**
- `ship-to-testflight`: your Folio ship lessons (upload with stable Xcode, never a beta; unique
  build number per upload) on top of the Codex TestFlight Release plugin.
- `app-store-ready`: a port of `~/.claude/skills/app-store-compliance`. It's already in SKILL.md
  format; rewrite the Claude-specific tool references.
- Flashcard knowledge: spaced-repetition scheduling, pinyin rendering, and CC-CEDICT's
  attribution and share-alike terms, once you've seen his code.
