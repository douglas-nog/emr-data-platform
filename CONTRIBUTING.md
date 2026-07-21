# Contributing

## Branches

- `main` — protected, mirrors production. Merges only through an approved PR.
- `develop` — integration.
- `feature/<scope>` — work in progress.

Nothing goes straight to `main`.

## Workflow

1. `pre-commit install` on first setup.
2. Branch off `develop`.
3. `make lint` before committing.
4. Open a PR; CI posts the `terraform plan` as a comment.
5. Merge after approval and a green CI run.

## Commits

Conventional Commits: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`.
Add a scope when useful: `feat(catalog): add per-domain LF-Tags`.

## Architecture decisions

Every decision with a meaningful alternative becomes an ADR under `docs/adr`, in MADR 4.0
format, using `docs/adr/template.md`. Accepted ADRs are not edited: supersede them with a
new record that references the previous one.

## Language

All code, comments, identifiers, documentation, and commit messages are written in English.
