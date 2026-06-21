# SMEPro COS — GCP Deployment Runbook
## Kickoff Build: Day 1 to Production
## Version: 2026.06.20-LAMAR-GCP-1.0
## Date: 2026-06-20

---

## 1. Prerequisites

Before running this runbook, ensure you have:

| Tool | Version | Purpose |
|------|---------|---------|
| `gcloud` CLI | >= 440.0.0 | GCP resource management |
| `terraform` | >= 1.7.0 | Infrastructure as Code |
| `kubectl` | >= 1.28.0 | Kubernetes cluster management |
| `docker` | >= 24.0.0 | Container builds |
| `kustomize` | >= 5.0.0 | Kubernetes manifest management |
| `skaffold` | >= 2.7.0 | Build and deploy orchestration |
| `git` | >= 2.40.0 | Version control |
| `gh` CLI | >= 2.30.0 | GitHub operations |
| `node` | >= 20.0.0 | Backend/frontend runtime |
| `python` | >= 3.11.0 | ML jobs and connectors |

---

## 2. Day 1: GCP Project Setup (30 minutes)

### 2.1 Create GCP Projects

```bash
# Set your billing account ID (from GCP Console)
BILLING_ACCOUNT="XXXXXX-XXXXXX-XXXXXX"

# Create projects
gcloud projects create smepro-cos-shared --name="SMEPro COS Shared"
gcloud projects create smepro-cos-dev --name="SMEPro COS Development"
gcloud projects create smepro-cos-staging --name="SMEPro COS Staging"
gcloud projects create smepro-cos-prod --name="SMEPro COS Production"

# Link billing accounts
gcloud billing projects link smepro-cos-shared --billing-account=$BILLING_ACCOUNT
gcloud billing projects link smepro-cos-dev --billing-account=$BILLING_ACCOUNT
gcloud billing projects link smepro-cos-staging --billing-account=$BILLING_ACCOUNT
gcloud billing projects link smepro-cos-prod --billing-account=$BILLING_ACCOUNT

# Set default project for operations
gcloud config set project smepro-cos-prod
```

### 2.2 Enable APIs (5 minutes per project)

```bash
for project in smepro-cos-shared smepro-cos-dev smepro-cos-staging smepro-cos-prod; do
  gcloud services enable compute.googleapis.com --project=$project
  gcloud services enable container.googleapis.com --project=$project
  gcloud services enable sqladmin.googleapis.com --project=$project
  gcloud services enable redis.googleapis.com --project=$project
  gcloud services enable pubsub.googleapis.com --project=$project
  gcloud services enable storage.googleapis.com --project=$project
  gcloud services enable secretmanager.googleapis.com --project=$project
  gcloud services enable clouddeploy.googleapis.com --project=$project
  gcloud services enable cloudbuild.googleapis.com --project=$project
  gcloud services enable artifactregistry.googleapis.com --project=$project
  gcloud services enable monitoring.googleapis.com --project=$project
  gcloud services enable logging.googleapis.com --project=$project
  gcloud services enable cloudtrace.googleapis.com --project=$project
  gcloud services enable aiplatform.googleapis.com --project=$project
  gcloud services enable securitycenter.googleapis.com --project=$project
  gcloud services enable cloudkms.googleapis.com --project=$project
  gcloud services enable cloudasset.googleapis.com --project=$project
  gcloud services enable iap.googleapis.com --project=$project
  gcloud services enable dns.googleapis.com --project=$project
  gcloud services enable certificatemanager.googleapis.com --project=$project
done
```

### 2.3 Create Terraform State Bucket (in shared project)

```bash
gcloud config set project smepro-cos-shared

# Create the Terraform state bucket
gcloud storage buckets create gs://smepro-cos-tfstate \
  --location=us-central1 \
  --uniform-bucket-level-access

# Enable versioning for state recovery
gcloud storage buckets update gs://smepro-cos-tfstate \
  --versioning
```

