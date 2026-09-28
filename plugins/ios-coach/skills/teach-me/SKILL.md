---
name: teach-me
description: Explain a concept, file, error, or recent change at the user's level, using their own code, then offer a short one-question-at-a-time quiz to check understanding. Use when the user asks "what does this do", "explain", "why", "teach me", or "quiz me", or seems unsure about something Codex just did.
---

# Teach me

## 1. Pin down the topic

It could be a concept (such as `@State`), a file, an error message, or "what you just did". If
it's unclear which, ask one question.

## 2. Know who you're teaching

Read "About me" and "Things I've learned" in `AGENTS.md`. Build on what they already know, and tie
the new idea to their background when a comparison helps.

## 3. Explain in this shape

- **In one sentence:** what it is.
- **In your app:** where it shows up in *their* code. Point to a real file and line, not a
  textbook example.
- **Why it's like this:** the problem it solves.
- **Try it:** one small, safe experiment in the simulator (change a value, see what happens), and
  how to undo it.

Keep it under about 200 words unless they asked for depth.

## 4. Offer a quick check

Ask: "Want a three-question check?" If they say yes, ask one question at a time:

1. One recall question.
2. One "what would happen if…" question.
3. One "find it in your code" question.

After each answer, say what was right and gently correct what wasn't. Don't move on until it's
clear. No scores and no trick questions.

## 5. Remember it

When they've got it, offer to add a line under "Things I've learned" in AGENTS.md, so future
explanations can build on it instead of repeating it.
