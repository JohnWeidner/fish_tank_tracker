# Getting Started with Wingspan: A Flutter Developer's Tutorial

Wingspan is a set of AI-powered skills for Claude Code that guide you through the full development lifecycle — brainstorming, planning, building, and quality review. It follows Very Good Ventures' engineering standards and works with any Flutter or Dart project.

This tutorial teaches each Wingspan skill using a real app — a Fish Tank Tracker — as a running example. We built this app from a blank slate to a fully functional Flutter application with AI-powered species identification, image management, and water parameter tracking. Along the way, Wingspan's review agents caught real bugs, its planning agents found over twenty edge cases we'd missed, and its build phase produced clean, well-tested code.

You don't need to build the same app. The skills work on any project. Follow along with your own idea, or use the examples here to learn the workflow.

---

## Prerequisites

Before installing Wingspan, you need Claude Code running. If you already have it, skip to [Installing Wingspan](#installing-wingspan).

### Installing Claude Code

Claude Code is Anthropic's CLI for Claude. Install it globally:

```bash
npm install -g @anthropic-ai/claude-code
```

You'll need an Anthropic API key or a Claude subscription. Run `claude` in your terminal to authenticate.

> **Already using Claude Code?** Jump to [Installing Wingspan](#installing-wingspan).

### Installing Wingspan

Navigate to your Flutter project and load Wingspan:

**Single session** (loads for this session only):

```bash
cd /to/your/project
claude --plugin VeryGoodOpenSource/wingspan
```

**Persistent** (loads automatically on every session):

```bash
cd /to/your/project
claude
# then inside Claude Code:
/plugin marketplace add VeryGoodOpenSource/wingspan
/plugin install wingspan@wingspan-marketplace
```

That's it. Wingspan's skills are now available as slash commands.

---

## The Wingspan Workflow

Wingspan follows a three-phase workflow: **brainstorm**, **plan**, **build**. Each phase produces documents that feed into the next, so you can clear context between steps without losing work.

```
/brainstorm  →  /plan  →  /build
     ↕              ↕
/refine-approach  /plan-technical-review
```

You don't have to use every phase. Simple bug fix? Jump to `/build`. Already know what you want? Start at `/plan`. The workflow adapts to what you need.

### Quick Reference

| Skill | Command | When to use |
|-------|---------|-------------|
| Brainstorm | `/brainstorm <idea>` | Exploring a new feature or big change |
| Refine Approach | `/refine-approach` | Tightening a brainstorm or plan before moving on |
| Plan | `/plan <feature>` | Turning ideas into a step-by-step implementation plan |
| Plan Technical Review | `/plan-technical-review` | Validating a plan with opposing review perspectives |
| Build | `/build <plan path>` | Writing code, tests, and running quality review |
| Review | `/review` | Running quality review agents on demand |
| Hotfix | `/hotfix <bug>` | Emergency bug fixes with enforced review |

---

## Phase 1: Brainstorm

### What it does

`/brainstorm` opens a collaborative dialogue to explore your idea. Instead of dumping requirements, Wingspan asks targeted questions — often multiple-choice — to help you think through purpose, users, constraints, and trade-offs. It proposes approaches and captures decisions in a persistent document.

### Try it

```text
/brainstorm add a way to photograph fish and identify species using AI
```

Wingspan will ask you questions one at a time. Here's what a typical exchange looks like:

**Wingspan asks:**
> Should the AI identification happen automatically after capture, or on-demand?
> 1. Automatically after every photo
> 2. On-demand via a button
> 3. Both — auto-identify but allow re-identification

You pick an option, Wingspan asks the next question. After several rounds, it proposes 2-3 concrete approaches with trade-offs:

> **Approach A: Cubit with debounced auto-save** (Recommended)
>
> The edit page gets its own Cubit that handles inline saves...
>
> - Pros: Follows existing patterns, clean separation
> - Cons: Needs a new cubit + state
> - Best when: Consistency with existing architecture matters

You choose an approach, and Wingspan writes a brainstorm document to `docs/brainstorm/`:

```
docs/brainstorm/2026-03-30-gallery-entry-detail-brainstorm-doc.md
```

This document captures what you're building, why this approach, key decisions, and open questions. It becomes the input to the next phase.

### What we learned building the Fish Tank Tracker

When we brainstormed the initial app concept, Wingspan asked about navigation layout and generated ASCII mockups to compare options before writing any code. Later, when brainstorming the image cropping feature, it explored three package options (`image_cropper`, `crop_image`, `croppy`) with pros/cons for each, and we picked the native crop UI approach.

One thing Wingspan doesn't do well yet: it doesn't research existing apps or competitors during brainstorm. That's a feature we'd like to add. For now, if competitive research matters, do it yourself before brainstorming with Wingspan.

### Tips

- **Give context up front.** `/brainstorm add authentication` produces generic results. `/brainstorm add email/password and OAuth login for our e-commerce app that currently has guest checkout` produces focused questions.
- **Push back.** If Wingspan suggests something you disagree with, say so. The brainstorm adapts to your feedback.
- **Run `/refine-approach` after.** This catches contradictions and gaps in the brainstorm before you invest in planning. When we refined our initial app brainstorm, it caught logical contradictions we'd glossed over in the excitement of ideation.

---

## Phase 2: Plan

### What it does

`/plan` transforms your brainstorm into a structured implementation plan. It launches research agents in parallel to understand your codebase and identify gaps, then produces an actionable document with acceptance criteria, technical design, and implementation order.

### Try it

```text
/plan implement the gallery entry detail page from our brainstorm
```

If a recent brainstorm document exists, Wingspan picks it up automatically:

> Found brainstorm from 2026-03-30: gallery-entry-detail. Using as context for planning.

### What happens behind the scenes

Wingspan runs multiple agents in parallel:

1. **Codebase review agent** — reads your existing code to understand patterns and conventions
2. **User-flow analysis agent** — analyzes the feature for completeness and edge cases
3. **External research agents** (when needed) — fetches docs for frameworks and libraries

The user-flow analysis agent is particularly valuable. When planning the entry detail page for our Fish Tank Tracker, it found twelve gaps the brainstorm missed:

> **Gap: Debounce-on-close data loss**
>
> When the user edits the name and immediately presses back, the debounce timer may not have fired yet. The pending save is lost. The user sees their edit on screen, presses back thinking it saved, and returns to find the old name.
>
> **Gap: currentIndex out of bounds after deletion**
>
> If the user deletes the last entry in a list, the currentIndex may point beyond the new list length, causing a range error.

These are real bugs that would have shipped without this analysis. Across two planning phases for the Fish Tank Tracker, the user-flow agent found over twenty edge cases that brainstorming missed — the kinds of bugs that ship to production and generate confused support tickets.

When we later planned a major refactor (merging the separate "add entry" and "edit entry" flows into one), the flow agent found eleven more gaps including how to handle orphaned image files when the user cancels, what happens when the app is killed mid-edit, and a race condition between debounced saves and the cancel action.

### The plan document

The output lands in `docs/plan/`:

```
docs/plan/2026-03-30-feat-gallery-entry-detail-page-plan.md
```

It includes:
- Title, type, and acceptance criteria
- Technical design with file paths and code sketches
- Implementation order
- Risks and mitigations
- What's explicitly out of scope

### Optional: Technical Review

Before building, you can validate the plan:

```text
/plan-technical-review
```

This runs two agents with deliberately opposing perspectives:
- A **code-simplicity reviewer** that flags over-engineering and YAGNI violations
- A **VGV-standards reviewer** that checks architectural rigor

The tension between "keep it simple" and "do it right" produces a plan that balances both. When we ran this on the initial Fish Tank Tracker plan, the simplicity reviewer flagged six YAGNI items (features we didn't need yet) while the VGV reviewer upgraded the architecture to a multi-package monorepo. The final plan was both leaner and more production-grade than either perspective alone would have produced.

### Refining plans with your own feedback

Plans aren't rigid. When our unified entry flow plan suggested auto-deleting entries with empty names on close, we pushed back: "I'm fine if the name is empty; there should always be an image." Wingspan updated the plan, and that single piece of feedback eliminated an entire category of complexity — no `PopScope` interception, no auto-delete logic, no special back-navigation handling. The implementation was significantly simpler as a result.

### Tips

- **Skip external research when your codebase has strong patterns.** Wingspan decides automatically, but you can guide it: "My codebase already has good examples of this pattern."
- **You can skip planning entirely.** For small bug fixes or simple changes, go straight to `/build` with a description.
- **Not every plan needs a technical review.** We used `/plan-technical-review` for the initial app build but skipped it for subsequent features where the patterns were already established. Use it when the stakes are high or when you're exploring unfamiliar territory.

---

## Phase 3: Build

### What it does

`/build` executes your plan — writing code, writing tests, running static analysis, and performing a multi-agent quality review. It follows the plan's implementation order and validates at each step.

### Try it

```text
/build docs/plan/2026-03-30-feat-gallery-entry-detail-page-plan.md
```

Wingspan summarizes the scope and asks for confirmation before starting:

> **Plan scope:** 6 tasks, ~8 files to create/modify, moderate complexity.
>
> 1. Start building
> 2. Review the plan first
> 3. Adjust scope

### What happens during the build

Wingspan breaks the plan into phased tasks and tracks progress as it works through each one:

![Build phase todo list showing phased tasks with validation checkpoints](screenshots/build-todos.png)

For each task in the plan:

1. **Implement** — writes code following VGV conventions (Bloc/Cubit, sealed classes, const constructors, layer separation)
2. **Test** — writes tests alongside each unit (`blocTest`, `mocktail`, proper mocking)
3. **Validate** — runs `flutter analyze` and `flutter test`
4. **Checkpoint** — brief progress update

The initial Fish Tank Tracker build produced six packages, four features, roughly fifty files, with sealed classes, Bloc + Cubit state management, and go_router navigation. It shipped with twenty-three passing tests and zero analysis issues.

### Quality Review: Where Wingspan Earns Its Keep

After all tasks complete, the build phase launches four review agents in parallel:

- **VGV standards agent** — conventions, doc comments, naming
- **Code simplicity agent** — YAGNI audit, dead code, unnecessary abstractions
- **Test quality agent** — coverage gaps, anti-patterns, missing edge cases
- **Architecture agent** — layer separation, dependency direction, Bloc/Cubit correctness

The quality review isn't ceremonial — it catches real issues. Here's what the agents found building the Fish Tank Tracker:

**During the initial build**, the code-simplicity agent found broken wiring that left the AI identification feature silently non-functional. Without this review, the feature would have appeared to work during development (no errors, no crashes) but would have never actually called the API. The test-quality agent also flagged zero widget tests and missing failure paths.

**When building the entry detail page**, the architecture agent found a `TextEditingController` initialized inside `build()` — a common Flutter anti-pattern that causes subtle lifecycle bugs. The VGV agent found missing error handling in the save method, which would have silently swallowed database errors.

**During a major refactor** (unifying the add and edit entry flows), the architecture agent caught a layer violation: a widget was calling the repository directly instead of going through the cubit. This broke the pattern used everywhere else in the codebase and would have left the business logic untestable without a widget test.

After the review, Wingspan categorizes findings and asks you how to proceed — you stay in control of what gets fixed:

![Fix scope dialog showing options for addressing critical issues, all issues, or just bugs](screenshots/fix-scope.png)

You choose the scope, and Wingspan fixes the selected issues automatically, re-running analysis and tests after each fix.

### The limits of automated review

Here's what the review agents *didn't* catch: after building the entry detail page, manual testing revealed that type-only changes (switching a fish's category from livestock to plant without editing its name) weren't saving. An empty-name guard in the save method was blocking type toggles for entries that hadn't been named yet. Four review agents ran, and none flagged it.

Similarly, the agents recommended a deprecated package (`google_generative_ai`, replaced by `firebase_ai`) and a Gemini API model (`gemini-2.0-flash`) that was blocked for new users despite appearing in documentation. These required manual debugging with curl to resolve.

The takeaway: automated review catches architectural and pattern issues exceptionally well, but it can't replace running the app and tapping through the flows yourself.

### Tips

- **Don't skip the quality review.** It's tempting to stop after the code compiles, but the review phase consistently finds issues that would otherwise ship.
- **Manual testing still matters.** Run the app. Tap every button. Try edge cases. The AI catches patterns; you catch behavior.
- **Clear context between phases.** Wingspan offers this option after each phase. A fresh context window produces better results for the next phase.

---

## Working Outside the Phases

Not everything needs the full brainstorm-plan-build cycle. During the Fish Tank Tracker development, a significant amount of work happened outside the structured phases — and that's by design.

### Quick changes

Just describe what you need in natural language:

```text
Change the livestock icon from a paw print to a fish icon
```

```text
The camera preview should be centered instead of left-justified
```

```text
Pin the intl dependency to ^0.20.2
```

```text
The API key field shouldn't be obscured like a password
```

Wingspan handles these directly without invoking a skill. We added scientific name editing, a retake photo feature, a custom SVG fish icon, and various UI fixes this way — all flowing smoothly alongside the structured Wingspan workflows.

### Mixed workflows

You can also use individual skills for ad-hoc decisions. When we needed to choose an image cropping package, we ran `/brainstorm` just for that decision — it explored three options with trade-offs and we picked one in under two minutes. No plan or build phase needed; we implemented it directly.

### On-demand review

Want a quality check on code you've already written?

```text
/review lib/entry_detail/
```

This runs the same review agents from the build phase on the specified path.

### Emergency fixes

```text
/hotfix users are getting a crash when they tap the crop button on Android
```

`/hotfix` applies a minimal fix with enforced review and testing, skipping the brainstorm and planning phases.

---

## Putting It All Together

Here's how a typical feature development flows with Wingspan:

### The full cycle (new features, big changes)

```
/brainstorm add image cropping to the edit page
  → Explores packages, UX approaches, placement decisions
  → Output: docs/brainstorm/2026-03-31-image-crop-brainstorm-doc.md

/refine-approach
  → Catches gaps and contradictions

/plan implement image cropping from our brainstorm
  → Codebase review, user-flow analysis, external docs research
  → Output: docs/plan/2026-03-31-feat-image-crop-plan.md

/plan-technical-review
  → Simplicity vs rigor review

/build docs/plan/2026-03-31-feat-image-crop-plan.md
  → Code + tests + analysis + quality review
  → Fixes critical/important findings
```

### The short cycle (medium changes)

```
/brainstorm add a way to edit entries in the gallery
  → Quick Q&A, approach selection

/plan implement entry detail page
  → Picks up brainstorm, runs research agents

/build docs/plan/...
  → Full implementation with review
```

### No cycle (small changes, bug fixes)

```text
The empty state shows a paw print icon, change it to a fish
```

Or for bugs:

```text
/hotfix render overflow on the edit page when the keyboard opens
```

### The key insight

**Wingspan is a guide, not a cage.** We used the full sequence for the initial app build, a shorter version for adding the entry detail feature, and a mix of structured and ad-hoc work for polish and refactoring. The workflow adapts to how you actually work.

---

## What to Expect

After building the Fish Tank Tracker from scratch with Wingspan, a few patterns stood out:

**Parallel review agents catch real bugs.** Not theoretical issues — actual broken wiring, anti-patterns that cause crashes, and architectural violations. The review phase paid for itself on the very first build.

**The user-flow analysis agent is the unsung hero.** It consistently finds edge cases that brainstorming misses — debounce data loss, index-out-of-bounds errors, race conditions between concurrent operations. These are the bugs that ship to production and generate confused support tickets.

**The workflow is flexible by design.** Not every step is always needed. We skipped `/refine-approach` and `/plan-technical-review` when the feature was well-scoped. We used `/brainstorm` for a two-minute package selection. We handled a dozen quick fixes with plain natural language. Rigidity would have made the tool unusable; the flexibility is what makes it practical.

**Human judgment still drives the product.** We pushed back on implementation choices (no auto-deleting empty entries), caught bugs that agents missed (type-only saves failing), spotted UI issues that required actually running the app (overlapping buttons, render overflows), and made UX decisions that shaped the architecture (moving the AI button near the fields it fills). Wingspan handles the scaffolding and catches the details; the developer sets the direction.

**How you frame the project matters.** Calling something a "demo app" gives the AI permission to cut corners. If you want production-grade architecture, set that expectation upfront. The AI responds to the same context cues a junior developer would.

**AI tools have knowledge gaps, and that's fine — if you're aware of it.** Deprecated packages, blocked API models, missing platform configuration — these are areas where the developer's real-world testing complements what AI agents can verify. We're building detection for these gaps into future Wingspan versions.

---

## Next Steps

- **[Wingspan on GitHub](https://github.com/VeryGoodOpenSource/wingspan)** — Installation, full skills reference, and source code
- **[Very Good Ventures](https://verygood.ventures/contact)** — Questions about Wingspan for your team