---

## 3. Day 1: Infrastructure Deployment (Terraform)

### 3.1 Initialize Terraform

```bash
cd infra/terraform

# Initialize with remote state backend
terraform init
```

### 3.2 Deploy Staging Environment

```bash
# Select staging workspace
terraform workspace select staging || terraform workspace new staging

# Plan
terraform plan -var-file=environments/staging.tfvars -out=tfplan-staging

# Review the plan (check for correctness)
terraform show tfplan-staging

# Apply (this takes 15–30 minutes)
terraform apply tfplan-staging
```

**What gets created:** VPC, GKE Autopilot cluster, Cloud SQL PostgreSQL, Memorystore Redis, Cloud Pub/Sub topics, Cloud Storage buckets, Secret Manager, KMS, IAM service accounts, Load Balancer IP.

### 3.3 Deploy Production Environment

```bash
# Select production workspace
terraform workspace select production || terraform workspace new production

# Plan
terraform plan -var-file=environments/production.tfvars -out=tfplan-production

# Apply (requires explicit approval)
terraform apply tfplan-production
```

---

## 4. Day 1: Secret Seeding (10 minutes)

### 4.1 Generate Strong Passwords

```bash
# Generate database password
DB_PASSWORD=$(openssl rand -base64 32)
echo "Database password: $DB_PASSWORD"

# Generate JWT signing key (RSA 2048)
openssl genrsa -out jwt-key.pem 2048
openssl rsa -in jwt-key.pem -pubout -out jwt-pub.pem
```

### 4.2 Store Secrets in Secret Manager

```bash
# Set project
export GCP_PROJECT=smepro-cos-prod

# Database password
echo -n "$DB_PASSWORD" | gcloud secrets create db-password-production \
  --data-file=- --project=$GCP_PROJECT

# JWT signing key (private)
gcloud secrets create jwt-signing-key-production \
  --data-file=jwt-key.pem --project=$GCP_PROJECT

# Store API credentials (obtain these from Lamar IT)
# Banner
gcloud secrets create banner-api-credentials-production \
  --data-file=./secrets/banner-credentials.json --project=$GCP_PROJECT

# Blackboard
gcloud secrets create blackboard-api-key-production \
  --data-file=./secrets/blackboard-key.txt --project=$GCP_PROJECT

# Anthropic (AVA + Claude)
gcloud secrets create anthropic-api-key-production \
  --data-file=./secrets/anthropic-key.txt --project=$GCP_PROJECT

# Firecrawl
gcloud secrets create firecrawl-api-key-production \
  --data-file=./secrets/firecrawl-key.txt --project=$GCP_PROJECT

# SendGrid (email notifications)
gcloud secrets create sendgrid-api-key-production \
  --data-file=./secrets/sendgrid-key.txt --project=$GCP_PROJECT

# Slack webhook
gcloud secrets create slack-webhook-url-production \
  --data-file=./secrets/slack-webhook.txt --project=$GCP_PROJECT

# Trace chain private key (Ethereum wallet)
gcloud secrets create trace-chain-private-key-production \
  --data-file=./secrets/trace-chain-key.txt --project=$GCP_PROJECT

# Clean up local files
rm jwt-key.pem jwt-pub.pem
echo "Secrets stored. Verify in GCP Console > Security > Secret Manager."
```

---

## 5. Day 2: GKE Cluster Access & Namespaces

### 5.1 Authenticate to GKE

```bash
# Get cluster credentials
gcloud container clusters get-credentials smepro-cos-gke \
  --region=us-central1 \
  --project=smepro-cos-prod

# Verify connection
kubectl cluster-info
kubectl get nodes
```

### 5.2 Create Namespaces

```bash
kubectl apply -f k8s/base/namespace.yaml

# Verify
kubectl get namespaces
```

### 5.3 Create Service Accounts (Workload Identity)

