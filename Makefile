.PHONY: help init fmt validate lint plan apply destroy dbt-deps dbt-build test clean

ENV ?= dev
STACK ?= platform
TF_DIR = infra/envs/$(ENV)

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

init: ## terraform init for the ENV environment
	terraform -chdir=$(TF_DIR) init

fmt: ## format all Terraform code
	terraform fmt -recursive infra bootstrap

validate: ## validate Terraform for the ENV environment
	terraform -chdir=$(TF_DIR) validate

lint: ## run pre-commit across all files
	pre-commit run --all-files

plan: ## terraform plan for the ENV environment
	terraform -chdir=$(TF_DIR) plan -out=tfplan

apply: ## apply the generated plan
	terraform -chdir=$(TF_DIR) apply tfplan

destroy: ## destroy the ENV environment
	terraform -chdir=$(TF_DIR) destroy

dbt-deps: ## install dbt packages
	cd dbt/macro && dbt deps

dbt-build: ## run dbt build (requires SPARK_REMOTE)
	@test -n "$$SPARK_REMOTE" || (echo "SPARK_REMOTE is not set" && exit 1)
	cd dbt/macro && dbt build --target $(ENV)

test: ## unit tests for PySpark jobs
	pytest jobs -v

clean: ## remove local artifacts
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	rm -rf dbt/macro/target dbt/macro/dbt_packages .pytest_cache .ruff_cache
