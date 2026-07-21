---
status: "accepted"
date: 2026-07-20
decision-makers: [Douglas]
---

# Position the project as a domain-oriented platform

## Context and Problem Statement

The project organizes data by domain, with output ports and federated governance — data
mesh vocabulary. However, there is a single owner and no organizational boundary between
domains. Can the project be labelled a data mesh?

## Decision Drivers

* Data mesh rests on four principles, the first being domain ownership, which is
  organizational and cannot be demonstrated with a single owner.
* The project is a portfolio artifact: claims must survive technical scrutiny.

## Considered Options

* Label it a data mesh
* Label it a domain-oriented, self-service data platform
* Label it a lakehouse

## Decision Outcome

Chosen option: **domain-oriented, self-service data platform**. Data-as-a-product,
self-service infrastructure, and computational federated governance are implemented.
Domain ownership is enforced technically (distinct roles and LF-Tags), not
organizationally.

### Consequences

* Good, because the claim is verifiable and holds up under questioning.
* Good, because "lakehouse" alone would undersell the governance and per-domain modularity.
* Bad, because it gives up the "data mesh" keyword, which carries more search appeal.

### Confirmation

Two domains instantiated from the same Terraform module, with distinct roles and effective
denial of cross-domain access to internal layers.