```bash
# Create Kubernetes service accounts and bind to GCP service accounts
kubectl apply -f k8s/base/api-gateway.yaml  # Includes ServiceAccount
kubectl apply -f k8s/base/cloudsql-proxy.yaml  # Includes ServiceAccount

# Verify Workload Identity binding
kubectl annotate serviceaccount k8s-api-gateway \
  iam.gke.io/gcp-service-account=sa-api-gateway@smepro-cos-prod.iam.gserviceaccount.com \
  -n api-gateway

kubectl annotate serviceaccount k8s-cloudsql-proxy \
  iam.gke.io/gcp-service-account=sa-cloudsql@smepro-cos-prod.iam.gserviceaccount.com \
  -n trust-model
```

---

## 6. Day 2: Database Migration (Flyway)

### 6.1 Run Migrations

```bash
# Create migration job
kubectl apply -f k8s/jobs/flyway-migrate.yaml -n trust-model

# Wait for completion
kubectl wait --for=condition=complete job/flyway-migrate -n trust-model --timeout=300s

# Check logs
kubectl logs job/flyway-migrate -n trust-model
```

### 6.2 Verify Database Schema

```bash
# Connect to Cloud SQL via proxy
kubectl exec -it deployment/cloudsql-proxy -n trust-model -- psql -h 127.0.0.1 -U smepro -d smepro

# List schemas
\dn

# List tables in module3_ai_governance
\dt module3_ai_governance.*

# Verify seed data
SELECT COUNT(*) FROM module3_ai_governance.ai_system_inventory;
-- Expected: 9
```

---

## 7. Day 3: Application Deployment (Cloud Deploy)

### 7.1 Build Docker Images

```bash
# Set environment
export ENV=staging
export IMAGE_TAG=$(git describe --tags --always)

# Build via Cloud Build (or locally)
gcloud builds submit --config cloudbuild.yaml \
  --substitutions=_IMAGE_TAG=$IMAGE_TAG,_ENV=$ENV

# Or build locally and push
docker build -t $ARTIFACT_REGISTRY/api-gateway:$IMAGE_TAG backend/api-gateway/
docker push $ARTIFACT_REGISTRY/api-gateway:$IMAGE_TAG
```

### 7.2 Deploy via Cloud Deploy

```bash
# Create release
gcloud deploy releases create release-001 \
  --delivery-pipeline=smepro-cos-pipeline \
  --target=staging \
  --source=k8s/overlays/staging \
  --images=api-gateway=$ARTIFACT_REGISTRY/api-gateway:$IMAGE_TAG

# Watch rollout
gcloud deploy rollouts list --release=release-001 \
  --delivery-pipeline=smepro-cos-pipeline \
  --target=staging

# Verify pods
kubectl get pods -n smepro-staging
kubectl get svc -n smepro-staging
```

### 7.3 Verify Deployment

```bash
# Health check via Load Balancer IP
export LB_IP=$(gcloud compute addresses list --format="value(address)")
curl -s https://$LB_IP/v1/health/ready

# Expected: {"status":"ready","timestamp":"..."}
```

---

## 8. Day 4: DNS & SSL Configuration

### 8.1 Create SSL Certificate (Google-managed)

```bash
# Create managed certificate
gcloud certificate-manager certificates create smepro-cos-cert \
  --domains="smepro-cos.lamar.edu,app.smepro-cos.lamar.edu" \
  --project=smepro-cos-prod

# Map to load balancer
gcloud certificate-manager maps create smepro-cos-map \
  --project=smepro-cos-prod

gcloud certificate-manager maps entries create smepro-cos-entry \
  --map=smepro-cos-map \
  --hostname=smepro-cos.lamar.edu \
  --certificate=smepro-cos-cert \
  --project=smepro-cos-prod
```

### 8.2 DNS A Record

Create an A record in Lamar's DNS (or Google Cloud DNS) pointing:
- `smepro-cos.lamar.edu` → Load Balancer IP
- `app.smepro-cos.lamar.edu` → Load Balancer IP

