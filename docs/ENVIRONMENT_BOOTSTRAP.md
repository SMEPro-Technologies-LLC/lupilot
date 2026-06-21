# Environment Bootstrap Guide

**Project:** SMEPro COS / Lamar IOS+  
**Version:** 1.0  
**Date:** 2026-06-21  
**Purpose:** Step-by-step instructions to bootstrap a new environment (dev, staging, or production) from scratch.

---

## Prerequisites

Before you begin, ensure you have:

- [ ] GCP project created and linked to billing (or on-prem K8s cluster)
- [ ] GitHub repository access (or equivalent Git provider)
- [ ] `gcloud` CLI installed and authenticated
- [ ] `kubectl` installed and configured
- [ ] `terraform` >= 1.5.0 installed
- [ ] `helm` >= 3.12 installed (if using Helm)
- [ ] `docker` installed (for local builds)
- [ ] Domain name registered and DNS accessible (or internal DNS for on-prem)
- [ ] IdP metadata URL or OIDC discovery URL (for SAML/OIDC auth)

**Time required:** ~2 hours for GCP, ~4 hours for on-prem.

---

## Bootstrap Steps

### Step 1: Clone Repository

```bash
git clone https://github.com/LamarUniversity/ios-plus.git
cd ios-plus
```

If this is SMEPro's org, use:
```bash
git clone https://github.com/SMEPro-Technologies-LLC/lupilot.git
cd lupilot
```

---

### Step 2: Configure Environment Variables

Copy the environment template:

```bash
cp environments/.env.template environments/.env.staging
cp environments/.env.template environments/.env.production
```

Edit the `.env` file with your environment-specific values:

```bash
# Organization
ORG_NAME=LamarUniversity
PROJECT_PREFIX=lamar-ios
DOMAIN=ios.lamar.edu

# GCP
GCP_REGION=us-central1
GCP_PROJECT_ID=lamar-ios-staging
GCP_BILLING_ACCOUNT=XXXXXX-XXXXXX-XXXXXX

# GitHub
GITHUB_ORG=LamarUniversity
GITHUB_REPO=ios-plus

# Container Registry
REGISTRY=us-central1-docker.pkg.dev/lamar-ios-shared/artifact-registry

# Database
DB_HOST=10.0.0.3
DB_PORT=5432
DB_NAME=ios_plus
DB_USER=ios_admin
DB_PASSWORD=<generate-me>
DB_SSL_MODE=require

# Redis
REDIS_HOST=10.0.0.4
REDIS_PORT=6379
REDIS_PASSWORD=<generate-me>

# Auth
IDP_TYPE=saml  # or oidc
IDP_METADATA_URL=https://sso.lamar.edu/metadata.xml
IDP_ENTITY_ID=https://ios.lamar.edu/sp
IDP_SSO_URL=https://sso.lamar.edu/idp/profile/SAML2/Redirect/SSO
IDP_SLO_URL=https://sso.lamar.edu/idp/profile/SAML2/Redirect/SLO
IDP_CERTIFICATE=<paste-cert-here>
JWT_SIGNING_KEY=<generate-256-bit-key>
JWT_EXPIRATION=3600

# TLS
TLS_CERT_SOURCE=letsencrypt  # or purchased, or self-signed
TLS_EMAIL=admin@lamar.edu
TLS_ACME_SERVER=https://acme-v02.api.letsencrypt.org/directory

# Monitoring
GRAFANA_ADMIN_PASSWORD=<generate-me>
ALERTMANAGER_SLACK_WEBHOOK=https://hooks.slack.com/services/XXXX/XXXX/XXXX
PROMETHEUS_RETENTION=30d

# Secrets Manager
SECRETS_MANAGER=gcp  # or vault, or kubernetes
VAULT_ADDR=https://vault.lamar.edu:8200
VAULT_ROLE=ios-plus

# Logging
LOG_LEVEL=info
LOG_FORMAT=json
```

