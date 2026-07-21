# Slice 1 — scope and acceptance criteria

Domain `macro`, environment `dev`, Landing → SOR → SOT → SPEC, one BCB series
(daily SELIC), one dbt model per layer.

Goal: validate the hard integrations (Spark Connect, Iceberg + Glue, LF-Tags, OIDC)
before multiplying by two domains and three environments.

**Out of scope:** `fundos` domain, `hom` and `prod` environments, OpenMetadata, ODCS,
masking, RAG, 5-year backfill.

## Steps

| # | Deliverable | Acceptance criterion |
|---|---|---|
| 1 | Bootstrap: state bucket and lock | `terraform init` works against the remote backend |
| 2 | `network` + `security-baseline` | EMR job in a private subnet reaches S3 and Glue |
| 3 | `catalog` + `domain` (macro/dev) | buckets and databases created following the naming convention |
| 4 | `compute`: EMR Serverless application | a trivial `start-job-run` succeeds and writes logs to S3 |
| 5 | Landing job (BCB SGS → raw JSON) | re-running does not duplicate files |
| 6 | SOR job (JSON → Iceberg, MERGE) | two consecutive runs produce the same row count |
| 7 | dbt: source, SOT, and SPEC | `dbt build` passes; changing a type without updating YAML breaks the build |
| 8 | Airflow on EC2 + single DAG | Spark Connect session terminates on failure as well |
| 9 | Lake Formation: LF-Tags and grants | consumer role gets `AccessDeniedException` on SOT |

## Reference configuration

Iceberg + Glue on EMR Serverless:

```
spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions
spark.sql.catalog.macro=org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.macro.catalog-impl=org.apache.iceberg.aws.glue.GlueCatalog
spark.sql.catalog.macro.warehouse=s3://<bucket>/<prefix>/
spark.hadoop.hive.metastore.client.factory.class=com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory
```

dbt on EMR Serverless (requires `emr-7.13.0` or later):

```bash
pip install "dbt-spark[session]"
export SPARK_REMOTE="<interactive session endpoint>"
dbt build --target dev
```

## Risks

| Risk | Mitigation |
|---|---|
| Orphaned Spark Connect session burning credit | terminate in `on_failure` + AWS Budgets alarm |
| Debugging Spark Connect through Airflow logs | validate the command sequence via CLI first |
| Uncertain `bucket_namespace` behavior in the provider | pass the full name explicitly via `format()` |
