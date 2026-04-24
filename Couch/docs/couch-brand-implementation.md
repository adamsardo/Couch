# Couch Brand Implementation

This document is the local source of truth for applying the current Couch rebrand inside the iOS app.

## Position

Couch is a mobile-first clinical skills simulator for psychology and counselling students. It helps placement-bound students practise therapy before placement through realistic virtual patient sessions, structured feedback, and repeatable clinical skill drills.

Use this framing:

- "Practice therapy before it counts."
- "Low stakes reps for high stakes conversations."
- "Open the app. Meet a virtual patient. Debrief. Improve."
- "You've got this, now run the rep."

Avoid this framing:

- "AI therapy"
- "Fix your mental health"
- "Roleplay with AI"
- "Replace supervision"
- Institution or procurement-led language

## Visual System

Brand tokens live in `Couch/Branding/Theme.swift` and should be used before one-off colors.

Core palette:

- Deep Violet `#5A38FF`: primary action, wordmark, active progress.
- Lavender `#CD88FF`: mascot and soft brand depth.
- Blush `#F1D6E2`: warm secondary surfaces.
- Peach `#FFC7A6`: human accent and completion warmth.
- Coral `#FF7A7A`: warnings and high-attention accents.
- Cream `#FFF6F1`: warm app background.
- Mist `#F1F2F8`: quiet grouped surfaces.
- Sage `#BFE6C9`: healthy progress and safe success.
- Ink `#111318`: primary text and dark surfaces.

Support palette:

- Lavender Soft `#DCC8FF`
- Violet Bright `#6B4CFF`
- Blush Soft `#FFE3EC`
- Peach Soft `#FFD4B6`
- Cream Soft `#FFF7F2`
- Shadow `#E9E2F3`
- Inner Shadow `#F3EEFB`

## Assets

Use semantic asset names so screens do not depend on board-specific crops:

- `brand-wordmark`
- `mascot-default`
- `mascot-compact`
- `mascot-complete`
- `scenario-marcus-intake`
- `patient-avery`
- `patient-zara`
- `patient-ethan`
- `patient-maya`
- `patient-liam`

Mascot usage:

- App icon and splash: plush couch mascot.
- Progress and completion: small mascot pose or sticker reward.
- Empty and error states: calm, steady mascot pose.
- Virtual patient screens: realistic patient portraits, not mascot.

## UI Direction

- Home has one dominant next action: run a rep.
- Tabs stay focused: Practice, Progress, Settings.
- Scenario copy uses "virtual patient", "practice rep", "clinical skill drill", and "debrief".
- Live sessions stay portrait/video-first with minimal controls.
- Debrief should feel like a calm coach: strengths, next move, micro-drill, confidence check, completion.
- Progress remains private-first: no social ranking or performative sharing.

## QA Checklist

- Light and dark mode preserve warmth and contrast.
- Dynamic Type does not clip CTA labels, patient names, chips, or debrief content.
- Reduce Motion disables ambient loops and decorative motion.
- App icon reads at 20pt, 29pt, 40pt, and 1024pt.
- No old GO Club-style cobalt/yellow palette remains in UI tokens.
- Visible copy does not frame Couch as therapy for the user.
- Mandatory debrief remains enforced before returning to Practice.
