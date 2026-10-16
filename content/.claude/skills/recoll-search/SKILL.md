---
name: recoll-search
description: Query the local Recoll full-text index for ranked, conceptual searches across code, docs, Markdown, and PDFs when the exact symbol or string is unknown. Use when the user asks for an indexed or Recoll search, or when CodeGraph and grep cannot locate a concept by name. Do not trigger for exact symbol or string lookups, call-path questions, or repositories outside the indexed directories.
---

# Recoll search

Recoll is a full-text indexer configured on this machine for repositories under
`~/Code` (config at `~/.recoll/recoll.conf`). Confirm that `recoll` is installed
and indexes the relevant directory before relying on it.

## When to use it

Follow the search order in global and repository instructions: CodeGraph where a
`.codegraph/` index exists, then grep/ripgrep for exact symbols and strings.

- Use Recoll for broad conceptual searches ("where do we compute retry backoff"),
  for prose in docs, comments, Markdown, and PDFs, or when the right term is unknown.
- The index updates on a schedule, not on every save. Verify a result with a fresh
  grep or read before trusting it, especially for renamed or deleted code.

## Basic query

```bash
recoll -t <query>
```

- `-t` is terminal query mode. Always pass it; without it Recoll launches the GUI.
- Bare words are ANDed: `recoll -t retry backoff` finds documents with both terms.
- Quote phrases: `recoll -t "retry backoff"` matches adjacent words.
- Exclude a term with a leading `-`: `recoll -t cache -redis`.
- OR binds tighter than implicit AND: `t1 OR t2 t3` means `(t1 OR t2) AND t3`.
- Wildcards: `recoll -t 'parse*'` (quote to prevent shell globbing).
- Stemming: lowercase terms stem-expand (`sync` matches `syncing`); capitalized
  terms match the exact form only, which avoids noisy matches on common words.

## Field and filter searches

- File extension: `ext:rs`, `ext:md`, or another relevant extension.
- Directory subtree: `dir:src/sync`.
- Combined: `recoll -t dir:src/sync ext:rs RetryPolicy`.
- Metadata fields such as `title:"..."` are less useful for source code.

## Useful output flags

- `-b`: bare URLs only, for piping into other tools.
- `-a`: all-terms mode (AND every bare word).
- `-o`: any-term mode (OR every bare word).
- `-n <count>`: limit the result count.
- `--paths-only`: print `file://` results as plain absolute paths.
- `-A`: include an abstract per result to judge relevance before opening files.

### Recommended default invocation

```bash
recoll -t -a --paths-only -n 30 <terms>
```

This returns a capped list of absolute paths matching all terms. Follow up with a
read or a targeted grep.

## Keeping the index fresh

Check status:

```bash
cat ~/.recoll/idxstatus.txt
```

Rescan incrementally, re-indexing only changed files:

```bash
recollindex
```

A full rebuild (`recollindex -z`) is slow and rarely needed. If results look stale,
suggest running `recollindex` before trusting them.
