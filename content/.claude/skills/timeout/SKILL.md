---
name: timeout
argument-hint: "<duration, e.g. 5s, 200ms, 1h> <message>|help"
description: Wait for a duration, then act on a message as if the user had just sent it. Use when the user invokes /timeout, for example to check CI some time after a merge. Do not trigger for recurring polling (use /loop) or for scheduling work outside this session.
---

# Timeout

Delay acting on a message until a timer passes, without blocking the session.

## Help dispatch

If the entire argument is `help`, `--help`, or `-h`, or the argument is empty,
print Usage and stop.

## Usage

`/timeout <duration> <message>`

The duration is a number with a unit: `ms`, `s`, `m`, or `h`, such as `200ms`,
`90s`, `15m`, `1h`, or `1h30m`. Everything after the duration is the message.

```text
/timeout 15m check whether CI on main passed after the merge of #42
/timeout 1h30m look at the deploy logs for errors
```

The timer lives in this session; closing the session cancels it. Say "cancel the
timeout" to stop it early.

## Start the timer

1. Parse the first word as the duration. If it is not a valid duration or no
   message follows, print Usage and stop. Do not guess a unit.
2. Convert it to whole seconds, rounding up, with a minimum of 1.
3. Run `sleep <seconds>` with the shell tool in background mode (Claude Code:
   `run_in_background: true`; OpenCode: `background: true`) and a description
   naming the delay, such as "Wait 15m before checking CI". If the harness has no
   background mode that resumes you on exit, say so and stop. Do not use a
   foreground sleep or a polling loop.
4. Reply in one line with the delay, the local time it ends (`date -d`), and the
   message. Then end the turn. Do not start on the message early, gather context
   for it, or schedule extra wakeups.

## When the timer ends

The completion notification for that sleep is the trigger. Treat the saved
message as a new request from the user and handle it normally, following all
repository and user instructions. The delay does not authorize actions that
would otherwise need confirmation.

If the user sends other messages while the timer runs, answer them normally and
keep the timer. If they ask to cancel, stop the background sleep and confirm.
If several timers are running, match each notification to its message by ID.
