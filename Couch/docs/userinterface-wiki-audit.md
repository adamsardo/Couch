# Couch UI Audit

This audit applies the transferable parts of the installed `userinterface-wiki` guidance to Couch's current SwiftUI rebrand. The app is mobile-first, clinical-skills focused, and intentionally calm. Web-only rules such as CSS pseudo-elements, Web Audio, and predictive prefetching are not applicable.

## Priority Principles

1. One clear next action per screen.

Home should lead with a single practice launcher. Secondary surfaces can show progress, streaks, or drills, but they should not compete with "run a rep".

2. Friendly hierarchy, not noise.

Use deep violet headlines, cream/mist backgrounds, and compact progress chips. Avoid oversized marketing blocks inside the app shell.

3. Motion as reassurance.

Keep transitions short and gentle. Ambient mascot or progress motion must respect Reduce Motion.

4. Clinical seriousness with consumer warmth.

Mascot and sticker elements should reward completion or soften empty states. Serious patient content should use realistic portraits and direct clinical language.

5. Private-first progress.

Progress views should show earned confidence, recent reps, and skill trends without ranking, leaderboards, or performative social mechanics.

## Screen Notes

- Onboarding: keep one decision per screen, place privacy copy early, and avoid "AI therapy" framing.
- Practice home: lead with today's plan and the next rep. Keep streak/confidence quiet.
- Scenario cards: use patient name, traits, and clinical focus tags. Marcus remains the flagship case.
- Live session: minimize chrome, keep emergency controls clear, and use "Virtual patient".
- Debrief: sequence feedback into strengths, next move, micro-drill, confidence check, and completion.
- Settings: group privacy, practice preferences, legal links, and local data reset.

## Implementation Checks

- Use `CouchTheme` tokens instead of literal colors for app UI.
- Use rounded cards with visible grouping, but avoid nested card stacks.
- Use icon buttons for familiar actions and text buttons for primary commands.
- Keep button labels and chip text readable at larger Dynamic Type settings.
- Prefer system symbols that feel rounded and friendly: chat, heart, spark, progress, shield, book, lock, bell.
- Avoid medical-stethoscope clichés unless a screen explicitly needs clinical equipment language.

## Current Status

The active rebrand replaces the old cobalt/yellow system with the Couch violet, lavender, cream, blush, peach, coral, sage, mist, and ink palette. Remaining future audit work should focus on simulator screenshots for Dynamic Type, dark mode, Reduce Motion, and patient-card cropping.