```bash
# Verify DNS resolution
dig +short smepro-cos.lamar.edu
# Should return the LB IP
```

---

## 9. Day 5: Monitoring & Alerting Setup

### 9.1 Create Monitoring Dashboard

```bash
# Apply Grafana dashboards
kubectl apply -f monitoring/grafana-dashboards.yaml -n monitoring

# Access Grafana
kubectl port-forward svc/grafana 3000:3000 -n monitoring
# Open http://localhost:3000 (admin/admin)
```

### 9.2 Create Alerting Policies

```bash
# Apply alert policies
kubectl apply -f monitoring/alert-policies.yaml -n monitoring

# Or use gcloud CLI
gcloud alpha monitoring policies create --policy-from-file="monitoring/alert-policies.json"
```

### 9.3 Configure Notification Channels

```bash
# Slack channel
gcloud monitoring channels create \
  --channel-labels=auth_token=$SLACK_TOKEN,channel_name=#smepro-ops \
  --type=slack \
  --display-name="SMEPro Ops Slack"

# Email channel
gcloud monitoring channels create \
  --channel-labels=email_address=ops@lamar.edu \
  --type=email \
  --display-name="SMEPro Ops Email"
```

---

## 10. Day 6: UAT & Smoke Testing

### 10.1 Run Smoke Tests

```bash
# API health
curl -s https://smepro-cos.lamar.edu/v1/health/ready | jq .

# Database connectivity
curl -s https://smepro-cos.lamar.edu/v1/health/db | jq .

# Persistence model (UC-01)
curl -s https://smepro-cos.lamar.edu/v1/module2/persistence/students?limit=5 | jq .

# Governance dashboard (Module 3)
curl -s https://smepro-cos.lamar.edu/v1/module3/governance/risk-summary | jq .
```

### 10.2 Run E2E Tests

```bash
# Install Cypress dependencies
cd tests/e2e
cd cypress && npm ci

# Run tests against staging
npx cypress run --env baseUrl=https://smepro-cos.lamar.edu
```

### 10.3 Performance Testing

```bash
# k6 load test
cd tests/load/k6
k6 run api-load.js --env BASE_URL=https://smepro-cos.lamar.edu
```

---

## 11. Day 7: Go-Live Checklist

### 11.1 Pre-Go-Live Verification

| Check | Command | Expected |
|-------|---------|----------|
| All pods running | `kubectl get pods -A` | All Ready |
| Services healthy | `kubectl get svc -A` | All ClusterIP/LoadBalancer |
| Ingress responding | `curl -s https://smepro-cos.lamar.edu/v1/health/ready` | `{"status":"ready"}` |
| Database migrated | `kubectl logs job/flyway-migrate` | `Successfully applied` |
| Secrets loaded | `kubectl get secrets -A` | No errors in pod logs |
| Cloud Armor active | `gcloud compute security-policies list` | `smepro-cos-waf` listed |
| SSL certificate valid | `openssl s_client -connect smepro-cos.lamar.edu:443` | `Verify return code: 0` |
| Monitoring dashboards | Open Grafana | All dashboards populated |
| Alerting channels | Trigger test alert | Slack/email received |
| Backup configured | `gcloud sql backups list` | Daily backups listed |
| Log sinks active | `gcloud logging sinks list` | All sinks listed |

### 11.2 Go-Live Approval

Before promoting to production, obtain sign-off from:
- [ ] **Chief Compliance Officer** (CCO) — Governance controls verified
- [ ] **CISO** — Security scan clean, pen test passed
- [ ] **General Counsel** — Privacy impact assessment approved
- [ ] **Provost** — Academic functionality verified (UC-01 through UC-05)
- [ ] **Registrar** — Transcript crosswalk (UC-02) tested with real data
- [ ] **Compliance Officer** — UC-08 monitoring active, alerts routing correctly
- [ ] **Data Analytics Team** — ETL pipelines running, data quality > 95%
- [ ] **QA Lead** — All test cases passed, no P0/P1 bugs open

