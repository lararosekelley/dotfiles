---
name: finalize
argument-hint: "[code|comments|docs|commits|pr|help] [target]"
description: Interactive, chunk-by-chunk review and editing of current work. Use when the user invokes /finalize with optional code, comments, docs, commits, pr, or help scope, or explicitly asks to walk through changes one at a time with keep/edit/remove decisions. Do not trigger for a general code review, a summary, or a request to commit or ship work.
---

# Finalize

Walk the user through the current result of their work, one meaningful chunk per
turn. Offer concise critique, apply their decisions, and wait before advancing.
Stay in the main conversation so the user can steer the review live.

## Help dispatch

Before inspecting the repository or calling forge tools, check the invocation or
forwarded arguments. If the entire argument is `help`, `--help`, or `-h`, print
the Usage section below as user-facing help and stop. Do not begin a review or
alter an existing review queue.

## Usage

`/finalize [code|comments|docs|commits|pr|help] [target]`

Review current work one chunk at a time. With no arguments, review all applicable
categories, prioritizing relevant uncommitted changes and active branch commits.
Merged work is excluded unless explicitly selected.

- `code`: implementation, configuration, and tests.
- `comments`: inline comments and docstrings.
- `docs`: standalone documentation.
- `commits`: existing or proposed commit messages.
- `pr`: the current PR/MR description or a draft.
- `help`, `--help`, `-h`: show this help without starting a review.

An optional path, Git range, or PR/MR link narrows the scope. Examples:

```text
/finalize
/finalize docs README.md
/finalize comments src/
/finalize commits
/finalize pr
/finalize help
```

Reply **keep**, **edit**, **remove**, **skip**, or **stop**, or give natural-language
feedback such as "shorter" or "show the caller". **Back** revisits a chunk;
**stop** ends the review with completed edits preserved and returns to normal
conversation. Requested local edits happen as you go. Publishing a description
or changing Git history requires explicit direction.
PR/MR access uses an available forge tool, with pasted text or drafts as a fallback.
Use `/audit` for a broader assessment of older or larger work.

## Scope

Read the scope from the invocation or forwarded arguments using the categories
in Usage. Avoid reviewing the same material twice across categories, and show
comments in context when reviewing code.

Honor explicit paths, ranges, or request links that narrow the scope. Ask briefly
about unrecognized arguments rather than silently broadening the review.

1. Follow the repository's instructions. Inspect Git status, staged and unstaged
   diffs, and relevant untracked files. Prioritize uncommitted work connected to
   the conversation; do not assume every dirty file belongs to this task.
2. Inspect a bounded amount of recent branch history when relevant work may
   already be committed. Determine the actual base from branch/PR metadata and
   repository conventions; an upstream tracking branch is not necessarily the
   review base. For stacked branches, prefer the immediate parent so earlier
   layers are not reviewed again.
3. Exclude merged or closed work by default. Do not select commits merely because
   they are recent. Use merge-base/branch comparisons and, when needed, available
   forge metadata to distinguish active work from merged work, including squash
   merges. If the base or relevance remains unclear, ask one short scope question.
4. Use conversation history to identify agent-authored work, but review relevant
   current changes even when authorship is uncertain. Never claim the agent wrote
   user changes. Preserve unrelated edits and staging choices.
5. Review the current combined result, not every intermediate version of a file.
   If Git is unavailable, use known session edits and readable current files;
   state the scope limitation briefly. If no matching material exists, say so and
   stop instead of digging into unrelated history.

Establish a lightweight queue in conversation before presenting the first chunk.
Track pending, awaiting approval, accepted, or skipped; record edits separately
from approval. Use stable chunk identifiers, including when splitting or adding
chunks. Give a one-sentence inventory and an estimated total, then start unless
a scope question is blocking. Do not create tracking files unless asked.

On resume or after context loss, reconstruct the queue from the conversation and
current files. Never infer approval from an edit alone. If a decision cannot be
recovered, mark it pending and briefly explain the uncertainty.

## Present one chunk

Choose semantic units: a small function, a related group of edits, one comment
with the code it explains, a documentation section, or one commit message.
Group related low-risk material into one decision. Aim for roughly 15–40 lines
of code or prose per turn. Split larger units at sensible boundaries; show
additional context when requested rather than dumping files.

