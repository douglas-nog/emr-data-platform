# Operations Runbook

Operational procedures for the EMR Data Platform. Sections are added as each
roadmap phase lands; this file covers what currently exists (v1 — Foundation).

---

## 1. Access

Two identities exist, with different purposes.

| Identity | Works on | Purpose |
|---|---|---|
| IAM Identity Center user | console + CLI | daily use |
| IAM user (admin group) | console only | break-glass fallback |

Neither has access keys. Long-lived credentials are not used in this project.

### 1.1 Console access

Open the AWS access portal, sign in, and pick the account and permission set:

```
https://d-906676744b.awsapps.com/start
```

This is the same identity used by the CLI. Do not sign in through the IAM user
for routine work.

### 1.2 CLI access

The profile is configured once:

```bash
aws configure sso --profile edp
```

| Prompt | Value |
|---|---|
| SSO session name | `edp` |
| SSO start URL | `https://d-906676744b.awsapps.com/start` |
| SSO region | `us-east-1` |
| SSO registration scopes | default |
| CLI default client Region | `us-east-1` |
| CLI default output format | `json` |
| CLI profile name | `edp` |

`export AWS_PROFILE=edp` is set in `~/.zshrc`, so every new shell uses it.

### 1.3 Starting a work session

Sessions last 8 hours. At the start of each working day:

```bash
aws sso login --profile edp
```

A browser window opens for device authorization. Confirm the code shown in the
terminal and approve.

Verify:

```bash
aws sts get-caller-identity
```

The `Arn` must contain `assumed-role/AWSReservedSSO_AdministratorAccess`. If it
contains `user/`, another profile is taking precedence — check `AWS_PROFILE`.

### 1.4 Expired session

Terraform and the CLI fail with credential errors when the session expires. The
fix is the same command:

```bash
aws sso login --profile edp
```

Nothing is reconfigured. The profile persists; only the session expires.

### 1.5 Programmatic credentials without access keys

If a tool cannot use SSO directly, export temporary credentials from the active
session instead of creating an access key:

```bash
aws configure export-credentials --profile edp --format env
```

These expire with the session. Never create an access key for either identity.

### 1.6 Break-glass

If Identity Center becomes unavailable, sign in to the console with the IAM user
and MFA. Use it only to restore Identity Center, then return to normal access.

---

## 2. Terraform state

State lives in `s3://edp-tfstate-464868388894-us-east-1-an`, with versioning
enabled and S3-native locking (no DynamoDB table).

### 2.1 Stale lock

If an apply is interrupted, a `.tflock` object may remain and block the next
run. Terraform reports the lock ID in the error.

```bash
terraform force-unlock <LOCK_ID>
```

Only do this after confirming no other apply is running.

### 2.2 Corrupted or lost state

Versioning is the recovery path. List versions of the state object:

```bash
aws s3api list-object-versions \
  --bucket edp-tfstate-464868388894-us-east-1-an \
  --prefix edp/bootstrap/terraform.tfstate
```

Download a known-good version and restore it:

```bash
aws s3api get-object \
  --bucket edp-tfstate-464868388894-us-east-1-an \
  --key edp/bootstrap/terraform.tfstate \
  --version-id <VERSION_ID> \
  restored.tfstate
```

Inspect it before pushing it back with `terraform state push`.

### 2.3 The state bucket must not be destroyed

`aws_s3_bucket.tfstate` carries `prevent_destroy = true`. Removing it requires
deleting that lifecycle block in a deliberate commit. Losing this bucket means
losing the mapping of every resource in the account.

---

## 3. Cost control

A monthly budget of 50 USD is configured, with email alerts at 50% actual,
90% actual, and 100% forecast.

### 3.1 When an alert arrives

Cost data lags by up to 24 hours, so the alert is a safety net, not real-time
detection.

1. Open Cost Explorer and group by service to find the source.
2. The usual suspects are compute left running and long-running jobs.
3. Tear down whatever is not in active use.

The budget notifies; it does not block. Nothing stops spend automatically.

### 3.2 Checking current spend

```bash
aws budgets describe-budget \
  --account-id 464868388894 \
  --budget-name edp-monthly
```

---

## 4. Development workflow

Deploys run from the CLI during development. The CI/CD pipeline takes over in
roadmap phase v9.

```bash
git checkout -b feature/<scope>   # branch off develop
terraform -chdir=infra/envs/dev plan
terraform -chdir=infra/envs/dev apply
```

Nothing is committed straight to `main`. The flow is
feature → develop → homolog → main.