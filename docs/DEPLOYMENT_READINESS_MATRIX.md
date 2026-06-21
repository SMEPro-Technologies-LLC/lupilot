# Deployment Readiness Matrix

**Project:** SMEPro COS / Lamar IOS+  
**Version:** 1.0  
**Date:** 2026-06-21  

---

## How to Use This Matrix

Each row represents a deployable component. For each component, track:
- **Artifact Status:** Does the artifact exist? (Dockerfile, Helm chart, Terraform module)
- **Health/Readiness:** Does it have probes and SLOs?
- **Secrets:** Are all required secrets documented and injected?
- **Test Coverage:** Are there unit, integration, and smoke tests?
- **Observability:** Are logs, metrics, and traces implemented?
- **Owner:** Who is responsible?
- **Wave:** Which production wave does it belong to?
- **Status:** Red (not started), Yellow (in progress), Green (ready)

Update this file weekly. Do not deploy a component to production until all columns are Green.

---

## Wave 1 — Core Platform

| Component | Repo Path | Runtime | Dockerfile | Helm Chart | Secrets | Probes/SLOs | Tests | Logs/Metrics/Traces | Owner | Status |
|-----------|-----------|---------|------------|------------|---------|-------------|-------|---------------------|-------|--------|
| **PostgreSQL HA** | `db/migrations/` + Terraform | Cloud SQL / On-prem | N/A (managed) | N/A (managed) | `db-password`, `db-ssl-cert` | N/A (managed health) | Migration tests | Cloud SQL metrics / Postgres exporter | SMEPro | 🟡 |
| **Redis** | Terraform `google_redis_instance` | Memorystore / On-prem | N/A (managed) | N/A (managed) | `redis-password` | N/A (managed health) | Connectivity tests | Redis metrics / Cloud Monitoring | SMEPro | 🟡 |
| **API Gateway** | `services/api-gateway/` (spec) | Node.js / Go | ⬜ | ⬜ | `jwt-signing-key`, `idp-client-secret`, `tls-cert` | ⬜ | ⬜ | ⬜ | SMEPro | 🔴 |
| **UDM Query Service** | `services/udm-query/` (spec) | Node.js / Python | ⬜ | ⬜ | `db-password`, `redis-password` | ⬜ | ⬜ | ⬜ | SMEPro | 🔴 |
| **Evidence Chain Service** | `services/evidence-chain/` (spec) | Node.js / Go | ⬜ | ⬜ | `trace-chain-private-key`, `eth-node-url` | ⬜ | ⬜ | ⬜ | SMEPro | 🔴 |
| **Frontend App** | `frontend/ios-plus/` (spec) | React/Vue | ⬜ | ⬜ | `api-base-url`, `auth-client-id` | ⬜ | ⬜ | ⬜ | SMEPro | 🔴 |
| **Auth / RBAC** | `services/auth/` (spec) | Node.js / OAuth proxy | ⬜ | ⬜ | `idp-metadata-url`, `saml-cert`, `jwt-signing-key` | ⬜ | ⬜ | ⬜ | Joint | 🔴 |
| **Ingress Controller** | `k8s/base/ingress.yaml` | NGINX / GCE | N/A | ⬜ | `tls-cert`, `tls-key` | ⬜ | ⬜ | ⬜ | SMEPro | 🟡 |
| **Cert Manager** | `k8s/base/cert-manager.yaml` | cert-manager | N/A | ⬜ | `letsencrypt-issuer`, `dns-solver` | ⬜ | ⬜ | ⬜ | SMEPro | 🟡 |
| **External Secrets** | `k8s/base/external-secrets.yaml` | External Secrets Operator | N/A | ⬜ | `gcp-sa-key` (or Vault token) | ⬜ | ⬜ | ⬜ | SMEPro | 🟡 |
| **Flyway Migrations** | `db/migrations/` | Flyway job | N/A | ⬜ | `db-password`, `db-host` | N/A (job completion) | ⬜ | ⬜ | SMEPro | 🟡 |
| **Network Policies** | `k8s/base/network-policies.yaml` | Kubernetes | N/A | N/A | N/A | N/A | ⬜ | N/A | SMEPro | 🟡 |
| **Pod Security** | `k8s/base/pod-security.yaml` | Kubernetes | N/A | N/A | N/A | N/A | ⬜ | N/A | SMEPro | 🟡 |
| **Monitoring Stack** | `k8s/monitoring/` | Prometheus + Grafana + Loki | ⬜ | ⬜ | `grafana-admin-password`, `alertmanager-slack-webhook` | ⬜ | ⬜ | ⬜ | SMEPro | 🔴 |
| **Backup / Restore** | Terraform + scripts | Cloud SQL / Velero | N/A | N/A | `backup-sa-key`, `gcs-bucket` | N/A | Restore drill | Cloud Monitoring alerts | SMEPro | 🟡 |
| **CI Pipeline** | `.github/workflows/ci-gcp.yml` | GitHub Actions | N/A | N/A | `GITHUB_TOKEN`, `GCP_WORKLOAD_IDENTITY_PROVIDER` | N/A | ⬜ | N/A | SMEPro | 🟡 |
| **CD Pipeline** | `.github/workflows/cd-gcp.yml` | GitHub Actions + Cloud Deploy | N/A | N/A | `GCP_SERVICE_ACCOUNT`, `deploy-approval-token` | N/A | ⬜ | N/A | SMEPro | 🟡 |

