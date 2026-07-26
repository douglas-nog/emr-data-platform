# Project Roadmap — EMR Data Platform

Domain-oriented data platform on AWS: raw files land on S3, are loaded into
Apache Iceberg through a config-driven PySpark framework, modeled with dbt on
EMR Serverless, orchestrated by Airflow, and governed by Lake Formation and
OpenMetadata. Everything is provisioned with Terraform.

Status: ✅ done · 🔶 partial · ⬜ pending

## v1 — Foundation

| Item | Status |
|---|---|
| Repository structure | ✅ |
| Branch flow (feature → develop → homolog → main) | 🔶 |
| Local development environment (Python 3.11 venv, Terraform, AWS CLI) | ✅ |
| Naming convention (buckets, databases, roles, state keys) | ✅ |
| ADRs 0001–0006 (MADR 4.0) | ✅ |
| IAM auth: user assumes admin role with MFA (no Identity Center) | ✅ |
| Billing console access activated | ✅ |
| Terraform state bucket (account regional namespace, versioning, S3 locking) | ✅ |
| Bootstrap state migrated to the remote backend | ✅ |
| AWS Budgets: monthly limit + actual and forecast alerts | ✅ |
| Slice 1 scope and acceptance criteria | ✅ |
| Project roadmap | ✅ |
| Operations runbook | ✅ |
| CLI-based deploys until the pipeline lands in v9 | ✅ |

## v2 — Platform core

| Item | Status |
|---|---|
| `platform`: EMR Serverless application (release 7.13, auto-stop, capacity ceiling) | 🔶 |
| `platform`: logs bucket with 30-day expiration | ✅ |
| `platform`: artifacts bucket for job code and configs | ✅ |
| `domain`: buckets per layer (landing, sor, sot, spec) | ✅ |
| `domain`: Glue databases per table layer | ✅ |
| `domain`: EMR execution role scoped to the domain | ✅ |
| Environment split into `persistent` and `ephemeral` stacks | ✅ |
| Trivial `start-job-run` validated end to end | ⬜ |

## v3 — `macro` ingestion (Landing)

| Item | Status |
|---|---|
| Table config schema (YAML): source, schema, PK, merge keys, partitioning | ⬜ |
| `rest_api` connector (Central Bank SGS) | ✅ |
| Lambda ingestion function (arm64, layer built in Docker) | ✅ |
| Landing writer: raw JSON, partitioned by ingestion date | ✅ |
| Unit tests for connector, writer, handler (95% coverage) | ✅ |
| End-to-end invocation validated (Selic landed on S3) | ✅ |

## v3b — SOR loader (blocked on EMR)

| Item | Status |
|---|---|
| Generic SOR loader: declared schema, typing, `MERGE INTO` on Iceberg | ⬜ |
| SOR tables: `selic_daily`, `cdi_daily`, `ipca_monthly`, `ptax_usd_daily` | ⬜ |
| Idempotency proven: two consecutive SOR runs, same row count | ⬜ |
| Unit tests for the SOR loader | ⬜ |

## v4 — Transformation (SOT + SPEC), blocked on EMR

| Item | Status |
|---|---|
| dbt project wired to EMR Serverless via Spark Connect (`SPARK_REMOTE`) | ⬜ |
| Interactive session helper script (open, export, terminate) | ⬜ |
| `sources.yml`: SOR as source, with freshness and tests | ⬜ |
| SOT models: `rate_daily`, `inflation_monthly` | ⬜ |
| SPEC model: `benchmark_daily` (output port, `access: public`) | ⬜ |
| Enforced contracts on SOT and SPEC (`contract: enforced: true`) | ⬜ |
| dbt tests with `store_failures` (quarantine tables) | ⬜ |
| Contract break proven: type change without YAML update fails the build | ⬜ |

## v5 — Orchestration

