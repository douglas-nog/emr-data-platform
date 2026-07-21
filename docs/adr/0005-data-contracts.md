---
status: "accepted"
date: 2026-07-20
decision-makers: [Douglas]
---

# dbt-enforced data contracts on SOT and SPEC, with derived ODCS

## Context and Problem Statement

Domains consume each other's data. A contract mechanism is needed that breaks the build on
an incompatible change, not just documentation.

## Decision Drivers

* Contracts must be executable, not declarative.
* Consumers must discover the contract before coupling to it.

## Considered Options

* dbt model contracts with `enforced: true`
* Hand-maintained ODCS
* dbt tests only, no contract

## Decision Outcome

**dbt model contracts** are the source of truth, with `enforced: true` on SOT and SPEC.
The ODCS YAML is generated in CI from `manifest.json` and treated as a derived artifact,
never hand-edited.

### Consequences

* Good, because a schema violation stops the model from running.
* Bad, because every column must declare `data_type`; mitigated with `dbt-codegen`.
* Bad, because on Spark, constraints such as `primary_key` and `unique` are documentation
  only: uniqueness and integrity are covered by `dbt test`, not by the contract.

### Confirmation

Changing a column type in SQL without updating the YAML breaks `dbt build`.
A CI gate compares the PR manifest against the production manifest and fails on an
incompatible change to a `public` model without a version bump.

## More Information

A contract defines **shape**; quality and availability are SLA, covered by `dbt test` and
`source freshness`. If the ODCS generator proves expensive, the fallback is to drop ODCS —
never to maintain it by hand in parallel.
