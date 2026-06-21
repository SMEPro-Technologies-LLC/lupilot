# lupilot

**Lamar University Pilot** — SMEPro Compliance Operating System (COS) deployment on Google Cloud Platform.

## Overview

This repository contains the complete infrastructure-as-code, Kubernetes manifests, CI/CD pipelines, and deployment runbooks for the SMEPro COS at Lamar University.

## Architecture

- **Cloud:** Google Cloud Platform (us-central1)
- **Orchestration:** GKE Autopilot
- **Database:** Cloud SQL PostgreSQL 16
- **Cache:** Memorystore Redis
- **Messaging:** Cloud Pub/Sub
- **Storage:** Cloud Storage (GCS)
- **Secrets:** Secret Manager + Workload Identity
- **CI/CD:** GitHub Actions + Cloud Deploy
- **Monitoring:** Cloud Monitoring + Cloud Logging + Grafana

## Quick Start

```bash
# Clone repository
git clone https://github.com/SMEPro-Technologies-LLC/lupilot.git
cd lupilot

# Set up GCP authentication
gcloud auth login
gcloud config set project smepro-cos-prod

# Deploy infrastructure (Terraform)
cd infra/terraform
terraform init
terraform workspace select production
terraform plan -var-file=environments/production.tfvars
terraform apply

# Deploy application (Cloud Deploy)
gcloud deploy releases create release-$(date +%Y%m%d) \
  --delivery-pipeline=smepro-cos-pipeline \
  --target=production \
  --source=k8s/overlays/production
```

## Documentation

| Document | Purpose |
|----------|---------|
| `docs/architecture/` | Architecture v2 narrative, deployment spec, diagram layout, repo mapping |
| `docs/DEPLOYMENT_RUNBOOK.md` | Day-by-day deployment procedures |
| `docs/GITHUB_ACTIONS_SECRETS.md` | GitHub Actions secrets setup guide |
| `docs/Module3_AI_Governance_Framework.md` | NIST AI RMF governance framework |
| `docs/SMEPro_COS_Master_Delivery_Summary_2026-06-20.md` | Complete delivery summary |
| `docs/SMEPro_COS_Meeting_Review_2026-06-20.md` | Board-ready meeting review |

## Repository Structure

```
lupilot/
├── .github/workflows/      # GitHub Actions CI/CD
├── infra/
│   ├── terraform/           # Terraform IaC (GCP)
│   └── gcp/                 # GCP architecture docs
├── k8s/
│   ├── base/                # Base K8s manifests
│   ├── overlays/            # Environment overlays (staging, production)
│   └── jobs/                # One-off jobs (Flyway migrations)
├── db/migrations/           # PostgreSQL Flyway migrations
├── docs/                    # Architecture docs, runbooks, guides
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

- **Data never leaves campus.** GKE cluster runs in Lamar-controlled VPC.
- **All PII pseudonymized.** SYN IDs replace SSNs at ingestion.
- **Workload Identity.** No service account keys in GKE.
- **Cloud Armor WAF.** SQL injection, XSS, and rate limiting protection.
- **CMEK encryption.** Customer-managed keys for all storage.
- **Trace chain.** Immutable blockchain audit trail for governance.

## License

Proprietary — SMEPro Technologies, LLC. All rights reserved.

## Contact

- **Engineering:** devops@smepro.com
- **Emergency:** emergency@smepro.com
- **Support:** support@smepro.com
