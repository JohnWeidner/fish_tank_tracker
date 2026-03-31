# fish_tank_tracker

I was asked to try out using Wingspan to build a simple app. I decided to create an app that I could use to keep track of what fish I have in my fishtank. The idea was that when I go to a fish store, I want to be able to easily show the store owner what fish I currently have with out sounding like an idiot when I can't remember that I have a Platy and instead say I have a little orange fish.

The app I built lets you take pictures of your fish and your plants and uses AI to look up what they are really called. It lets you add, edit, and remove the pictures. There is also a place where you can keep track of your water parameters.


<img width="250" src="https://github.com/user-attachments/assets/64634b5d-ce78-4644-b128-9dd476310fee" />

<img width="250" src="https://github.com/user-attachments/assets/e7661d09-e336-41d0-9e6a-ab5a8bbb0201" />

<img width="250"  src="https://github.com/user-attachments/assets/df803194-4c05-438e-8deb-2307e5bf4e3a" />

# I Built a Flutter App in Three Sessions with Wingspan. Here's Exactly How.

AI-assisted development tools promise a lot. Most deliver autocomplete. I wanted something different: an AI workflow that handles the full lifecycle — from brainstorming to architecture review — while keeping the developer in the driver's seat.

At VGV, we built Wingspan, a set of AI-powered skills for Claude Code that guide you through ideation, planning, building, and quality review. To put it through its paces, I built a real Flutter app from scratch: a Fish Tank Tracker that lets you photograph your fish, identify species with Gemini AI, and manage your aquarium inventory.

Three sessions. One app. Every Wingspan skill exercised. Here's what happened.

## Session 1: From Blank Slate to Running App

### Brainstorm and Refine

I started with `/brainstorm`. Rather than dumping a wall of requirements, Wingspan opened a collaborative Q&A — asking about the app's purpose, target users, and core features through multiple-choice questions. It even generated ASCII preview mockups to help me choose a navigation layout before writing a single line of code.

The brainstorm output landed in `docs/brainstorm/` as a persistent document. I ran `/refine-approach` on it, which caught logical contradictions I'd glossed over in the excitement of ideation. That refinement step is easy to skip, but it saved me from building on a shaky foundation.

### Plan with Parallel Research

Next came `/plan`. This is where Wingspan starts to flex. It launched four research agents in parallel: a codebase reviewer, an official docs researcher, a Flutter best practices agent, and a user-flow analysis agent. That last one found twelve gaps the brainstorm missed — edge cases around navigation, data persistence, and error handling that would have surfaced as bugs later.

I refined the plan, then ran `/plan-technical-review`, which spun up two agents with deliberately opposing perspectives: a code-simplicity reviewer (flagging six YAGNI items) and a VGV-standards reviewer (which upgraded the architecture to a multi-package monorepo). The tension between "keep it simple" and "do it right" produced a plan that was both lean and production-grade.

### Build and Review

`/build` turned that plan into code: six packages, four features, roughly fifty files, with sealed classes, Bloc + Cubit state management, and go_router navigation. It shipped with twenty-three passing tests and zero analysis issues.

But Wingspan doesn't stop at "it compiles." Phase 3 of `/build` launched four parallel review agents — covering VGV standards, code simplicity, test quality, and architecture. They found a real bug: broken wiring that left the AI identification feature silently non-functional. They also flagged missing widget tests and dependency direction issues. Fourteen critical and important findings were fixed before I called session one complete.

## Session 2: Adding a Feature the Right Way

For session two, I needed an entry detail page — tap a fish in the gallery, see its details, edit inline. I used `/ideate` as a lightweight brainstorm, which proposed three approaches and walked me through the trade-offs via interactive questions.

That brainstorm document became the input to `/plan`. This time Wingspan skipped external research (strong local patterns already existed) but still ran its codebase reviewer and user-flow analysis agent. The flow agent again earned its keep, catching a debounce-on-close data loss edge case — a bug that would have shipped silently and frustrated users.

The `/build` produced the feature: hero animations, debounced auto-save, delete with confirmation dialog, and it even fixed a pre-existing bug where the gallery's current index reset on every stream update. Thirty-eight passing tests, zero analysis issues.

The quality review caught a TextEditingController-in-build anti-pattern — the same class of bug it found in session one, which suggests this is a common Flutter pitfall that automated review handles well.

