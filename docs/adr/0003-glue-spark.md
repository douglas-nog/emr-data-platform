---
status: "accepted"
date: 2026-10-20
decision-makers: [Douglas]
---

# AWS Glue as the Spark execution engine

## Context and Problem Statement

The platform needs a Spark engine for two workloads: the generic SOR loader
(typing raw Landing data and running `MERGE INTO` on Iceberg tables) and the dbt
transformations that build the SOT and SPEC layers. Ingestion is already
serverless and light (Lambda); this decision concerns only the distributed
processing engine.

## Decision Drivers

* Cost is a hard constraint, so idle compute is unacceptable — the engine must
  bill only while work runs.
* Native Apache Iceberg support, to avoid assembling the runtime and its JARs by
  hand.
* Fine-grained access control through Lake Formation, to enforce the domain
  boundary at the data-access layer.
* Minimal operational surface: no cluster to size, patch, or keep alive.

## Considered Options

* AWS Glue 5.0
* Self-managed Spark on EC2
* Amazon Athena (SQL only)

## Decision Outcome

Chosen option: **AWS Glue 5.0**.

Self-managed Spark on EC2 was rejected for its idle cost and the burden of
operating the cluster. Athena was rejected because the config-driven SOR loader
needs programmatic control over the Spark session and job flow that a SQL-only
engine does not provide.

Glue 5.0 satisfies every driver: it is serverless and billed per job-second, so
nothing is provisioned between runs; it ships Spark 3.5.4 with Apache Iceberg
1.7.1 natively, so the Iceberg runtime needs no manual JARs; and it supports
Spark-native fine-grained access control through Lake Formation. Glue 5.1 was
not chosen because it writes Iceberg format version 3, which Athena cannot read;
the project pins Glue 5.0.

### Consequences

* Good, because there is no standing compute cost: a job is billed only while it
  runs, and nothing idles between runs.
* Good, because Iceberg is native — no runtime assembly, and each snapshot
  records the engine version.
* Good, because Lake Formation FGAC works with Glue, enforcing the same domain
  boundary at query time that the IAM policies enforce at the storage layer.
* Neutral, because each job pays a cold start of roughly 30–60 seconds, which is
  acceptable for a batch pipeline with no latency requirement.
* Constraint: the SOR loader and dbt models run as plain Spark DataFrames
  (`SparkSession` plus Iceberg SQL), never `GlueContext` or DynamicFrames. Lake
  Formation FGAC on open table formats requires DataFrames, and keeping the
  processing code free of Glue-specific libraries keeps it clean, standard Spark
  that is straightforward to test.

### Confirmation

A trivial Glue job reads and writes an Iceberg table and appears in the job run
history. The SOR loader proves idempotency: two consecutive runs leave the same
row count. dbt builds the SOT and SPEC models through the dbt-glue adapter.

## More Information

The `platform` module holds no central compute resource. Glue jobs are
per-domain resources, created in the domain layer alongside that domain's data
and execution role, consistent with the domain-oriented design in ADR-0001.