**Generate passwords:**
```bash
# Generate a 32-character secure password
openssl rand -base64 32

# Generate a JWT signing key
openssl rand -base64 64
```

---

### Step 3: Create Terraform State Backend

The Terraform state must be stored remotely with locking.

#### Option A: GCS Backend (Recommended for GCP)

```bash
cd infra/terraform

# Create the state bucket (one-time, in shared project)
gcloud storage buckets create gs://lamar-ios-tfstate \
  --project=lamar-ios-shared \
  --location=us-central1

gcloud storage buckets update gs://lamar-ios-tfstate --versioning

# Verify
terraform init
```

#### Option B: S3 Backend (If using AWS or S3-compatible storage)

Edit `infra/terraform/main.tf`:
```hcl
terraform {
  backend "s3" {
    bucket         = "lamar-ios-tfstate"
    key            = "terraform/state"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

#### Option C: Local Backend (Dev Only, Not Recommended)

For local dev only. Do not use for staging or production.

---

### Step 4: Enable GCP APIs

Run this in the target project:

```bash
gcloud config set project $GCP_PROJECT_ID

gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  sqladmin.googleapis.com \
  redis.googleapis.com \
  pubsub.googleapis.com \
  storage.googleapis.com \
  secretmanager.googleapis.com \
  clouddeploy.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  cloudkms.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com \
  cloudtrace.googleapis.com \
  aiplatform.googleapis.com \
  securitycenter.googleapis.com \
  cloudasset.googleapis.com \
  iap.googleapis.com \
  dns.googleapis.com \
  certificatemanager.googleapis.com
```

**Note:** On-prem environments only need GCP APIs if using hybrid services (Artifact Registry, Secret Manager, etc.).

---

### Step 5: Terraform Apply — Infrastructure

```bash
cd infra/terraform

# Select workspace
terraform workspace new staging
# or: terraform workspace new production
terraform workspace select staging

# Plan
terraform plan \
  -var-file="environments/staging.tfvars" \
  -out=tfplan-staging

# Review the plan carefully. Ensure no destruction of existing resources.

# Apply
terraform apply tfplan-staging
```

**Verify outputs:**
```bash
terraform output
# Should show: cluster_name, cluster_endpoint, db_connection_name, redis_host, etc.
```

---

### Step 6: Configure kubectl

```bash
# Get cluster credentials
gcloud container clusters get-credentials $(terraform output -raw cluster_name) \
  --region $(terraform output -raw region) \
  --project $(terraform output -raw project_id)

# Verify
kubectl cluster-info
kubectl get nodes
```

---

### Step 7: Seed Secrets

#### Option A: GCP Secret Manager (Recommended for GCP)

```bash
cd scripts

# Run the secret seeding script
./seed-secrets.sh --environment=staging --project=$GCP_PROJECT_ID

# Or manually:
gcloud secrets create db-password --data-file=<(echo -n 'your-password') --project=$GCP_PROJECT_ID
gcloud secrets create jwt-signing-key --data-file=<(echo -n 'your-key') --project=$GCP_PROJECT_ID
gcloud secrets create idp-client-secret --data-file=<(echo -n 'your-secret') --project=$GCP_PROJECT_ID
# ... etc
```

#### Option B: HashiCorp Vault

```bash
vault kv put secret/ios-plus/staging/db-password value="your-password"
vault kv put secret/ios-plus/staging/jwt-signing-key value="your-key"
# ... etc
```

#### Option C: Kubernetes Secrets (Dev Only)

```bash
kubectl create namespace ios-plus
kubectl create secret generic db-password --from-literal=password="your-password" -n ios-plus
# ... etc
```

**Verify secrets are accessible:**
```bash
# For GCP Secret Manager + Workload Identity:
kubectl run test-secret --image=busybox --rm -it --restart=Never -- \
  sh -c "wget -qO- http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token"
