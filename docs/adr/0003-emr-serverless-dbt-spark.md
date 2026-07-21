---
status: "accepted"
date: 2026-07-20
decision-makers: [Douglas]
---

# EMR Serverless with dbt-spark over Spark Connect as the transformation engine

## Context and Problem Statement

Processing must run on Spark, be serverless (no idle cluster), and integrate with dbt.

## Decision Drivers

* No idle compute cost, given the ephemeral infrastructure model.
* Explicit goal of deepening hands-on EMR knowledge.
* Need for control over the Spark version and runtime configuration.

## Considered Options

* EMR Serverless + `dbt-spark[session]` over Spark Connect
* AWS Glue + `dbt-glue`
* Athena + `dbt-athena`
* EMR on EC2

## Decision Outcome

Chosen option: **EMR Serverless with `dbt-spark[session]`**, available from release
`emr-7.13.0` with Spark Connect enabled interactive sessions. In `profiles.yml`,
`method: session` and `host: NA`; `SPARK_REMOTE` points to the session endpoint.

### Consequences

* Good, because there is no compute cost when no job is running.
* Good, because it gives fine-grained control over Spark runtime and configuration.
* Bad, because the interactive session lifecycle becomes an orchestration responsibility:
  open, run, terminate — including on failure.
* Bad, because an orphaned session silently burns credit.

### Confirmation

The Airflow task terminates the session in `on_failure`, verified by an induced failure
test. AWS Budgets alarm acts as the safety net.

## More Information

Athena was rejected because it is not a batch processing engine.
`dbt-glue` was rejected because it reduces runtime control and does not serve the EMR
learning goal.
