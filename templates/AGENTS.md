# Project instructions

Describe the project and its working agreements from the codebase. Preserve
existing project instructions. Keep project-specific guidance outside the
agents-control managed block.

## Documents and workflows

Team setup adds a managed shared manifest here. Resolve document locations with
`sh .agents-control/context.sh resolve DOC` before writing. Use `--read` to find
existing entries and edit their containing file. Ask when an entry or task owner
is ambiguous. Optional documents are created only when needed.

Shared workflows live in `.agents/skills/`; `.claude/skills/` contains generated
adapters. Read `.agents/skills/unslop/SKILL.md` for writing rules. Preserve edited
resources and resolve ownership conflicts before updating. Personal guidance and
private paths come from registered personal context, never this shared file.
