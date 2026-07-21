---
status: "accepted"
date: 2026-07-20
decision-makers: [Douglas]
---

# Create S3 buckets in the account regional namespace

## Context and Problem Statement

The infrastructure is ephemeral and goes through destroy and recreate cycles. In the S3
global namespace, the name of a deleted bucket becomes available to any account again.

## Decision Drivers

* Short, predictable names are easy targets for bucket squatting.
* IaC requires deterministic names, which rules out random suffixes.

## Considered Options

* Global namespace with an account ID suffix
* Global namespace with a random suffix (`random_id`)
* Account regional namespace (`-an` suffix)

## Decision Outcome

Chosen option: **account regional namespace**, following the
`prefix-<accountId>-<region>-an` format. It is a reserved subdivision of the global
namespace where only the owning account can create buckets; attempts from other accounts
are rejected. AWS classifies its use as a security best practice.

### Consequences

* Good, because it removes squatting risk across destroy and recreate cycles.
* Good, because names stay deterministic and the region is already part of the suffix.
* Bad, because it requires AWS provider >= 6.37.0 and the `bucket_namespace` argument.
* Bad, because the suffix consumes 26 of the 63 available characters.

### Confirmation

An IAM policy on the CI role denies `s3:CreateBucket` when the
`s3:x-amz-bucket-namespace` condition is not `account-regional`.

## More Information

Not available in the Middle East (Bahrain) and Middle East (UAE) regions.
