---
name: ac-init
description: Set up private agents-control notes in this checkout. Use when the user asks for ac-init or to set up agents-control here.
---

# Set up private notes

1. Run `agents-control init` in the current checkout. If the CLI is unavailable,
   provide the install command from the agents-control README and stop.
2. Run `agents-control context` and read the new documents.
3. Inspect the codebase and fill PRD.md and STACK.md with facts you can establish.
   Ask about missing goals or requirements. Leave existing content intact.
4. Add tasks, roadmap entries or decisions only when the user has supplied them.
5. Run `agents-control doctor` and report the private folder's location.

Setup uses docs-agents-private/ and a local Git exclusion. All document types and
six workflows are available. Create optional documents when needed.
