---
name: teach
argument-hint: "[topic or change|help] [level or focus]"
description: Teach a repository-specific concept or change through a source-backed mental model and worked example. Use when the user invokes /teach or explicitly requests a deeper explanation to understand code. Do not trigger for a brief factual answer, ordinary code review, or an implementation request.
---

# Teach

Build understanding of the code without overwhelming the reader. Follow current
repository instructions, use plain language, and keep the work read-only.

## Help dispatch

If the entire argument is `help`, `--help`, or `-h`, print Usage and stop before
investigating. Otherwise read the topic and requested level from the invocation
or forwarded arguments.

## Usage

`/teach [topic or change|help] [level or focus]`

Explain a concept with a small mental model, one concrete example, and evidence
from the actual code. With no topic, use a clear topic from this conversation or
ask one question. Default to an experienced developer new to this subsystem.

```text
/teach how this PR changes retries
/teach sync filtering, focus on why both directions use the repo
/teach worktrees step by step, assume I know branches
/teach help
```

Add a level, focus, or "step by step" in ordinary language. In step-by-step mode,
show one concept and wait; `next` continues and `stop` returns to normal conversation.
Otherwise give a compact explanation without a mandatory quiz. Use `/how` for
a short execution trace and `/why` for a historical-rationale investigation.

## Build the explanation

1. Identify what the user wants to understand and what they already know from
   the conversation. Do not force an interview when a reasonable default suffices.
2. Read the relevant code and trace one representative input to its result.
   Reuse evidence already gathered, verifying it against current files when needed.
   Do not automatically run `/how` and `/why` as separate full investigations.
3. Investigate history only when it helps answer the requested rationale. Separate
   documented intent from a useful explanation of the current design. Cite sources;
   do not turn an analogy into a claim about how the implementation works.
4. Choose one mental model and a small worked example. Distinguish illustrative
   inputs from observed runtime results. Include one important boundary or failure
   case when it sharpens understanding. For a change, contrast before and after.
5. Stay read-only and follow the user's delegation policy. Do not modify code,
   start services, or run side-effectful demonstrations without a separate request.

## Present and continue

For a focused topic, aim for roughly 200-400 words initially: the central idea,
one example, and the key constraint. Use short code snippets or a small ASCII
diagram only if they reduce explanation. Cite the few source locations that let
the user check the explanation; do not list every file you opened.

Honor the requested level and expand when needed rather than enforcing a word
budget at the expense of clarity. Do not require a quiz, ask repeated comprehension
questions, or offer a long menu of next lessons. If the user requests step-by-step
teaching, wait after each concept and accept ordinary-language questions or `next`.

If evidence is missing, say what cannot be established. Do not present a plausible
explanation as proven behavior. On `stop`, return to normal conversation without
another lesson prompt or extra investigation.
