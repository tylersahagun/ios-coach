---
name: verify
description: Check that the iOS app still builds, and passes its tests if it has any, on the pinned simulator, then explain any failure in plain English. Use before saying any change is done, when the user asks "does it still build", "check my app", or "run the tests", and after code from ChatGPT or elsewhere has been pasted in.
---

# Verify

The rule this skill enforces: if it doesn't build, it isn't done.

## Run it

1. Get the scheme and the pinned destination from the Commands section of `AGENTS.md`. If there's
   no AGENTS.md, run anyway (the script picks sensible defaults) and suggest `$start-here`
   afterward.
2. Tell the user it takes one to five minutes, then run this from the project root:

   ```bash
   bash <this skill's folder>/scripts/verify.sh --scheme <Scheme> --destination '<destination>'
   ```

   Add `--test` if the project has a test target. If the XcodeBuildMCP tools from the Build iOS
   Apps plugin are available, you can use them instead, with the same scheme and destination.

## Report it

- **First line:** "✅ Builds" or "❌ Doesn't build". If tests ran: how many passed and failed.
- **If it failed:** explain the first error in plain English: what it means, which file and line,
  and the likely cause. The first compile error often causes the ones after it, so fix that one
  and run again before explaining the rest.
- **Propose the fix and ask before applying it**, unless the user already asked you to fix things.
- **If it passed:** say how to see the change in the app: which screen, and what to tap.

Never make it pass by deleting code or tests, commenting things out, or silencing warnings. If the
real fix is big, say so and explain why.

## Common errors, translated

| Error says | Usually means |
|---|---|
| `cannot find 'X' in scope` | A typo in a name, or the file that defines `X` isn't part of the app target. |
| `no such module 'X'` | A Swift package isn't added yet, or needs File → Packages → Resolve Package Versions. |
| `value of type 'X' has no member 'y'` | A typo, or code (often pasted) written for a different version of the type. |
| `Unable to find a device matching…` | The pinned simulator isn't installed. List them with `xcrun simctl list devices available`, then update AGENTS.md. |
| `…main actor-isolated…` or `sending … risks causing data races` | Swift concurrency: code running on a background thread touches something that belongs to the UI. Explain the idea once; the Swift Concurrency plugin has the deeper patterns. |
| Signing or provisioning errors | Shouldn't happen here, because the script turns signing off for simulator builds. On a real iPhone they come from the Signing & Capabilities tab, which is on the "Ask first" list. |