### Wave 1 Summary
- **Red (not started):** 7 components
- **Yellow (in progress):** 10 components
- **Green (ready):** 0 components
- **Blocker:** No service Dockerfiles exist yet. The architecture is specified but not implemented.

---

## Wave 2 — Data Pipeline

| Component | Repo Path | Runtime | Dockerfile | Helm Chart | Secrets | Probes/SLOs | Tests | Logs/Metrics/Traces | Owner | Status |
|-----------|-----------|---------|------------|------------|---------|-------------|-------|---------------------|-------|--------|
| **Banner Connector** | `services/connectors/banner/` | Python | ⬜ | ⬜ | `banner-api-credentials`, `banner-api-url` | ⬜ | ⬜ | ⬜ | SMEPro | 🔴 |
| **Blackboard Connector** | `services/connectors/blackboard/` | Python | ⬜ | ⬜ | `blackboard-api-key`, `blackboard-api-url` | ⬜ | ⬜ | ⬜ | SMEPro | 🔴 |
| **CSV Upload Worker** | `services/connectors/csv/` | Python / Node.js | ⬜ | ⬜ | `upload-sa-key`, `gcs-bucket` | ⬜ | ⬜ | ⬜ | SMEPro | 🔴 |
| **Normalization Engine** | `services/normalization/` | Python / Node.js | ⬜ | ⬜ | `udm-mapping-config`, `validation-rules` | ⬜ | ⬜ | ⬜ | SMEPro | 🔴 |
| **Rules Engine** | `services/rules-engine/` | Java (Drools) / Node.js | ⬜ | ⬜ | `rules-git-repo`, `rules-branch` | ⬜ | ⬜ | ⬜ | SMEPro | 🔴 |
| **Workflow Orchestrator** | `services/workflow/` | Node.js / Temporal | ⬜ | ⬜ | `workflow-db-password`, `temporal-server-url` | ⬜ | ⬜ | ⬜ | SMEPro | 🔴 |
| **Approval Queue Service** | `services/approval-queue/` | Node.js | ⬜ | ⬜ | `email-smtp-password`, `slack-webhook-url` | ⬜ | ⬜ | ⬜ | SMEPro | 🔴 |
| **Pub/Sub Event Bus** | Terraform `google_pubsub_topic` | Cloud Pub/Sub | N/A | N/A | `pubsub-publisher-sa-key` | N/A | N/A | Cloud Monitoring | SMEPro | 🟡 |
| **Kafka / CDC** | `services/kafka/` (spec) | Kafka + Debezium | ⬜ | ⬜ | `kafka-sa-key`, `debezium-config` | ⬜ | ⬜ | ⬜ | SMEPro | 🔴 |
| **Elasticsearch / OpenSearch** | Terraform or on-prem | Search cluster | N/A | N/A | `elastic-password`, `tls-cert` | N/A | N/A | Cluster metrics | SMEPro | 🔴 |
| **Expanded Frontend** | `frontend/ios-plus-v2/` | React/Vue | ⬜ | ⬜ | `feature-flags`, `additional-api-endpoints` | ⬜ | ⬜ | ⬜ | SMEPro | 🔴 |

