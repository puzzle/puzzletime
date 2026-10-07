# Agent guide

Instructions for LLM/agent tools working in this repo.

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/):
`type(scope): summary` (e.g. `refactor(assets): shim forms`).

- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`,
  `ci`, `chore`, `revert`. Scope optional; `!` marks a breaking change.
- Imperative, lowercase after the type, no trailing period, subject ≤ 72 chars.
- Short body, bullet points where possible. Put longer rationale in the relevant
  doc and reference it from the body — do not inline long prose.

Enforced by `overcommit` (`.overcommit.yml` → `CommitMsg/MessageFormat`).
Canonical reference: [CONTRIBUTING.md](CONTRIBUTING.md#commit-messages).
