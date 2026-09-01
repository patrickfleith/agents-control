# Agents Control

_The original brief for agents-control, written before any of it was built.
Content preserved as written; only formatting has been applied, and the
per-doc implementation status has moved to the [README](README.md), which is
the current source of truth for what this repo is and how it works._

## What I Want

I want an agentic coding setup that is easily understandable by contributors, maintainable and extensible, continuously in-sync with the repo, compact without excessive text, making sure developers trust the outcome, making developers feel in control, not being the bottleneck.

### Keywords

- Understandable
- Maintainable
- Controllable
- Extensible
- Trustable
- Minimal
- MVP

## To be defined

- What is user-triggered only?
- What can be also automatically changed by the model?
- How should it be organized in the repo? Probably in a local claude and .gitignore.
- What should I use and for what: Skills? Command? Agents? Rules?
- Are Hooks useful possibly?
- We probably want it to be connected to github or linear MCP.

## Capabilities

- First we make it work for claude, then also for codex.
- Made primarily for solo dev with occasional contributors.
- Commit commands, rules, styles.
- Code review capabilities.
- Documentation update.
- PR creations, PR reviews.

Agents must be aware of how to handle the various markdown files and what to do with them (read-only for information and context access, write, create), etc.

Must ultimately work at different stages of software development:

- **Greenfield work** — project creation.
- **Brownfield work** — existing project you jump in.

## Optional capabilities

Distinguish between throwaway vs production code.

- **Throwaway code** — experimental code for testing stuff, user research, quick analyses, demo features, etc. — so that code that don't need attention during a code review. Does not require thorough testing or evals etc.
- **Production code** — code that delivers the core of the value from the project. It must work, be maintained over time. It is more annoying if something breaks than for throwaway code.

## A set of human-friendly readable markdown files

At product Level we have:
- PRD + ROADMAP

At feature level we have:
- FRD + PLAN

- **README** — Entry point to the project.
- **SUM** — Software and User Manual covering installation guide, quickstart, and detailed usage guide per feature.
- **PRD** — Product Requirement Document describes the requirements at product level. Also contains high-level business context and motivation, user needs, etc.
- **STACK** — Project-level stack (frameworks, libraries, etc.).
- **ROADMAP** — Describes the overall project roadmap: upcoming features, things to work on, rework, improve, fix.
- **FRD** — Feature Requirement Document describes the requirements at feature level.
- **PLAN** — For difficult features, we may need an implementation plan. It is narrower than the roadmap as it targets a specific slice of the roadmap, but made to carry info across multiple sessions.
- **GLOSSARY** — Definition of the terms, disambiguated words, and how to interpret terms in the context of a given project.
- **IDEAS** — A set of ideas that needs to be captured before we forget them, a question to myself of a possibility, an investigation.
- **CONCERNS** — A set of concerns about the project, product, feature which might need to be investigated, or be helpful to capture to relate to bugs.
- **EVALUATIONS** — Specific for AI/ML projects. Describes how the product / features are evaluated.
- **TESTS** — Test Guide for traditional tests, the kind of tests that cover non-AI/ML parts.
- **QUESTIONS** — Questions (not decisions) that I may need to find an answer to (by doing some research, asking a colleague, etc.) that relate to some piece of the work (future work, ongoing or past implementation). Includes the answer once it was answered.
- **TASKS** — At repo level, dump your todos here; avoids having to bloat the context by looking up issues for small things.
- **DECISIONS** — Contains two broad sections: TBD (to be decided) with pending decisions, and then Decided. Captures meaningful decisions made over the course of the project (architecture decision, prioritization, tool, default value).
- **UXUI** — Optional. Contains guidelines and rules for maintaining a high bar for the user experience (even for a CLI tool) and user interface (best practices, rules, etc.).
- **CHANGELOG** — Should contain a chronological, human-readable list of notable changes made in each released version of the project.
- **DEPLOYMENT** — How the project is built, released, and run per environment: release steps, configuration/secrets, and rollback.
