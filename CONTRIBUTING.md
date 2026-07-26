## Branches

| Branch | Environment | Purpose |
|---|---|---|
| `main` | `prod` | protected, mirrors production |
| `homolog` | `hom` | pre-production validation |
| `develop` | `dev` | integration |
| `feature/<scope>` | — | work in progress |

Nothing goes straight to `main`. Changes flow
`feature/<scope>` → `develop` → `homolog` → `main`.

## Workflow

1. Branch off `develop`: `git checkout -b feature/<scope>`.
2. Deploy and validate on `dev` from the CLI.
3. Open a PR into `develop`.
4. Promote `develop` → `homolog`, then `homolog` → `main`, each through a PR.

Deployments run from the CLI during development. The CI/CD pipeline takes over
in roadmap phase v9, when the OIDC deploy role exists.