| Item | Status |
|---|---|
| `orchestration`: EC2 instance + security groups | ⬜ |
| Airflow via Docker Compose, metadata in Postgres | ⬜ |
| DAG: ingestion → SOR → session → dbt build → session teardown | ⬜ |
| Dynamic task mapping: one EMR job run per table | ⬜ |
| Session teardown guaranteed on failure (`on_failure`) | ⬜ |
| Induced failure test: no orphaned session left behind | ⬜ |

## v6 — Access control and governance

| Item | Status |
|---|---|
| LF-Tag taxonomy: `domain`, `layer`, `env` | ✅ |
| Lake Formation Data Lake Administrator configured | ✅ |
| Lake Formation registers the domain's Iceberg S3 locations | ✅ |
| LF-Tags applied to the domain's databases | ✅ |
| Dedicated per-domain registration role (scoped to its buckets) | ✅ |
| Intra-domain grant: EMR role reads its own layers (SELECT/DESCRIBE) | ✅ |
| EMR role IAM policy allows `lakeformation:GetDataAccess` | ✅ |
| Strict mode: remove `IAMAllowedPrincipals` fallback | ⬜ |
| Cross-domain access denial proven (`AccessDeniedException` on SOR) | ⬜ |

## v7 — Second domain (`fundos`)

| Item | Status |
|---|---|
| `http_archive` connector (CVM monthly ZIP) | ⬜ |
| Backfill path (historical) separate from incremental path | ⬜ |
| SOR tables: `fund_daily_report`, `fund_registry` | ⬜ |
| Restatement handling: rolling-window reprocessing with MERGE | ⬜ |
| 5-year backfill executed and validated | ⬜ |
| SOT models: `dim_fund`, `fact_fund_daily`, `fact_fund_return` | ⬜ |
| SPEC models: `fund_performance_daily`, `fund_ranking_monthly` | ⬜ |
| Cross-domain consumption: `fundos` reads `macro` SPEC | ⬜ |
| Domain module reuse proven by a second instantiation | ⬜ |

## v8 — Multi-environment

| Item | Status |
|---|---|
| `hom` environment (separate state, buckets, databases, roles) | ⬜ |
| `prod` environment | ⬜ |
| Promotion flow dev → hom → prod validated | ⬜ |
| Environment isolation proven (cross-env access denied) | ⬜ |

## v9 — CI/CD pipeline

| Item | Status |
|---|---|
| GitHub OIDC provider + deploy role (no long-lived secrets) | ⬜ |
| CI: lint, unit tests, `terraform validate` | ⬜ |
| CI: `terraform plan` commented on pull requests | ⬜ |
| CD: apply per branch, prod behind an approval gate | ⬜ |
| pre-commit reinstated (fmt, tflint, terraform-docs, checkov, gitleaks) | ⬜ |
| Contract gate: manifest diff fails on breaking change without version bump | ⬜ |
| Branch protection enforced on `main` | ⬜ |
| Official deploys of all three environments through the pipeline | ⬜ |

## v10 — Catalog and data contracts

| Item | Status |
|---|---|
| OpenMetadata on a dedicated EC2 instance (stop, not destroy) | ⬜ |
| Glue metadata ingestion workflow | ⬜ |
| dbt artifact ingestion (descriptions, lineage, tests) | ⬜ |
| Data products documented with owners and glossary terms | ⬜ |
| ODCS YAML generated from `manifest.json` in CI | ⬜ |
| ODCS validated against the v3.1.0 JSON Schema | ⬜ |

## v11 — Security hardening

| Item | Status |
|---|---|
| LF-Tag dimension for sensitivity (`public`, `internal`, `restricted`) | ⬜ |
| Column-level filtering and masking through Lake Formation | ⬜ |
| Two roles proven: one sees the column, one sees it masked | ⬜ |
| S3 server access logging bucket (clears CKV_AWS_18) | ⬜ |
| IAM policy denying bucket creation outside the account regional namespace | ⬜ |
| Least-privilege review: replace the broad admin role | ⬜ |

## v12 — Observability and lifecycle

