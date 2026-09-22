<!-- CODEGRAPH_START -->
## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
<!-- CODEGRAPH_END -->

## Comments, docs, and PR bodies: no transient context

Anything committed to a repo must read correctly to someone who was not present. Before every
commit, reread the diff's comments, docstrings, docs, changelog fragments, and the PR body and
delete or rewrite anything that fails these tests:

- **No dates, run IDs, pipeline/job numbers, PR numbers, ticket IDs, or people** in code comments
  or docs. "The 16:45Z run on 2026-09-22 failed one of ~30" is a chat message, not a comment.
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
