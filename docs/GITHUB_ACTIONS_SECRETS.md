# GitHub Actions Secrets Guide
## SMEPro COS — GCP Deployment Secrets
## Version: 2026.06.20-LAMAR-GCP-1.0
## Date: 2026-06-20

---

## 1. Required Secrets

Configure these secrets in your GitHub repository: **Settings > Secrets and variables > Actions**

### 1.1 GCP Authentication (Choose ONE method)

#### Option A: Service Account Key (Quickstart, less secure)

| Secret Name | Value | How to Obtain |
|-------------|-------|---------------|
| `GCP_SA_KEY` | JSON service account key | `gcloud iam service-accounts keys create key.json --iam-account=sa-cicd@smepro-cos-prod.iam.gserviceaccount.com` |
| `GCP_PROJECT_ID` | `smepro-cos-prod` | GCP Console |
| `GCP_REGION` | `us-central1` | GCP Console |
| `GCP_ARTIFACT_REGISTRY` | `us-central1-docker.pkg.dev/smepro-cos-shared/artifact-registry/smepro` | GCP Console > Artifact Registry |

#### Option B: Workload Identity Federation (Recommended, more secure)

| Secret Name | Value | How to Obtain |
|-------------|-------|---------------|
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | `projects/123456789/locations/global/workloadIdentityPools/github-pool/providers/github-provider` | See setup steps below |
| `GCP_DEPLOY_SERVICE_ACCOUNT` | `sa-cicd@smepro-cos-prod.iam.gserviceaccount.com` | GCP IAM |
| `GCP_PROJECT_ID` | `smepro-cos-prod` | GCP Console |
| `GCP_REGION` | `us-central1` | GCP Console |
| `GCP_ARTIFACT_REGISTRY` | `us-central1-docker.pkg.dev/smepro-cos-shared/artifact-registry/smepro` | GCP Console |

**Why Workload Identity Federation?** No long-lived service account keys. GitHub Actions authenticates directly to GCP using OIDC tokens. No JSON keys to rotate or leak.

---

## 2. Workload Identity Federation Setup (Recommended)

### 2.1 Create Workload Identity Pool

```bash
export PROJECT_ID=smepro-cos-prod
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

# Create the workload identity pool
gcloud iam workload-identity-pools create github-pool \
  --project=$PROJECT_ID \
  --location=global \
  --display-name="GitHub Actions Pool"
```

### 2.2 Create Workload Identity Provider

```bash
# Create the provider for GitHub Actions
gcloud iam workload-identity-pools providers create-oidc github-provider \
  --project=$PROJECT_ID \
  --location=global \
  --workload-identity-pool=github-pool \
  --display-name="GitHub Actions Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com"
```

### 2.3 Create Service Account for CI/CD

```bash
# Create service account
gcloud iam service-accounts create sa-cicd \
  --display-name="CI/CD Service Account" \
  --project=$PROJECT_ID

# Grant necessary roles
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:sa-cicd@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/clouddeploy.jobRunner"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:sa-cicd@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/container.developer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:sa-cicd@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:sa-cicd@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:sa-cicd@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/cloudbuild.builds.editor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:sa-cicd@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:sa-cicd@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"
```

### 2.4 Allow GitHub Actions to Impersonate Service Account

```bash
# Get the full provider resource name
export PROVIDER="projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider"

# Allow the GitHub repository to impersonate the service account
gcloud iam service-accounts add-iam-policy-binding \
  sa-cicd@$PROJECT_ID.iam.gserviceaccount.com \
  --project=$PROJECT_ID \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/$PROVIDER/attribute.repository/SMEPro-Technologies-LLC/lupilot"
```

### 2.5 Store the Provider Name in GitHub Secrets

```bash
# Get the provider name (to store in GitHub)
echo "Provider: $PROVIDER"
# Store this value in GitHub Secret: GCP_WORKLOAD_IDENTITY_PROVIDER
```

---

## 3. Additional Secrets

### 3.1 Terraform Secrets

| Secret Name | Value | How to Obtain |
|-------------|-------|---------------|
| `TF_STATE_BUCKET` | `smepro-cos-tfstate` | Created in Day 1 setup |
| `GCP_TERRAFORM_SERVICE_ACCOUNT` | `sa-terraform@smepro-cos-prod.iam.gserviceaccount.com` | GCP IAM |

### 3.2 Notification Secrets

