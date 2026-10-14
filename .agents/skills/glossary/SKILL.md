---
name: glossary
description: Manage GLOSSARY.md — add or refine a canonical term, extract terms from the current conversation, or audit for conflicts and duplicates. Use when the user says "define this term", "add to the glossary", "build a glossary", "what do we call this", or wants to harden terminology
---

# glossary

## Resolve destinations first

If the repository has `.agents-control/context.sh`, call it with `sh`.
Otherwise use the installed `agents-control` CLI. Both expose `resolve DOC`.
Resolve the concrete path and visibility before editing; never assume a docs folder.
Use `--scope=private` or `--scope=shared` when the request establishes its audience.
An invalid configuration or unavailable private workspace stops the write.

For new material, run `resolve GLOSSARY` with an explicit scope if needed.
For an existing entry, use `resolve GLOSSARY --read` and find it in the returned
files. Keep edits in the containing file. Ask if identifiers or headings match
multiple files. Unclassified legacy entries need an explicit migration destination
before editing. Do not recreate content that was moved to shared storage.


Maintains `GLOSSARY.md` — the single source of truth for what terms mean in this project. Reference doc: opinionated, tight, skimmable. No implementation details or code.

## Locate the file

Edit `GLOSSARY.md` at its resolved path. If it doesn't exist, create it with this structure:

```markdown
# Glossary

**<Term>** — one or two sentence definition in this project's context. _avoid:_ <synonyms to not use>
```

Format per term: a bold term, an em-dash, one or two sentences saying what it **is** (not what it does), and an optional `_avoid:_` list of synonyms to kill. One term per line. Keep alphabetical, or group under `##` subheadings only when natural clusters clearly emerge.

## Modes

**1. Add a term**
Append (or insert alphabetically) one line in the format above. Pick the best word as canonical; list rejected synonyms under `_avoid:_`.

**2. Refine a term**
Locate the existing line and tighten its definition or update its `_avoid:_` list in place. Don't duplicate the term.

**3. Extract from this conversation**
Scan the discussion for project/domain-specific nouns and concepts. For each: pick a canonical term, write a one or two sentence definition, and note synonyms actually used in the conversation under `_avoid:_`. Add all new terms; refine any already present.

**4. Audit**
Read the whole file and report (inline, to the user): duplicate/near-duplicate terms, definitions longer than two sentences, generic programming terms that don't belong, and any term used two ways. Propose fixes; apply on confirmation.

## Rules

- **Be opinionated.** One canonical term per concept; everything else goes under `_avoid:_`.
- **One or two sentences, define what it IS.** Cut anything longer.
- **Project-specific only.** Skip generic programming concepts (array, endpoint, timeout) unless they carry special meaning here.
- **Flag conflicts, don't silently overwrite.** If a new term clashes with an existing definition, surface it to the user and let them resolve it.
- **No implementation details.** This is a glossary, not a spec or scratchpad.
