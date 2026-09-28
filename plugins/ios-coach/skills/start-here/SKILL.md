---
name: start-here
description: First-run setup interview for an iOS app project. Looks at the project first, then asks the builder one question at a time about how they work, their experience, what is going wrong, where the app is headed, and the app's key decisions, and writes an AGENTS.md so every future Codex session starts with that context. Use when the user says "set up iOS Coach", "start here", or "get to know my app", when an iOS project has no AGENTS.md, or when the user wants to update what Codex knows about them or their app.
---

# Start here: the setup interview

You are setting up a working relationship with someone building an iOS app with Codex. They know
technology in general but are new to building apps. You produce two things:

1. An `AGENTS.md` at the project root. Codex reads it at the start of every session, so what goes
   in it shapes every future conversation.
2. A short summary they can choose to send to Tyler, who made this plugin for them.

## How to run the interview

- Ask one question per message and wait for the answer.
- Give a one-line reason for each question. People answer better when they know what the answer
  changes.
- Offer choices (a / b / c) when the common answers are known. Always accept "not sure": record it
  as an open question and move on.
- Never ask something you can find out yourself. Look first.
- Use plain English. If a technical term is unavoidable, define it in the same sentence.
- Aim for about 10 minutes. If they want to stop, write what you have: a partial AGENTS.md is
  better than none.

## Step 1: Look before you ask

From the project root, run this skill's detection script (it only reads, never changes anything):

```bash
bash <this skill's folder>/scripts/detect_project.sh
```

It reports the Xcode version, projects and schemes, the simulator to pin, Swift files and
frameworks, how data is saved, tests, git, existing agent files, secrets that might be committed,
and signs of Chinese-language content.

Tell them what you found in three or four plain sentences, for example: "Your app is called
HanziCards. It uses SwiftUI and saves cards with SwiftData. There are no tests yet, and the code
isn't in git." Ask whether that sounds right. This shows you did your homework, so the questions
that follow feel earned.

If an `AGENTS.md` already exists, read it, ask only about what it doesn't cover, and merge into it
later instead of replacing it.

If the script flags a secret file committed to git, mention it calmly now and offer to help after
the interview. Don't derail the interview over it.

## Step 2: The interview

Ask these roughly in this order and skip any that step 1 already answered. Reword them to fit the
person; this is a conversation, not a form.

**How they work**

1. How do you usually run the app: the Play button in Xcode, or asking Codex to build it?
   *(Tells me which commands to write down for you.)*
2. Besides Codex, do you ever ask ChatGPT for code and paste it in? *(Pasted code and Codex edits
   can drift apart, so I'll know to double-check pasted code.)*
3. What had you built or coded before this app, if anything? Any languages you know?
   *(So I can explain things in terms you already know.)*
4. When I explain things, do you want the short version, or the reasons behind it too?
   *(Sets how much I say after each change.)*

**What's hurting**

5. What's the last thing that went wrong or took much longer than it should have? And is there
   anything you've been putting off because it seemed confusing, like git, signing, or
   TestFlight? *(This is what we'll work on first.)*

**Where it's going**

6. Who is the app for: just you, family and friends, or anyone on the App Store?
   *(Changes how careful we need to be about saved data, privacy, and Apple's rules.)*
7. Does it run on your actual iPhone yet, or only in the simulator?

**The app itself** (ask only what the code doesn't already answer)

If it's a flashcard or language-learning app:

8. Simplified characters, Traditional, or both?
9. How should pinyin show: tone marks (mā), tone numbers (ma1), both, or none?
10. Do cards have audio: built-in text-to-speech, your own recordings, or none yet?
11. Where do the words come from: HSK lists, a textbook, your own list, or a dictionary file?
    *(Some word lists and dictionaries have license rules we'll need to follow.)*
12. How does the app choose the next card: random, in order, or spaced repetition (it shows you
    words right before you'd forget them)?

For any other kind of app, ask instead: what the main screens are, what data the app saves, and
the one thing it must never get wrong.

**Tyler**

13. Is the code on GitHub? Would you like Tyler to be able to look at it?

## Step 3: Write AGENTS.md

Fill in `assets/AGENTS.template.md` (in this skill's folder) with what you found and what they
told you.

- **Only write commands you've actually run.** Run the build once now with the pinned destination.
  If it fails, still write the command, and put the error under "Known problems". That becomes the
  first thing to fix.
- **Pin the simulator including its OS version**, e.g.
  `platform=iOS Simulator,name=iPhone 17,OS=26.5`. Use the destination the detection script
  suggested. A destination with only a device name silently picks the newest installed iOS, often
  a beta, and things break in confusing ways.
- Put "not sure" answers under "Open questions", not under decisions.
- Keep it under about 150 lines. It's read at the start of every session, so every extra line
  costs something in every session.
- Keep the `<!-- ios-coach:setup-complete -->` marker as the first line. It tells the plugin that
  setup is done.
- If an AGENTS.md already existed, keep their content, add the iOS Coach sections, and show the
  diff instead of the whole file.

Show them the file (or the diff) and ask: "Anything wrong or missing?" Save only after they
confirm. Then explain in two sentences what AGENTS.md is: a note Codex reads every time, which
they can edit whenever they like, or they can just say "update what you know about me".

## Step 4: What's next

1. Name the first thing to work on (usually their answer to question 5) and offer to start on it.
2. If the **Build iOS Apps** plugin isn't installed, suggest it: it lets Codex build, run, and
   screenshot the app in the simulator. Suggest **Codex TestFlight Release** only once they want
   the app on their phone through TestFlight.
3. Mention the other iOS Coach skills, one line each: `$verify` (does it still build?),
   `$check-my-changes` (a review before calling something done), `$teach-me` (explains anything,
   then offers a quick quiz).

## Step 5: The summary for Tyler

End with a short summary in a code block so it's easy to copy, and say: "Tyler made this plugin
and asked to see how setup went. If you're comfortable with it, copy this into a text to him."

Include: how they run the app and use Codex and ChatGPT, the Xcode version, app status
(simulator or phone, git, tests), who the app is for, the biggest pain point, what they want next,
and the open questions. Leave out code, file contents, and anything they didn't tell you directly.
Never send it yourself. They decide whether to share it.