### 11.3 Production Promotion

```bash
# Promote staging release to production
gcloud deploy releases promote --release=release-001 \
  --delivery-pipeline=smepro-cos-pipeline \
  --target=production

# Monitor canary rollout
kubectl get pods -n smepro-production -w

# Verify production health
curl -s https://smepro-cos.lamar.edu/v1/health/ready
```

---

## 12. Post-Go-Live: Runbooks

### 12.1 Incident Response

```bash
# 1. Identify incident severity
curl -s https://smepro-cos.lamar.edu/v1/module3/governance/incidents/open | jq .

# 2. For CRITICAL incidents: auto-escalation to CCO
# 3. For HIGH incidents: page on-call engineer
# 4. Run diagnostic commands
kubectl logs -l app=api-gateway -n api-gateway --tail=100
kubectl describe pod <pod-name> -n api-gateway

# 5. Rollback if needed
gcloud deploy rollouts rollback --rollout=rollout-001 \
  --delivery-pipeline=smepro-cos-pipeline \
  --target=production
```

### 12.2 Database Recovery

```bash
# Point-in-time recovery (last 5 minutes)
gcloud sql backups restore <backup-id> \
  --restore-instance=smepro-cos-postgres-production

# Or restore from GCS backup
gcloud sql import sql smepro-cos-postgres-production \
  gs://smepro-cos-prod-backups/backup-20240620.sql.gz
```

### 12.3 Scaling Events

```bash
# Scale API gateway horizontally
kubectl scale deployment api-gateway --replicas=5 -n api-gateway

# Scale Cloud SQL vertically
gcloud sql instances patch smepro-cos-postgres-production \
  --tier=db-custom-16-65536

# Scale Memorystore
gcloud redis instances update smepro-cos-redis-production \
  --memory-size-gb=16
```

---

## 13. Troubleshooting

### Issue: Pods stuck in `Pending`

```bash
# Check resource constraints
kubectl describe pod <pod-name> -n <namespace>
# Look for: Insufficient cpu, Insufficient memory

# Solution: GKE Autopilot auto-scales; wait 2–5 minutes
# If persistent, check node pool limits in Terraform
```

### Issue: Cloud SQL connection refused

```bash
# Check Cloud SQL proxy logs
kubectl logs -l app=cloudsql-proxy -n trust-model

# Verify private VPC connection
gcloud sql instances describe smepro-cos-postgres-production \
  --format="value(ipAddresses)"

# Verify service account permissions
gcloud projects get-iam-policy smepro-cos-prod \
  --filter="bindings.members:sa-cloudsql"
```

### Issue: Workload Identity not working

```bash
# Verify annotation
kubectl get serviceaccount k8s-api-gateway -n api-gateway -o yaml

# Verify IAM binding
gcloud iam service-accounts get-iam-policy \
  sa-api-gateway@smepro-cos-prod.iam.gserviceaccount.com

# Test from pod
kubectl exec -it deployment/api-gateway -n api-gateway -- \
  curl -H "Metadata-Flavor: Google" \
  http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token
```

### Issue: Terraform state lock

```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>

# Or manually remove from GCS
gcloud storage rm gs://smepro-cos-tfstate/terraform/state/default.tflock
```

---

## 14. Contact & Escalation

| Role | Contact | Escalation |
|------|---------|------------|
| **Primary On-Call** | SMEPro DevOps | PagerDuty rotation |
| **Secondary On-Call** | SMEPro Engineering Lead | Phone + Slack |
| **CCO** | Lamar Chief Compliance Officer | Direct line for CRITICAL |
| **CISO** | Lamar CISO | Security incidents only |
| **GCP Support** | GCP Console > Support | Billing account required |
| **SMEPro Emergency** | emergency@smepro.com | 24/7 hotline |

---

*End of Deployment Runbook.*