Use this shape:

````text
**2/7 · src/sync.rs:80–94 · replacement handling**

```diff
<focused diff or current text>
```

**Suggestion:** <one sentence, only if useful>

Keep, edit, remove, skip, or stop?
````

Show actual material, not a summary in place of it. Prefer a focused diff for
code and current text for prose/messages. Keep commentary outside the snippet to
at most two short sentences, excluding the decision prompt. Put critique after
the material. Omit routine praise and duplicate explanations. Expand reasoning
only when asked. End the turn and wait for the user's decision; do not review
the next chunk or apply your own suggestion before they respond.

Offer suggestions only when they materially improve correctness, clarity, or
maintenance; a chunk does not need a suggestion. Follow
local writing rules. Comments should explain non-obvious constraints; docs should
describe current behavior. Commit messages and PR/MR descriptions should explain
the problem and resulting change, with claims supported by the actual work.

## Apply decisions

- **Keep:** mark accepted and present the next chunk.
- **Edit/tweak:** interpret natural-language feedback and apply the targeted edit
  immediately. Re-read the affected material first if it could have changed.
  Mark substantial revisions awaiting approval and show them before advancing.
  An explicit, straightforward wording request can be marked accepted once applied;
  briefly confirm and continue. If ambiguous, ask about this chunk.
- **Remove:** for a diff, reject only the selected change: delete additions,
  revert modifications, or restore deletions while preserving unrelated edits.
  For current text, delete only a clearly identified passage. Ask when rejecting
  a change and deleting a passage would differ, the selection is unclear, or
  dependent code is affected. Never use a whole-file restore to reject a chunk.
  For commit messages, clarify the wording change; never drop the commit.
- **Skip:** leave unchanged, mark unreviewed, and advance.
- **Back:** revisit the requested or previous chunk in its current form. This does
  not undo an edit automatically.
- **Stop:** end the review loop and preserve completed edits. Briefly report
  accepted/skipped work, the next unresolved chunk, and pending checks.
  Return to normal conversation without another review
  prompt or automatically running finish checks. Resume only when explicitly
  asked, checking that the queued material still matches.

Carry style feedback forward to pending chunks. Do not silently rewrite accepted
chunks; revisit them if subsequent edits affect their correctness. Questions such
as "why?" or "show the caller" keep the current chunk open.

Edits to committed code remain working-tree edits. Reviewing a commit message
does not authorize rewriting history: keep approved replacement messages in the
conversation until the user explicitly authorizes the Git operation. Invoking
this skill does not authorize staging, committing, amending, rebasing, pushing,
merging, or submitting a formal forge review.

## PR/MR descriptions

Use an available, authorized integration for the repository's forge: a CLI, MCP,
or a tool such as git-stk. Inspect its help/schema before using unfamiliar
operations; do not assume GitHub or invent git-stk/GitLab/Gitea commands.

Resolve the request from an explicit link or the current branch and repository.
Fetch its current description, state, and base/head metadata. For stacks, select
the request for this branch rather than every request in the stack. Ask if multiple
targets remain plausible. Exclude merged/closed requests unless explicitly selected.

Review description sections one at a time against the relevant diff and any
repository template. Preserve unrelated sections and template structure. Keep
title editing outside the scope unless asked. Do not invent test results.

When the user explicitly requests an edit to the live description, apply it with
the available integration and verify the result. Re-fetch and apply only the
approved changes to the latest body, preserving concurrent edits. Otherwise keep
revisions as a draft in the conversation and ask before publishing. If access is unavailable,
ask for the pasted description or use an existing draft; explain briefly that
remote updates are unavailable and continue reviewing what can be read. Do not
create a PR/MR just to review a description. In an all-category review, mark an
unavailable description as skipped rather than blocking the local review.

## Finish

Run relevant checks after a coherent set of code edits and before declaring the
review complete. For prose-only edits, check the diff and applicable formatting.
Report only edits made, skipped/unresolved chunks, verification results, and any
approved commit-message or PR/MR draft still awaiting application. Keep the
summary short and distinguish reviewed material from material merely skipped.
