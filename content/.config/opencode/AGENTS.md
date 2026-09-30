## Permission before acting on my behalf

Always ask for confirmation before committing, amending or rewriting commits,
pushing, or posting comments, replies, or reviews on PRs/MRs. This applies to
shell commands, CLIs, MCP tools, and wrappers such as git-stk.

Show the proposed commit messages and scope, push destination and commits, or
exact comment/reply text and target before asking. Wait for my confirmation,
even if the initial task asks you to commit, push, or reply. One confirmation can
cover an explicitly listed batch; it does not authorize later or changed actions.
Approval to edit code or wording is not permission to publish it.

## Branches and worktrees

Use git-stk for stacked branch workflows and its built-in worktree management
for creating, switching, and removing worktrees. Check `git stk --help` and the
relevant subcommand help before using unfamiliar commands. If git-stk is
unavailable or cannot handle the operation, ask before using another workflow.
The confirmation requirements above still apply to git-stk operations.

## Existing work and verification

Inspect existing changes before editing. Preserve unrelated work and staging
choices; do not reset, restore, or overwrite them to simplify the task.

Run checks relevant to the change. State what actually ran, what passed, and what
remains unverified. Do not substitute linting for behavioral verification or
repeat successful checks without a reason.

## Writing style

Follow the repository's commit convention. Otherwise use a short lowercase
type(scope): description subject, without a body unless needed or requested.
Keep PR/MR descriptions to a few short sentences or simple bullets covering the
problem, change, and relevant verification. Follow required repository templates.
Keep comments, replies, docs, and chat concise too.

Use plain text and ASCII punctuation in authored prose. No em/en dashes, Unicode
arrows, smart quotes, emoji, or decorative symbols. Use hyphens, straight quotes,
and words such as "to" instead. Avoid decorative formatting; use Markdown only
when requested or needed by the document, template, or code presentation.
Preserve exact identifiers, quoted source text, and non-English content.

<!-- CODEGRAPH_START -->
## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call: the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
- **Shell** (when installed): `codegraph explore "<symbol names or question>"` prints the same output.

If the index or tool is unavailable, use normal repository search and mention any
material limitation. Do not create or rebuild an index without being asked.
<!-- CODEGRAPH_END -->

## Maintained prose

Before committing, reread comments, docstrings, docs, and PR text for someone who
was not present. Keep session-specific investigation details out of maintained
code and docs. Preserve history, dates, references, and attribution when they are
part of the document's purpose or explain a lasting constraint.

- Describe current behavior unless the document calls for historical context.
- Do not narrate the investigation or tell the reviewer what to notice.
- A comment justifies a non-obvious constraint in one or two sentences. If it
  needs a paragraph, the code probably needs a better name.
- PR bodies explain the problem and resulting behavior. Link to evidence rather
  than reproducing logs or the sequence of attempts.

Default to fewer words. When unsure whether a comment is needed, it is not.
