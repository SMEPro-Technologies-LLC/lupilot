# CI/CD Workflows for SMEPro COS on GCP

This directory contains GitHub Actions workflows for continuous integration and deployment to Google Cloud Platform.

## Workflows

- `ci-gcp.yml`: Continuous Integration - lint, test, build, security scan
- `cd-gcp.yml`: Continuous Deployment - deploy to GCP via Cloud Deploy

## Required Secrets

Configure the following secrets in GitHub repository settings (Settings > Secrets and variables > Actions):

| Secret | Description | How to obtain |
|--------|-------------|---------------|
| `GCP_PROJECT_ID` | GCP project ID (e.g., `smepro-cos-prod`) | GCP Console |
| `GCP_REGION` | GCP region (e.g., `us-central1`) | GCP Console |
| `GCP_SA_KEY` | Service account key JSON (for CI/CD) | GCP IAM > Service Accounts |
| `GCP_ARTIFACT_REGISTRY` | Artifact Registry URL | GCP Console > Artifact Registry |
| `TF_STATE_BUCKET` | Terraform state bucket name | Cloud Storage |
| `DB_PASSWORD` | Cloud SQL password (for migrations) | Secret Manager or manual |

## Workload Identity Federation (Recommended Alternative)

Instead of `GCP_SA_KEY`, use Workload Identity Federation for keyless authentication:

1. Create a Workload Identity Pool in GCP
2. Create a Provider for GitHub Actions
3. Grant the pool permission to deploy to your project
4. Use the `google-github-actions/auth` action with `workload_identity_provider` and `service_account` inputs

See: https://github.com/google-github-actions/auth#workload-identity-federation