Here's what the review agents didn't catch: after the build, manual testing revealed that type-only changes (switching a fish's category without editing its name) weren't saving. An empty-name guard in the save method was blocking type toggles. Human testing still matters.

I also skipped `/refine-approach` and `/plan-technical-review` this session. Not every step is always needed, and that flexibility is by design.

## Session 3: Polish, Integration, and a Major Refactor

Session three was the most varied — a mix of ad-hoc fixes, new features, and a significant architectural refactor, all flowing through Wingspan skills alongside manual work.

### The Gemini Integration Adventure

I hit a real-world snag with the Gemini AI integration. The `google_generative_ai` Dart package turned out to be deprecated, replaced by `firebase_ai`. The model I'd targeted (`gemini-2.0-flash`) was blocked for new API users despite appearing in documentation. I debugged with curl, found a working model (`gemini-2.5-flash`), and fixed the API call format.

This was a purely human debugging session — and it surfaced two concrete enhancement ideas for Wingspan: research agents should check pub.dev for deprecation notices, and they should verify that recommended API models are actually available.

### Rapid Feature Additions

I added several features without full Wingspan cycles — scientific name editing, retake photo, image cropping (via `/ideate` for package selection), a revert-to-original feature, and a custom fish SVG icon. These ad-hoc changes flowed smoothly alongside the structured Wingspan workflows, which matters: a rigid tool that can't accommodate real development's messiness isn't useful.

Not everything was perfect on the first pass. A couple of UI issues needed manual correction: a small button rendered directly underneath an existing FAB (visually redundant and confusing), and a render overflow that Wingspan hadn't anticipated. These are the kinds of spatial reasoning gaps that AI still struggles with — you need to run the app and look at it.

### The Unified Flow Refactor

The biggest change was merging the separate "add entry" and "edit entry" flows into one unified path. I ran `/plan` with full research agents, then refined the plan based on feedback. When the plan suggested auto-deleting entries with empty names, I pushed back — "I'm fine if the name is empty; there should always be an image." That feedback simplified the implementation significantly.

`/build` executed the refactor: a shared camera page replaced two separate implementations, the gallery FAB now opens the camera and flows straight to the edit page, and the entire `add_entry` feature got deleted — eight files gone. The quality review caught a layer violation where a widget was calling the repository directly, which got moved into the cubit where it belonged.

## The Result: Better Than Expected, With Caveats

Here's the thing that surprised me most: the app looked better than what I would have built on my own in the same timeframe. The code was divided into clean layers — data, domain, presentation — with consistent patterns across features. It looked like something a team would be comfortable maintaining long-term.

But I wanted to stress-test that impression. I asked Claude to think like an expert Flutter architect and roast the codebase. It did find issues: a small amount of business logic had crept into the UI layer, and some patterns could have been tighter. Interestingly, these shortcomings may trace back to how I framed the project. I told Claude I was building a demo app, not a production-ready product. That framing likely influenced how aggressively Wingspan enforced architectural rigor. Lesson learned: if you want production-quality output, say so from the start.

## What I Learned

After three sessions with Wingspan, a few patterns stood out.

**Parallel review agents catch real bugs.** Not theoretical issues — actual broken wiring, anti-patterns that cause crashes, and architectural violations. The review phase paid for itself in session one alone.

**The user-flow analysis agent is the unsung hero.** Across both planning sessions, it found over twenty edge cases that brainstorming missed. These are the bugs that ship to production and generate confused support tickets.

**The workflow is a guide, not a cage.** I used the full sequence (brainstorm, refine, plan, technical review, build, quality review) in session one, a trimmed version in session two, and a mix of structured and ad-hoc work in session three. Wingspan adapts to how you actually work.

**Human judgment still drives the product.** I pushed back on implementation choices, caught bugs that review agents missed, spotted UI issues that required actually running the app, and made UX decisions that shaped the architecture. Wingspan handles the scaffolding and catches the details; the developer sets the direction.

**How you frame the project matters.** Calling something a "demo" gives the AI permission to cut corners. If you want production-grade architecture, set that expectation upfront. The AI responds to the same context cues a junior developer would.

**AI tools have knowledge gaps, and that's fine — if you're aware of it.** Deprecated packages, blocked API models, missing platform configuration — these are areas where the developer's real-world testing complements what AI agents can verify. We're building detection for these gaps into future Wingspan versions.

## Try It Yourself

Wingspan is designed for teams that want AI to handle the repetitive analysis and review work while keeping developers focused on decisions that matter. If you're building Flutter apps and want to see what a structured AI workflow looks like in practice, [reach out](https://verygood.ventures/contact) — we'd love to show you.

