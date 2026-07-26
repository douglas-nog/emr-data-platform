# Operations Runbook

Operational procedures for the EMR Data Platform. Sections are added as each
roadmap phase lands; this file covers what currently exists (v1 — Foundation).

---

## 1. Access

Access uses an IAM user that assumes an admin role with MFA. No Identity Center,
no Organization — that combination expires Free Tier credits.

| Component | Purpose |
|---|---|
| IAM user `douglas_eng` | holds the static access key; only assumes the role |
| Role `edp-admin-role` | admin permissions, requires MFA, 4-hour sessions |
| Profile `edp-base` | the user's static credentials, never used directly |
| Profile `edp` | assumes the role; this is the daily-use profile |

### 1.1 Starting a work session

```bash
aws sts get-caller-identity --profile edp
```

The first call each session prompts for the MFA code. The `Arn` must contain
`assumed-role/edp-admin-role`. Sessions last 4 hours; when they expire, the next
call prompts for MFA again.

`export AWS_PROFILE=edp` is set in `~/.zshrc`, so every new shell uses it.

### 1.2 Console access

Sign in with the `douglas_eng` IAM user and its MFA device.

### 1.3 Programmatic credentials

If a tool cannot assume the role directly, export temporary credentials from the
active session:

```bash
aws configure export-credentials --profile edp --format env
```

These expire with the session.

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