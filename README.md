# lupilot

**Lamar University IOS+** — Compliance Operating System (COS) deployment platform.

> **Transfer Note:** This repository is designed for transfer to Lamar University. All organization-specific values are parameterized via environment variables. See `environments/.env.template` and `docs/TRANSFER_GUIDE.md`.

## Overview

This repository contains the complete infrastructure-as-code, Kubernetes manifests, CI/CD pipelines, and deployment runbooks for the IOS+ Compliance Operating System.

## Architecture

- **Cloud:** Google Cloud Platform (parameterized region)
- **Orchestration:** GKE Autopilot (or on-prem Kubernetes)
- **Database:** Cloud SQL PostgreSQL 16 (or on-prem PostgreSQL HA)
- **Cache:** Memorystore Redis (or on-prem Redis)
- **Messaging:** Cloud Pub/Sub (or Kafka)
- **Storage:** Cloud Storage (GCS) (or S3-compatible)
- **Secrets:** Secret Manager + Workload Identity (or HashiCorp Vault)
- **CI/CD:** GitHub Actions + Cloud Deploy (or self-hosted runners)
- **Monitoring:** Cloud Monitoring + Cloud Logging + Grafana (or self-hosted Prometheus/Loki)

## Quick Start

```bash
# Clone repository
git clone https://github.com/${GITHUB_ORG}/lupilot.git
cd lupilot

# Set up GCP authentication (or configure for on-prem)
gcloud auth login
gcloud config set project ${GCP_PROJECT_ID}

# Deploy infrastructure (Terraform)
cd infra/terraform
terraform init
terraform workspace select production
terraform plan -var-file=environments/production.tfvars
terraform apply

# Deploy application (Cloud Deploy)
gcloud deploy releases create release-$(date +%Y%m%d) \
  --delivery-pipeline=${CLOUD_DEPLOY_PIPELINE} \
  --target=production \
  --source=k8s/overlays/production
```

## Documentation

| Document | Purpose |
|----------|---------|
| `docs/PRODUCTION_READINESS_AND_TRANSFER_PLAN.md` | Master 90-day production readiness plan |
| `docs/DEPLOYMENT_READINESS_MATRIX.md` | Component-by-component readiness tracker |
| `docs/TRANSFER_GUIDE.md` | How to transfer to Lamar GitHub org |
| `docs/ENVIRONMENT_BOOTSTRAP.md` | Bootstrap a new environment from scratch |
| `docs/OPERATIONS_HANDOFF.md` | Runbooks, incident response, on-call |
| `docs/SECURITY_MODEL.md` | Threat model, controls, compliance |
| `docs/BREAK_GLASS_RUNBOOK.md` | Emergency procedures |
| `docs/DEPLOYMENT_RUNBOOK.md` | Day-by-day deployment procedures |
| `docs/GITHUB_ACTIONS_SECRETS.md` | CI/CD secrets and configuration |
| `docs/Module3_AI_Governance_Framework.md` | NIST AI RMF governance framework |
| `docs/architecture/` | Architecture v2 narrative, deployment spec, diagram layout, repo mapping |

## Repository Structure

```
lupilot/
├── .github/workflows/      # GitHub Actions CI/CD
├── environments/            # Environment variable templates
├── infra/
│   ├── terraform/           # Terraform IaC (GCP)
│   └── gcp/                 # GCP architecture docs
├── k8s/
│   ├── base/                # Base K8s manifests
│   ├── overlays/            # Environment overlays (staging, production)
│   └── jobs/                # One-off jobs (Flyway migrations)
├── db/migrations/           # PostgreSQL Flyway migrations
├── docs/                    # Architecture docs, runbooks, guides
├── scripts/                 # Utility scripts (transfer-prep, seed-secrets)
├── clouddeploy.yaml         # Cloud Deploy pipeline
├── skaffold.yaml            # Skaffold build config
└── README.md                # This file
```

## Modules

| Module | Status | Description |
|--------|--------|-------------|
| Module 1 | ✅ Complete | Regulatory Reporting — 12 agency marts, 17 canonical definitions |
| Module 2 | ✅ Complete | Operational Intelligence — UC-01 through UC-08 |
| Module 3 | ✅ Complete | AI Governance — NIST AI RMF aligned |

## Security

- **Data residency configurable.** On-prem trust boundary supported.
- **All PII pseudonymized.** SYN IDs replace SSNs at ingestion.
- **Workload Identity.** No service account keys in Kubernetes.
- **Cloud Armor WAF.** SQL injection, XSS, and rate limiting protection.
- **CMEK encryption.** Customer-managed keys for all storage.
- **Trace chain.** Immutable blockchain audit trail for governance.

## License

Proprietary — See `docs/TRANSFER_GUIDE.md` for ownership terms.

## Contact

- **Primary Owner:** [Lamar University IT]
- **Engineering:** [ops@lamar.edu]
- **Emergency:** [emergency@lamar.edu]
- **Support:** [support@lamar.edu]