| Item | Status |
|---|---|
| dbt `run_results.json` persisted to an Iceberg operational table | ⬜ |
| CloudWatch dashboards and alarms for job failures | ⬜ |
| Iceberg maintenance: `expire_snapshots` + `remove_orphan_files` | ⬜ |
| S3 Lifecycle on Landing only (never on Iceberg layers) | ⬜ |
| Offboarding: `deprecated` flag, grace period, manual drop | ⬜ |
| Spark tuning cycle documented (executor sizing, cold start) | ⬜ |

## v13 — Documentation and polish

| Item | Status |
|---|---|
| README with architecture diagram and design decisions | 🔶 |
| ADRs covering every non-obvious decision | 🔶 |
| Runbook validated by a full teardown and rebuild | ⬜ |
| Cost report: actual spend per phase | ⬜ |

## v14 — RAG layer (optional, decided at the end)

| Item | Status |
|---|---|
| Gate review: core running end to end, budget and time remaining | ⬜ |
| Document ingestion into Landing (PDF from CVM and BCB) | ⬜ |
| Parsing and chunking in Spark | ⬜ |
| Embeddings via Bedrock | ⬜ |
| pgvector store (separate database, isolated module) | ⬜ |
| Semantic search exposed as an output port | ⬜ |

## Concepts demonstrated

Apache Iceberg (MERGE, snapshots, schema evolution, maintenance) · medallion
layering (Landing/SOR/SOT/SPEC) · domain-oriented ownership · data products and
output ports · enforced data contracts (dbt) · ODCS · config-driven ingestion
framework · idempotent loads · restatement handling · EMR Serverless · Spark
Connect · dbt-spark · Glue Data Catalog · Lake Formation LF-Tags · row and
column level access control · Airflow dynamic task mapping · Terraform module
composition · S3 account regional namespace · OIDC deploys · multi-environment
promotion · OpenMetadata lineage and discovery · cost governance.

## Architecture

```
BCB API ─┐
         ├→ Landing (raw) → SOR (Iceberg) → SOT (dbt) → SPEC (output port)
CVM ZIP ─┘   Lambda/PySpark   MERGE          EMR Serverless + dbt-spark

Ingestion: serverless and lightweight (Lambda) — an HTTP fetch and an S3 write.
Processing: Spark on EMR Serverless — the distributed MERGE and dbt models.
Orchestration: Airflow on EC2, one EMR job run per table.
Catalog: Glue Data Catalog (technical) + OpenMetadata (discovery).
Access: Lake Formation LF-Tags — SPEC is the only cross-domain surface.
Delivery: Terraform, CLI during development, GitHub Actions from v9 onward.
```

## Design decisions

- Platform that enables a mesh, with domains instantiated on top — domain
  ownership is enforced technically, not organizationally (ADR-0001).
- Three environments in a single AWS account with logical isolation; real
  production would use account-per-environment (ADR-0002).
- EMR Serverless over Glue: no idle compute cost, full control of the Spark
  runtime, and an explicit goal of deepening EMR knowledge (ADR-0003).
- S3 account regional namespace: removes bucket squatting risk across the
  ephemeral destroy/recreate cycle (ADR-0004).
- Contracts enforced by dbt on SOT and SPEC; ODCS generated, never hand-written
  (ADR-0005).
- Airflow self-hosted on EC2 instead of MWAA, trading high availability for cost
  and setup speed (ADR-0006).
- Ingestion is serverless and light (Lambda); processing is Spark (EMR). Each
  workload runs on the engine that fits it, not on Spark by reflex.
- Git is the source of truth; SQL and table configs are deployed to S3 by the
  pipeline, never edited in place.
- Config declares data, never behavior: a new source means a new connector, not
  a new flag in YAML.
- The ingestion framework is generic only where it can be: connectors are typed
  per source, the SOR loader is fully generic, and dbt already is the framework
  for SOT and SPEC.
- Deployments run from the CLI during development; the pipeline takes over when
  all three environments are formalized.