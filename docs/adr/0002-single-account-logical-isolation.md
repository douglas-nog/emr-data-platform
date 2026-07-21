---
status: "accepted"
date: 2026-07-20
decision-makers: [Douglas]
---

# Three environments in a single AWS account with logical isolation

## Context and Problem Statement

The project requires dev, hom, and prod. The industry pattern is one AWS account per
environment through AWS Organizations. Multiple accounts are not available.

## Decision Drivers

* Cost and credit constraints.
* Need to demonstrate controlled promotion across environments.

## Considered Options

* Single account with logical isolation (buckets, databases, roles, and LF-Tags per environment)
* Single account with `terraform workspace`
* Multi-account through AWS Organizations

## Decision Outcome

Chosen option: **logical isolation in a single account**, with Terraform state separated by
directory under `infra/envs/<env>`. `terraform workspace` was rejected because it hides the
environment separation from the repository structure.

### Consequences

* Good, because dev → hom → prod promotion and LF-Tag segmentation are preserved.
* Bad, because there is no blast radius isolation: a policy mistake can cross environments.
* Bad, because there is no per-environment quota or billing separation.

### Confirmation

The `dev` role receives `AccessDeniedException` when reading a `prod` bucket or database.

## More Information

Real production would use account-per-environment. The limitation is stated explicitly in
the README and in interviews, not glossed over.
