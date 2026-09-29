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

## Writing style

Keep commit messages short: one lowercase subject matching the repo's
type(scope): description style, with no body unless needed or requested.
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
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely; indexing is the user's decision.
<!-- CODEGRAPH_END -->

## Comments, docs, and PR bodies: no transient context

Anything committed to a repo must read correctly to someone who was not present. Before every
commit, reread the diff's comments, docstrings, docs, changelog fragments, and the PR body and
delete or rewrite anything that fails these tests:

- **No dates, run IDs, pipeline/job numbers, PR numbers, ticket IDs, or people** in code comments
  or docs. Keep incident-specific evidence in chat or the PR description.
  The exception is a ticket ID in a commit subject or PR title, which is convention.
- **No history.** Not "used to", "no longer", "the old X", "was added in", "the release-candidate
  era", "how a hotfix silently did nothing". Describe the current behaviour and its consequence.
  If the past matters, it belongs in the commit message or the PR body, never in the code.
- **No narration of the investigation** or of what the reviewer should notice.
- **State the rule, then stop.** A comment justifies a non-obvious constraint in one or two
  sentences. If it needs a paragraph, the code probably needs a better name.
- **PR bodies** explain the problem and the resulting behaviour. A single link to the failing run
  is fine as evidence; quoting its log, its timestamp, or the sequence of attempts is not.

Default to fewer words. When unsure whether a comment is needed, it is not.