### Wave 2 Summary
- **Red (not started):** 10 components
- **Yellow (in progress):** 1 component (Pub/Sub Terraform exists)
- **Green (ready):** 0 components
- **Blocker:** No connector or engine services implemented.

---

## Wave 3 — Intelligence & Governance

| Component | Repo Path | Runtime | Dockerfile | Helm Chart | Secrets | Probes/SLOs | Tests | Logs/Metrics/Traces | Owner | Status |
|-----------|-----------|---------|------------|------------|---------|-------------|-------|---------------------|-------|--------|
| **ML Risk Scoring Job** | `services/ml/risk-scoring/` | Python (scikit-learn / XGBoost) | ⬜ | ⬜ | `ml-model-artifact-url`, `training-data-bucket` | ⬜ | ⬜ | ⬜ | SMEPro | 🔴 |
| **Anomaly Detection Job** | `services/ml/anomaly/` | Python (PyOD / Isolation Forest) | ⬜ | ⬜ | `ml-model-artifact-url`, `anomaly-threshold-config` | ⬜ | ⬜ | ⬜ | SMEPro | 🔴 |
| **Cohort Analysis Job** | `services/ml/cohort/` | Python (pandas / SQL) | ⬜ | ⬜ | `db-password`, `analysis-output-bucket` | ⬜ | ⬜ | ⬜ | SMEPro | 🔴 |
| **Explainability Service** | `services/ml/explain/` | Python (SHAP / LIME) | ⬜ | ⬜ | `ml-model-artifact-url`, `explanation-cache-redis` | ⬜ | ⬜ | ⬜ | SMEPro | 🔴 |
| **Trace Chain / Blockchain** | `services/trace-chain/` | Node.js / Go + Ethereum | ⬜ | ⬜ | `eth-node-url`, `smart-contract-address`, `trace-chain-private-key` | ⬜ | ⬜ | ⬜ | SMEPro | 🔴 |
| **Governance Automation** | `services/governance/` | Node.js / Python | ⬜ | ⬜ | `approval-escalation-rules`, `notification-channels` | ⬜ | ⬜ | ⬜ | SMEPro | 🔴 |
| **Compliance Automation** | `services/compliance/` | Node.js / Python | ⬜ | ⬜ | `ferpa-audit-config`, `retention-policy-config` | ⬜ | ⬜ | ⬜ | SMEPro | 🔴 |
| **MLflow / Model Registry** | `services/ml/mlflow/` | MLflow | ⬜ | ⬜ | `mlflow-db-password`, `artifact-store-bucket` | ⬜ | ⬜ | ⬜ | SMEPro | 🔴 |
| **Airflow / Pipeline Orchestrator** | `services/airflow/` | Apache Airflow | ⬜ | ⬜ | `airflow-db-password`, `git-sync-repo` | ⬜ | ⬜ | ⬜ | SMEPro | 🔴 |
| **Spark / Data Processing** | `services/spark/` | Apache Spark | ⬜ | ⬜ | `spark-sa-key`, `dataproc-cluster` | ⬜ | ⬜ | ⬜ | SMEPro | 🔴 |

### Wave 3 Summary
- **Red (not started):** 10 components
- **Yellow (in progress):** 0 components
- **Green (ready):** 0 components
- **Blocker:** All ML and governance services are specification-only.

---

## Infrastructure Components (Cross-Cutting)

