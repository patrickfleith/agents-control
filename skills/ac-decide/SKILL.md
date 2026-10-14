---
name: ac-decide
description: Record, revise or revoke a personal project decision in private agents-control docs. Use when the user asks for ac-decide or to record a decision with agents-control.
---

# decide

## Private documents

Run `agents-control context` once and `agents-control resolve DOC` for each
needed document. Use only the returned private paths. If setup is missing, ask
the user to run `agents-control init`. Do not use repository docs as a fallback.
Read existing entries before editing. Create optional docs only when needed.

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
- Read DECISIONS.md and find the highest `DEC-NNN`. New id = highest + 1, zero-padded to 3 digits.
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
