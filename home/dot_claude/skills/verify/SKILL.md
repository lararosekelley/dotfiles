---
name: verify
argument-hint: "[change, behavior, or path|help]"
description: Verify a change using the project's existing tests and check procedures. Use when the user invokes /verify or explicitly requests an evidence-based verification pass. Do not trigger for routine questions, general review, or as a replacement for required checks during implementation.
---

# Verify

Choose evidence that tests the changed behavior. Reuse the project's checks rather
than creating a parallel test system. Follow current user and repository permissions.

## Help dispatch

If the entire argument is `help`, `--help`, or `-h`, print Usage and stop before
inspecting the repository or running commands. Otherwise use the invocation or
forwarded arguments as the target.

## Usage

`/verify [change, behavior, or path|help]`

Check a change against its intended behavior. With no target, use relevant current
work from the conversation and Git status; ask if the intended scope is unclear.

```text
/verify
/verify the worktree cleanup change
/verify src/parser.rs
/verify help
```

The result says what ran, what passed or failed, and what remains unverified.
Existing test suites, fixtures, and project verification guides take precedence.
Verification may create temporary fixtures or normal build output; it does not
authorize code fixes, snapshot acceptance, publishing, or live-data mutations.
Say `stop` to end the pass and return to normal conversation.

## Select checks

1. Read project instructions, Git status, and the relevant diff. Preserve unrelated
   edits and staging choices. Identify the behavior to prove and any behavior that
   must remain unchanged. Do not assume every dirty file belongs to this task.
2. Read the existing test recipes and relevant CI configuration. Use a project-local
   verification skill or guide when available; locate it through project instructions
   or skill metadata. Do not invoke another generic `/verify` recursively.
3. Pick the smallest meaningful check and broaden only when dependencies or risk
   warrant it. Reuse existing fixtures. Docs-only changes usually need formatting,
   links, and command accuracy checks, not the full behavioral test suite.
4. Inspect unfamiliar test/CI scripts before running them. Distinguish offline tests
   from commands that install dependencies, contact paid services, rewrite files,
   or mutate remote state. A command named test or dry-run is not proof of safety.
5. State the selected checks briefly. Ask before commands outside the requested
   scope or approval boundary; do not silently enable real credentials or services.

## Execute and judge

- Run existing checks against the actual implementation. Use temporary repo/home
  fixtures for stateful operations, never the user's live data as a test fixture.
- Prefer non-fixing lint/check modes. Do not update expected output just to make a
  test pass. A failing test is evidence to report, not automatic permission to edit.
- If no check covers the important behavior, state the gap and propose the smallest
  reproduction or regression test. Do not build a new harness without agreement.
- Keep build/lint success distinct from behavioral evidence. Check skipped tests,
  filters matching zero tests, platform limitations, and failures unrelated to the
  change. Mark inconclusive results rather than presenting them as passes.
- Reuse prior results only when the tested code and relevant environment still
  match; identify those results as reused. Do not rerun passing checks without a reason.
- Clean up only resources created for this pass, using the project's fixture lifecycle.
  Follow the user's worktree tooling policy for any separately requested worktree work.

## Report

Use a short list of exact commands with pass/fail/inconclusive outcomes and the
behavior each establishes. Include meaningful gaps and any next recommended check.
Do not paste long logs, claim all-platform success from one local run, or treat a
green CI status as evidence for newer uncommitted edits.

On `stop`, launch no further checks. Use supported cancellation for owned running
checks when available; otherwise report what is still running. Do not kill unrelated
processes or continue into a repair/review loop. Invoking this skill never authorizes
commits, pushes, deployments, external replies, or test runs with those side effects.
