---
name: decide
description: Record decisions in DECISIONS.md — add a TBD (open question), log a decided decision, or revise/revoke an existing one. Use when the user says "decide", "we decided", "log a decision", "that's TBD", or wants to change/revoke a past decision
---

# decide

## Resolve destinations first

If the repository has `.agents-control/context.sh`, call it with `sh`.
Otherwise use the installed `agents-control` CLI. Both expose `resolve DOC`.
Resolve the concrete path and visibility before editing; never assume a docs folder.
Use `--scope=private` or `--scope=shared` when the request establishes its audience.
An invalid configuration or unavailable private workspace stops the write.

For new material, run `resolve DECISIONS` with an explicit scope if needed.
For an existing entry, use `resolve DECISIONS --read` and find it in the returned
files. Keep edits in the containing file. Ask if identifiers or headings match
multiple files. Unclassified legacy entries need an explicit migration destination
before editing. Do not recreate content that was moved to shared storage.


Maintains `DECISIONS.md`. Keep entries terse.

## Locate the file

Edit `DECISIONS.md` at its resolved path. If it doesn't exist, create it with this structure:

```markdown
# Decisions

## TBD

- **<Shortname> — <pending decision>** — options/context in one line.

## Decided

### DEC-001 — title

Decided by: Author | Author with Agent | Agent
Date: YYYY-MM-DD HH:MM

**Decision:** 1–2 sentences (what was decided).

**Rationale:** 1–2 sentences (why).
```

## Modes

**1. Add a TBD** (open question requiring a decision to move forward, not yet decided). 
Not to be confused with an open question from `QUESTIONS.md` which do not related to decision.
Append to the `## TBD` list:
```
- **<Shortname> — <pending decision>** — options/context in one line.
```

**2. Log a decided decision**
- Use `resolve DECISIONS --read` and find the highest `DEC-NNN` across returned files. New id = highest + 1, zero-padded to 3 digits. This avoids reusing IDs after sharing.
- Prepend the new entry to the top of `## Decided` (newest first).
- Get the timestamp by running `date "+%Y-%m-%d %H:%M"`.
- If it resolves a `## TBD` item, remove that TBD line.
```
### DEC-NNN — <title>

Decided by: Author | Author with Agent | Agent
Date: YYYY-MM-DD HH:MM

**Decision:** 1–2 sentences (what was decided).

**Rationale:** 1–2 sentences (why).
```
Set "Decided by" to who actually decided (ask if unclear; default `Author with Agent`).
`Author` means the person using the skill.
`Agent` means the coding agent harness in use.

**3. Revise a decision**
Locate the `DEC-NNN`. Do NOT rewrite history silently — append a revision note under the existing entry:
```
**Revised (YYYY-MM-DD HH:MM):** what changed and why. Supersedes original decision above.
```
Then move the whole entry to the top of `## Decided`. Keep its original id — the number is a stable reference, not a sort key, so recently-touched decisions surface first even if ids end up out of numeric order.

**4. Revoke a decision**
Prefix the title with `~~REVOKED~~` and append:
```
**Revoked (YYYY-MM-DD HH:MM):** reason. No longer in effect.
```
Then move the whole entry to the top of `## Decided` (same rule as revise) — a revocation is important activity, so surface the "no longer in effect" warning rather than leaving it buried.

## Rules

- Never renumber existing DEC ids.
- Always stamp real timestamps via `date`, never guess.
- Keep it skimmable — 1–2 sentences per field.