```

---

### Step 8: Deploy Kubernetes Platform Services

#### Option A: Helm (Recommended)

```bash
cd k8s/helm

# Add required Helm repos
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

# Install NGINX Ingress
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --values values-ingress.yaml

# Install cert-manager
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true

# Install External Secrets Operator
helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace

# Install monitoring stack
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values values-monitoring.yaml

# Install the main application
helm install ios-plus . \
  --namespace ios-plus \
  --create-namespace \
  --values values-staging.yaml
```

#### Option B: Kustomize (Existing)

```bash
cd k8s/overlays/staging

# If using Kustomize (legacy approach)
kubectl apply -k .

# Verify
kubectl get pods -n api-gateway
kubectl get pods -n connector-ingestion
# ... etc
```

---

### Step 9: Configure DNS

#### Option A: Cloud DNS (GCP)

```bash
# Get ingress external IP
kubectl get service ingress-nginx-controller -n ingress-nginx

# Create DNS record
gcloud dns record-sets create ios.lamar.edu \
  --zone=lamar-zone \
  --type=A \
  --ttl=300 \
  --rrdatas=<INGRESS_IP>
```

#### Option B: External DNS (Automated)

```bash
helm install external-dns bitnami/external-dns \
  --namespace external-dns \
  --create-namespace \
  --set provider=google \
  --set google.project=$GCP_PROJECT_ID \
  --set policy=sync
```

#### Option C: Manual / On-Prem DNS

Update your internal DNS server or `/etc/hosts`:
```
<INGRESS_IP>  ios.lamar.edu
<INGRESS_IP>  api.ios.lamar.edu
<INGRESS_IP>  grafana.ios.lamar.edu
```

---

### Step 10: Configure TLS / Certificates

#### Option A: Let's Encrypt with cert-manager

```bash
kubectl apply -f k8s/base/cluster-issuer.yaml
```

Contents of `cluster-issuer.yaml`:
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@lamar.edu
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

#### Option B: Purchased Certificate

```bash
kubectl create secret tls ios-plus-tls \
  --cert=path/to/cert.pem \
  --key=path/to/key.pem \
  -n ios-plus
```

#### Option C: Self-Signed (Dev Only)

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt -subj "/CN=ios.lamar.edu"

kubectl create secret tls ios-plus-tls \
  --cert=tls.crt --key=tls.key -n ios-plus
```

**Verify certificate:**
```bash
kubectl get certificate -n ios-plus
kubectl describe certificate ios-plus-cert -n ios-plus
```

---

### Step 11: Run Database Migrations

```bash
# Deploy Flyway job
kubectl apply -f k8s/jobs/flyway-migrate.yaml

# Wait for completion
kubectl wait --for=condition=complete job/flyway-migrate -n ios-plus --timeout=300s

# Verify
kubectl logs job/flyway-migrate -n ios-plus
```

**Verify schema:**
```bash
# Connect to database
kubectl run psql-client --image=postgres:16 --rm -it --restart=Never -- \
  psql postgres://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME \
  -c "\dt"
```

---

### Step 12: Verify Deployment

#### Health Checks
```bash
# API Gateway health
curl https://api.ios.lamar.edu/health

# Frontend loads
curl -I https://ios.lamar.edu

# Database connectivity
kubectl exec deployment/api-gateway -n api-gateway -- \
  wget -qO- http://localhost:8080/health
```

#### Smoke Tests
```bash
# Run automated smoke tests
npm run test:smoke -- --env=staging
# or
pytest tests/smoke/ --env=staging
```

#### Monitoring
```bash
# Check Grafana
kubectl port-forward service/grafana -n monitoring 3000:3000
# Open http://localhost:3000 (admin / <GRAFANA_ADMIN_PASSWORD>)

# Check Prometheus
kubectl port-forward service/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090
# Open http://localhost:9090
```

---

## On-Prem / Hybrid Bootstrap Differences

If running on-prem, these steps differ:

### Kubernetes Cluster
- **Provision:** Use RKE, OpenShift, or kubeadm instead of GKE
- **Storage:** Configure Ceph, NFS, or local PVs instead of GKE Persistent Disks
- **Network:** Configure Calico or Cilium instead of GCP VPC

### Database
- **PostgreSQL:** Use Patroni + etcd + HAProxy instead of Cloud SQL
- **Redis:** Use Redis Sentinel or Cluster instead of Memorystore
- **Backup:** Use pgBackRest or WAL-G to S3/GCS instead of Cloud SQL automated backups

### Registry
- **Use Harbor or Docker Registry** instead of Artifact Registry
- **Configure image scanning** (Trivy, Clair)

### Secrets
- **Use HashiCorp Vault** instead of Secret Manager
- **Deploy Vault** in HA mode with auto-unseal

### Load Balancer
- **Use MetalLB or NGINX** instead of GCE Load Balancer
- **Configure on-prem load balancer** (F5, HAProxy, etc.)

### Monitoring
- **Use self-hosted Prometheus/Grafana** instead of Cloud Monitoring
- **Use Loki** instead of Cloud Logging
- **Use Jaeger or Tempo** instead of Cloud Trace

---

## Troubleshooting

### Terraform fails to apply
- Check `terraform plan` output for errors
- Verify GCP APIs are enabled
- Verify IAM permissions (need `roles/owner` or `roles/editor`)
- Check quota limits (CPU, IP addresses, etc.)

### kubectl cannot connect to cluster
- Run `gcloud container clusters get-credentials` again
- Verify `kubectl` version matches cluster version (±1 minor version)
- Check firewall rules (port 443 to GKE control plane)

### Secrets not accessible from pods
- Verify Workload Identity is configured correctly
- Verify service account has `roles/secretmanager.secretAccessor`
- Verify pod has correct `serviceAccountName`
- Check `external-secrets` pod logs

### Database migrations fail
- Check Flyway job logs: `kubectl logs job/flyway-migrate`
- Verify database connectivity from cluster
- Verify database user has CREATE TABLE permissions
- Check if migrations are ordered correctly (no gaps)

### Ingress not routing traffic
- Verify DNS resolves to ingress IP: `nslookup ios.lamar.edu`
- Verify ingress class is correct: `kubectl get ingress -o yaml`
- Verify backend services are healthy: `kubectl get endpoints`
- Check ingress controller logs: `kubectl logs -n ingress-nginx deployment/ingress-nginx-controller`

### TLS certificate not issued
- Check cert-manager logs: `kubectl logs -n cert-manager deployment/cert-manager`
- Verify ClusterIssuer is created: `kubectl get clusterissuer`
- Verify Certificate resource: `kubectl get certificate -n ios-plus`
- Verify DNS points to ingress IP (ACME HTTP-01 challenge)
- Check for rate limits with Let's Encrypt

### Services cannot communicate
- Verify network policies allow traffic between namespaces
- Verify DNS resolution within cluster: `kubectl run -it --rm debug --image=busybox:1.28 -- nslookup kubernetes.default`
- Verify service discovery: `kubectl get svc -n <namespace>`
- Check firewall rules between namespaces

---

## Bootstrap Completion Checklist

After completing all steps, verify:

- [ ] All pods are running: `kubectl get pods --all-namespaces`
- [ ] All services are accessible via ingress
- [ ] TLS certificate is valid and auto-renewing
- [ ] Database migrations completed successfully
- [ ] Health checks return 200 for all services
- [ ] Smoke tests pass
- [ ] Monitoring dashboards show data
- [ ] Alertmanager can send notifications
- [ ] Backup job ran successfully
- [ ] Log aggregation is working
- [ ] Auth flow works (login → dashboard)
- [ ] Secrets are injected correctly (no hard-coded values)
- [ ] Cost estimates match budget expectations

---

*This guide is a living document. Update it as the platform evolves. If you find a missing step, add it and submit a PR.*
