---
name: reword
argument-hint: "[surface|path|help]"
description: Walk through a repository's user-facing text one piece at a time so the user can replace the wording with their own. Use when the user invokes /reword or explicitly asks to review UI strings, CLI help, website copy, store listings, release notes, or docs wording in their own voice. Do not trigger for reviewing current diffs, auditing doc accuracy, or general writing help.
---

# Reword

Show the user's existing user-facing text in context, one piece per turn, and
apply the wording they choose. The goal is copy in the user's voice: show text as
written and do not propose rewrites unless asked. Stay in the main conversation.

## Help dispatch

Before inspecting the repository, check the invocation or forwarded arguments. If
the entire argument is `help`, `--help`, or `-h`, print the Usage section below as
user-facing help and stop. Do not build an inventory or alter an existing queue.

## Usage

`/reword [surface|path|help]`

With no arguments, list the repository's text surfaces with rough sizes and ask
which to start with. A surface name or path starts that surface directly.

- `app`: in-app strings and copy, including help screens and dialogs.
- `cli`: command help, prompts, and error messages.
- `site`: website pages.
- `listing`: store listings and package descriptions.
- `changelog`: release notes and changelogs.
- `docs`: README, guides, and contributor docs.
- `help`, `--help`, `-h`: show this help without starting.

```text
/reword
/reword app
/reword www/index.html
/reword docs README.md
/reword help
```

Reply **keep**, **edit** with new wording or a direction, **skip**, **back**, or
**stop**. Edits are applied as you go, along with tests that pin the old wording.
Nothing is staged, committed, or published. Use `/finalize` for current diffs and
`/audit docs` for documentation accuracy.

## Inventory

1. Follow repository instructions, including notes in AGENTS.md or similar about
   where copy lives, generated files, and test procedures.
2. Find text a user or contributor reads: UI string resources and inline UI
   strings, CLI help and user-visible errors, website pages, store listings,
   release notes, README, and contributor docs. Exclude agent instructions
   (AGENTS.md, CLAUDE.md, skills, prompts), code comments, log-only messages,
   tests, and vendored or generated files unless the user names them by path.
3. Identify each surface's source of truth. Generated output, build artifacts,
   and copies produced by a script are not edited; trace them to their source.
4. With no argument, report surfaces as a short list with paths and rough counts
   (strings, sections, or pages) and ask which to start with. With a surface or
   path, give a one-sentence inventory of that scope and start. Ask about an
   unrecognized argument or nonexistent path rather than broadening the scope.

Keep the queue in conversation: pending, kept, edited, or skipped, with stable
chunk identifiers. Do not create tracking files. On resume, rebuild the queue from
the conversation and current files and re-read text before showing it again.

## Present one chunk

Group text the way a user meets it:

- String tables and inline UI strings: one screen, dialog, help topic, or command
  per chunk, roughly 5-20 strings. Show each string's key or location and where it
  appears, such as a button label or an error after a failed push.
- Prose: one section of roughly 15-40 lines, split at headings or paragraphs.
- Listings and release notes: one field or release entry per chunk.

Use this shape:

````text
3/12 - app/src/main/res/values/strings.xml - practice timer screen

```text
timer_start (button): Start
timer_paused (status line): Paused - tap to resume
```

Note: <only if the text contradicts the code or another copy>

Keep, edit, skip, or stop?
````

Show the text verbatim, with format placeholders, markup, and escapes intact.
Do not suggest wording, praise, or summarize. Add a note only when the text is
factually wrong against the code (a renamed flag, a removed feature, a wrong
default) or when the same copy appears elsewhere and differs. End the turn and
wait for the user's decision.

## Apply decisions

- **Keep:** mark kept and present the next chunk.
- **Edit:** apply the user's wording exactly. When they give a direction instead
  of wording ("shorter", "less formal"), draft it, show it, and wait for approval
  before applying. Preserve placeholders, escaping, markup, and line-length or
  character limits the surface imposes; ask when the new wording conflicts with one.
- **Skip:** leave unchanged and advance.
- **Back:** show a previous chunk in its current form.
- **Stop:** end the loop, preserve completed edits, and give the finish report.

With each applied edit:

1. Edit only the source of truth. Never hand-edit generated output.
2. Search for tests, fixtures, and snapshots that pin the old wording and update
   them in the same step. Name the files touched.
3. If screenshot or golden tests cover the changed text, say so and run the
   repository's recording task at the finish rather than after each edit.
4. Report other copies of the same text (README and website, listing and docs)
   and ask before editing them.

Carry style preferences the user states forward when drafting from directions,
but never rewrite pending chunks on your own.

## Finish

After the walk or on stop, run the checks covering edited text: unit tests that
pinned wording, golden recording or verification, and the repository's lint for
edited files. Re-record goldens only for chunks the user edited, and list every
golden file the recording changed so none are accepted silently. Report edits
made, pinned files updated, skipped chunks, copies left to reconcile, and what
remains unverified. Invoking this skill does not authorize
staging, committing, or publishing listings or releases.
