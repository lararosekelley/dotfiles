---
name: reflect
argument-hint: "[topic|help]"
description: Propose durable improvements to agent rules and skills from the current conversation. Use when the user invokes /reflect or explicitly asks to turn session lessons or repeated corrections into workflow improvements. Do not trigger for ordinary feedback, task retrospectives, or requests to summarize work.
---

# Reflect

Help the user improve how agents work without turning every correction into a
permanent rule. Stay in this conversation and follow its approval requirements.

## Help dispatch

If the entire argument is `help`, `--help`, or `-h`, print Usage and stop before
reading files or investigating. Read the topic from the invocation or forwarded
arguments. With no topic, use the current conversation.

## Usage

`/reflect [topic|help]`

Propose up to three lasting improvements to agent instructions, grounded in this
conversation. A topic narrows the review, for example:

```text
/reflect
/reflect the repeated corrections during review
/reflect help
```

Each proposal names its evidence, intended scope, and exact edit. Nothing changes
until you approve it. Reply with proposal numbers, revise a proposal in plain
language, or say `stop` to return to normal conversation. This does not file issues
or publish anything. Use `/audit` to assess existing rules more broadly.

## Find useful lessons

1. Start from the current conversation. Do not scan other projects or transcript
   stores unless the user explicitly names that scope. If context is missing,
   say so; do not invent corrections or approval history.
2. Separate explicit lasting preferences, repeated corrections, and one-off task
   choices. Silence is not approval. One incident may justify a narrow bug fix,
   but not a universal rule. Prefer proposals that change a future decision.
3. Read the relevant existing rule or skill before proposing changes. Check
   whether the instruction is missing, contradictory, too vague, or simply was
   not followed. Do not duplicate a clear existing rule because adherence failed.
4. Choose the right home: personal preferences in shared global rules, repository
   conventions in project instructions, repeatable workflows in skills. Prefer
   a test, lint rule, or permission control for mechanically enforceable behavior.
   Explain when an instruction alone cannot enforce the requirement.
5. Respect the user's delegation policy. Do not launch reviewer panels by default.

## Propose and apply

Present at most three proposals. For each, give a brief observation from this
session, the target path/scope, and the smallest exact replacement or addition.
For a code-level enforcement proposal, name the behavior and check instead of
pretending a prose edit implements it. Avoid a full session recap.

Ask which proposals to apply and wait. If none are useful, say so and stop.
Do not automatically create backlog items, new skills, or tracking files.

Apply only approved proposals after re-reading their targets. Edit the canonical
source when harnesses share a file. Preserve unrelated rules and local changes.
If a request substantially changes a proposal, show its revision before applying.
Follow any skill-authoring guidance for substantive skill changes; validate the
affected files and describe behavioral verification that remains untested.

Finish with one line per applied change and any deferred proposal. Editing rules
does not authorize commits, pushes, or external messages. On `stop`, preserve
completed edits and return to normal conversation without further investigation.