| Secret Name | Value | How to Obtain |
|-------------|-------|---------------|
| `SLACK_WEBHOOK_URL` | `https://hooks.slack.com/services/...` | Slack App > Incoming Webhooks |
| `PAGERDUTY_INTEGRATION_KEY` | `...` | PagerDuty > Services > Integration |

### 3.3 Security Scanning Secrets

| Secret Name | Value | How to Obtain |
|-------------|-------|---------------|
| `SNYK_TOKEN` | `...` | Snyk Dashboard > Account Settings |
| `CODECOV_TOKEN` | `...` | Codecov Dashboard > Repository |

### 3.4 Database Migration Secrets

| Secret Name | Value | How to Obtain |
|-------------|-------|---------------|
| `DB_PASSWORD` | (plaintext) | From Secret Manager `db-password-production` |

**Security note:** Never commit `DB_PASSWORD` to the repository. Use GitHub Secrets with restricted access.

---

## 4. Environment Variables (Not Secrets)

Configure these as **Variables** (not Secrets) in GitHub: **Settings > Secrets and variables > Actions > Variables**

| Variable Name | Value | Notes |
|---------------|-------|-------|
| `GCP_PROJECT_ID` | `smepro-cos-prod` | Used in multiple workflows |
| `GCP_REGION` | `us-central1` | Used in multiple workflows |
| `GCP_ARTIFACT_REGISTRY` | `us-central1-docker.pkg.dev/smepro-cos-shared/artifact-registry/smepro` | Docker image prefix |
| `GKE_CLUSTER_NAME` | `smepro-cos-gke` | Used in kubectl commands |
| `DOMAIN` | `smepro-cos.lamar.edu` | Used in SSL/DNS setup |

---

## 5. Verification

### 5.1 Test GitHub Actions Authentication

Create a test workflow `.github/workflows/test-gcp-auth.yml`:

```yaml
name: Test GCP Auth
on: workflow_dispatch
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ secrets.GCP_DEPLOY_SERVICE_ACCOUNT }}
      - uses: google-github-actions/setup-gcloud@v2
      - run: gcloud info
      - run: gcloud auth list
      - run: gcloud projects list
```

Run manually: **Actions > Test GCP Auth > Run workflow**

Expected output: Lists GCP projects including `smepro-cos-prod`.

### 5.2 Test Docker Push

```yaml
name: Test Docker Push
on: workflow_dispatch
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ secrets.GCP_DEPLOY_SERVICE_ACCOUNT }}
      - uses: google-github-actions/setup-gcloud@v2
      - run: gcloud auth configure-docker us-central1-docker.pkg.dev
      - run: |
          docker pull hello-world
          docker tag hello-world us-central1-docker.pkg.dev/smepro-cos-shared/artifact-registry/smepro/test:hello
          docker push us-central1-docker.pkg.dev/smepro-cos-shared/artifact-registry/smepro/test:hello
```

---

## 6. Secret Rotation Schedule

| Secret | Rotation Frequency | Owner | Procedure |
|--------|-------------------|-------|-----------|
| `GCP_SA_KEY` | Quarterly (if used) | CISO | Generate new key, update GitHub, delete old key |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Never (OIDC) | DevOps | N/A — no key to rotate |
| `DB_PASSWORD` | Quarterly | DBA | Rotate in Secret Manager, rolling restart of Cloud SQL proxy |
| `JWT_SIGNING_KEY` | Semi-annually | Security | Generate new key pair, update Secret Manager, rolling restart |
| `ANTHROPIC_API_KEY` | Annually | Academic Technology | Rotate in Anthropic console, update Secret Manager |
| `SLACK_WEBHOOK_URL` | Annually | DevOps | Regenerate in Slack, update GitHub Secret |
| `SNYK_TOKEN` | Annually | Security | Regenerate in Snyk, update GitHub Secret |

---

## 7. Security Best Practices

1. **Never use `GCP_SA_KEY` in production.** Use Workload Identity Federation exclusively.
2. **Restrict secret access.** Only repository admins and DevOps team should view secrets.
3. **Audit secret access.** Enable GitHub audit logs for secret usage.
4. **Use environment-specific secrets.** Different secrets for dev/staging/production.
5. **Rotate secrets proactively.** Before expiration, not after.
6. **Revoke leaked secrets immediately.** Use `gcloud iam service-accounts keys delete` if a key is compromised.
7. **Monitor secret usage.** Alert on unusual GitHub Actions activity.

---

*End of GitHub Actions Secrets Guide.*
