---
status: "accepted"
date: 2026-07-20
decision-makers: [Douglas]
---

# Self-hosted Airflow on EC2 instead of MWAA

## Context and Problem Statement

Orchestration must run on Airflow. MWAA bills the environment hourly in an always-on model
and takes tens of minutes to provision, which conflicts with ephemeral infrastructure.

## Considered Options

* MWAA
* Airflow on EC2 through Docker Compose
* Airflow on ECS/EKS

## Decision Outcome

Chosen option: **Airflow on EC2**, with metadata in Postgres and deployment through
Docker Compose.

### Consequences

* Good, because cost drops and the setup/teardown cycle is fast.
* Good, because it exposes real Airflow operations (executor, backend, scheduler).
* Bad, because a single instance is a single point of failure, with no high availability.

### Confirmation

Restarting the instance restores DAGs and history from the metadata backend.

## More Information

Real production would use MWAA or ECS/EKS. The limitation is stated, not glossed over.
The Airflow bundled with OpenMetadata stays separate: its scope is metadata ingestion.
