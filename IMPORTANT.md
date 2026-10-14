# Required changes to agents-control

agents-control needs to support personal use on a shared codebase, selective sharing with a team, and official team adoption. Installation and migration must support all three modes. This file records required work and open design questions. It does not settle the implementation.

## Installation modes

### 1. Private use

- A developer can use agents-control alone in a shared repository without adding personal docs, skills, or agent instructions to the team's tracked files.
- Keep personal artifacts local. Consider `.git/info/exclude` for files inside the working copy so personal exclusions do not require changes to the team's `.gitignore`.
- Define how agents discover personal instructions and skills when the repository already has shared agent configuration.
- Preserve existing team files and configuration during installation.

### 2. Private use with selected shared docs

- Keep personal docs, skills, and configuration private, as in mode 1.
- Allow selected docs or selected parts of docs to be shared with the team.
- Put shared content in a separate folder, proposed default `docs-agents-shared/`. Support a folder name or path chosen by the team.
- Define how selected sections become shared content, how updates reach the shared version, and how to avoid conflicting copies.
- Make the destination of each write clear to the developer and the agent. Sharing one doc or section must not expose unrelated personal content.
- Team members should be able to read the shared docs without adopting agents-control themselves.

### 3. Official team use

- Support agents-control as the team's agreed system for project docs, agent instructions, and skills.
- Track the shared artifacts needed for collaborators to use the system after cloning the repository.
- Keep a private area available to each developer. Team adoption should still allow personal working material.
- Define what belongs in that private area. Candidates include personal tasks, scratch notes, unshared ideas, and individual agent preferences or skills.
- Define how personal instructions and skills interact with shared instructions and skills, including conflicts and precedence.

## Installation requirements

- [x] Provide explicit installation modes for private use, selected sharing, and official team use.
- [x] Record the selected mode and the configured private and shared paths so subsequent commands use the correct destinations.
- [x] Apply the selected mode to docs, manifests, skills, and tool adapters. Hiding docs alone is insufficient.
- [x] Update setup and writing skills so they understand private and shared destinations instead of assuming every doc belongs in `docs-agents/`.
- [x] Manage local exclusions without overwriting unrelated entries. Exclusions must target agents-control's private artifacts without hiding team-owned files.
- [x] Explain the limits of local exclusions. Already tracked files need separate handling, and Git exclusions do not provide access control or confidentiality.
- [x] Define behavior for existing team instructions, skills, and docs. Installation must preserve them and handle conflicts explicitly.
- [x] Document which artifacts remain local and which are available to collaborators or agents working from a fresh clone.

## Migration requirements

- [x] Support migration from the existing agents-control layout and behavior into each of the three modes.
- [x] Support every transition between the new modes, including the gradual path from private use to selected sharing to official team use.

| Starting mode | Required destinations |
| --- | --- |
| Existing agents-control installation | Private, selected sharing, official team use |
| Private | Selected sharing, official team use |
| Selected sharing | Private, official team use |
| Official team use | Private, selected sharing |

- [x] Allow users to choose which docs and sections to share or keep private during migration.
- [x] Preserve content, user edits, existing team configuration, and unrelated files. Handle destination conflicts without silently overwriting content.
- [x] Update paths, manifests, skills, adapters, and local exclusions together so agents can still find and write the correct docs after migration.
- [x] Support changes to configured folder names and paths.
- [x] Show a migration preview that identifies file moves, content sharing, and changes to Git tracking before applying them.
- [x] Distinguish an individual's move back to private use from removing the team's shared setup. A personal mode change must preserve shared artifacts that colleagues still use.
- [x] Explain that making previously shared content private cannot remove it from Git history or colleagues' existing clones.
- [x] Make installation and migration safe to rerun, with a recovery path if migration stops partway through.

## Open design questions

- What are the private storage location and discovery mechanism for each supported agent tool?
- Should `.git/info/exclude` be the default private installation mechanism, or should some artifacts live outside the repository?
- Is `docs-agents-shared/` the default shared folder in both selected sharing and official team use? How does the existing `docs-agents/` folder migrate?
- How should users select, publish, and maintain shared sections of otherwise private docs?
- Which docs, instructions, and skills should official team use share by default? Which personal artifacts should remain private?
- How should agents resolve overlapping private and shared guidance and choose the destination for a new entry?
- Which defaults best preserve existing installations without accidentally publishing personal material?

Implementation and behavior coverage are recorded in [PLAN.md](PLAN.md). Native
host discovery remains pending as specified there. Git and confidentiality limits
are in the [usage guide](docs/usage.md#ownership-git-and-updates).