| Component | Repo Path | Status | Owner | Notes |
|-----------|-----------|--------|-------|-------|
| **VPC / Network** | `infra/terraform/network.tf` | 🟡 | SMEPro | Terraform exists; needs Lamar-specific CIDR ranges |
| **GKE Cluster** | `infra/terraform/gke.tf` | 🟡 | SMEPro | Terraform exists; needs on-prem alternative if required |
| **Cloud SQL PostgreSQL** | `infra/terraform/cloudsql.tf` | 🟡 | SMEPro | Terraform exists; needs HA and backup config |
| **Memorystore Redis** | `infra/terraform/redis.tf` | 🟡 | SMEPro | Terraform exists; needs on-prem alternative |
| **Cloud Storage Buckets** | `infra/terraform/storage.tf` | 🟡 | SMEPro | Terraform exists; needs CMEK key rotation |
| **Cloud Pub/Sub** | `infra/terraform/pubsub.tf` | 🟡 | SMEPro | Terraform exists; needs IAM fine-tuning |
| **Secret Manager** | `infra/terraform/secrets.tf` | 🟡 | SMEPro | Terraform exists; needs secret seeding scripts |
| **Cloud KMS** | `infra/terraform/kms.tf` | 🟡 | SMEPro | Terraform exists; needs key rotation policy |
| **Cloud Armor WAF** | `infra/terraform/cloudarmor.tf` | 🟡 | SMEPro | Terraform exists; needs Lamar-specific rules |
| **Cloud DNS** | `infra/terraform/dns.tf` | 🟡 | SMEPro | Terraform exists; needs Lamar domain delegation |
| **IAM / Service Accounts** | `infra/terraform/iam.tf` | 🟡 | SMEPro | Terraform exists; needs Lamar-specific roles |
| **Workload Identity** | `infra/terraform/workload-identity.tf` | 🟡 | SMEPro | Terraform exists; needs GitHub OIDC linkage |
| **Cloud Deploy Pipeline** | `clouddeploy.yaml` | 🟡 | SMEPro | Exists; needs Cloud Deploy agent setup |
| **Skaffold Config** | `skaffold.yaml` | 🟡 | SMEPro | Exists; needs image digests for immutable deploys |
| **Terraform State Backend** | `infra/terraform/main.tf` | 🟡 | SMEPro | GCS backend; needs bucket creation and versioning |
| **Kustomize Overlays** | `k8s/overlays/` | 🟡 | SMEPro | Staging + production overlays exist; needs Helm migration |
| **K8s Network Policies** | `k8s/base/network-policies.yaml` | 🟡 | SMEPro | Default deny + allow rules exist; needs testing |
| **K8s Pod Security** | `k8s/base/pod-security.yaml` | 🟡 | SMEPro | Security contexts exist; needs enforcement |
| **K8s Resource Quotas** | `k8s/base/resource-quotas.yaml` | ⬜ | SMEPro | Not yet created |
| **K8s HPA** | `k8s/base/hpa.yaml` | ⬜ | SMEPro | Not yet created |
| **K8s PDB** | `k8s/base/pdb.yaml` | ⬜ | SMEPro | Not yet created |
| **Disaster Recovery Plan** | `docs/DR_PLAN.md` | ⬜ | SMEPro | Not yet created |
| **Cost Monitoring** | `infra/terraform/budgets.tf` | ⬜ | SMEPro | Not yet created |

---

## Recommended Wave 1 MVP (Minimum Viable Production)

Given the red/yellow status, the **smallest deployable unit** that delivers value is:

1. **PostgreSQL + Redis** (managed or on-prem)
2. **API Gateway** (basic routing + auth)
3. **UDM Query Service** (read-only data access)
4. **One Frontend** (login + basic dashboard)
5. **Auth/RBAC** (SAML/OIDC login + role routing)
6. **Ingress + TLS + DNS**
7. **Monitoring** (health + basic logs)
8. **Backup/Restore** (daily + tested restore)

**This is 8 components, not 30.** Prove this works end-to-end before adding anything else.

---

*Update this matrix weekly. Do not mark a component Green until it has been deployed to staging and passed a smoke test.*
