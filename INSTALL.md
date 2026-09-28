# Installing iOS Coach (steps for Codex)

The user has asked you to install or update iOS Coach from this repository. Follow these steps.
The same steps work for a first install and for an update.

This repo is a Codex **plugin marketplace**. Install it with the `codex plugin` commands below.
**Don't** use `skill-installer`, and don't copy skill folders into `~/.codex/skills`. That would
leave out the plugin's startup check and break updates.

## What this changes

- Adds a marketplace named `sahagun`, pointing at this GitHub repo, to `~/.codex/config.toml`.
- Installs and enables the `ios-coach` plugin: four skills and one startup check.

Nothing else changes. There's no account, no API key, and nothing is written to the user's
project.

## Steps

These commands need network access and write to `~/.codex`, so request approval to run them
outside the sandbox. Tell the user in one plain sentence what they're approving, for example:
"This adds Tyler's iOS Coach plugin to Codex."

1. **Find the Codex command-line tool:**

   ```bash
   CODEX="$(command -v codex || true)"
   for p in /Applications/ChatGPT.app/Contents/Resources/codex /Applications/Codex.app/Contents/Resources/codex; do
     [ -z "$CODEX" ] && [ -x "$p" ] && CODEX="$p"
   done
   echo "${CODEX:-not found}"
   ```

   If it isn't found, stop and send the user to the "Manual install" section of this repo's
   README.

2. **Add or refresh the marketplace, then install the plugin.** Each command is safe to run
   again:

   ```bash
   "$CODEX" plugin marketplace add tylersahagun/ios-coach
   "$CODEX" plugin marketplace upgrade sahagun
   "$CODEX" plugin add ios-coach@sahagun
   ```

3. **Offer the companion plugin.** Ask the user first. OpenAI's Build iOS Apps plugin lets Codex
   build, run, and screenshot the app in the simulator:

   ```bash
   "$CODEX" plugin add build-ios-apps@openai-curated-remote
   ```

   If that fails, tell the user they can install "Build iOS Apps" from the Plugins page instead.

4. **Confirm it worked:**

   ```bash
   "$CODEX" plugin list | grep -E 'ios-coach|build-ios-apps'
   ```

   Each plugin you installed should show `installed, enabled`.

## Then tell the user, in plain words

1. Start a **new chat** with your app's folder open. Plugins load in new chats, not the one you're
   in. If iOS Coach doesn't show up, quit Codex and open it again.
2. The first time, Codex asks you to review iOS Coach's startup check (you can also type
   `/hooks`). Approve it. All it does is check whether setup has been done for your project.
3. In the new chat, say: **"Set up iOS Coach for my app."**
