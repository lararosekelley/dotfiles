---
name: discuss
argument-hint: "[idea, problem, or plan|help]"
description: Shape an idea into an actionable plan through short rounds of informed questions. Use when the user invokes /discuss or explicitly asks for an interactive planning conversation before implementation. Do not trigger for a simple question or a request to start building an already agreed change.
---

# Discuss

Help the user settle the decisions needed to implement, without implementing.
Follow current repository instructions and keep investigation read-only.

## Help dispatch

If the entire argument is `help`, `--help`, or `-h`, print Usage and stop before
investigating. Otherwise use the invocation or forwarded arguments as the topic.

## Usage

`/discuss [idea, problem, or plan|help]`

Inspect relevant context, then ask up to three focused questions per round, each
with a recommended/default answer and a short reason. With no topic, use a clear
topic from this conversation or ask what you want to discuss.

```text
/discuss a better way to review agent changes
/discuss whether this CLI needs a separate daemon
/discuss help
```

Reply naturally, redirect the discussion, or say `stop` to return to normal
conversation. When the decisions are sufficient, get a concise plan. Approval of
the plan does not start implementation; explicitly ask to build when ready.

## Investigate before asking

1. Read relevant code, instructions, and docs using the project's search guidance.
   Ask only questions that cannot be answered by inspecting the project. Keep
   research bounded to the next decision rather than surveying everything first.
2. Identify the goal, observable success criteria, constraints, and what must not
   change. Use conversation context instead of repeating answered questions.
3. Surface the next unresolved decision, assumption, dependency, or tradeoff.
   Resolve prerequisites before dependent choices. Consider doing nothing or a
   simpler solution when it meets the goal; do not assume a new feature is needed.

## Ask and converge

Ask no more than three questions per turn. For each, give a concrete recommendation
and a brief reason. Make alternatives materially different; do not invent choices
to fill a menu. Use the harness's question UI when available and useful, or plain
text otherwise. Wait for answers before the next round.

Keep agreed decisions in conversation, not new tracking files. Treat uncertainty
as uncertainty and challenge a premise when evidence warrants it. Do not keep
asking optional polish questions once scope, behavior, and verification are clear
enough to proceed. If choices require an experiment, propose it and ask before
performing work beyond read-only investigation.

## Finish or stop

Summarize agreed decisions, meaningful open questions, the recommended approach,
and the next step. Keep the plan in chat unless the user asks for a file.

Do not edit code, install dependencies, create branches, file issues, or publish
anything as part of discussion. "Yes" to a proposed design settles that decision;
it does not authorize implementation or Git operations. If the user explicitly
asks to implement, leave discussion mode and follow the normal approval rules.

On `stop`, end the questioning loop. Give a short summary only if it is useful,
then return to normal conversation without beginning implementation.
