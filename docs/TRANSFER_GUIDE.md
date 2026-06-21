# Transfer Guide

**Project:** SMEPro COS / Lamar IOS+  
**Version:** 1.0  
**Date:** 2026-06-21  
**Purpose:** Step-by-step guide for transferring the SMEPro COS repository, infrastructure, and operational ownership to Lamar University.

---

## Overview

This guide enables Lamar University to take full ownership of the Compliance Operating System (COS) with minimal disruption. The transfer is designed to be **reversible during Phase 1**, **jointly operated during Phase 2**, and **fully Lamar-owned by Phase 3**.

The transfer assumes one of three target scenarios:

1. **GitHub Org Transfer:** Lamar creates their own GitHub organization and SMEPro transfers the repo.
2. **Fork & Evolve:** Lamar forks the repo into their org and SMEPro contributes via PR.
3. **Archive & Rebuild:** Lamar uses the repo as a reference and rebuilds with their own team (not recommended).

This guide focuses on **Scenario 1 (Transfer)** as the primary path, with notes for **Scenario 2 (Fork)** where applicable.

---

## Pre-Transfer Checklist (SMEPro)

Before initiating transfer, SMEPro must complete these steps:

### 1. Repository Hygiene

- [ ] Run `scripts/transfer-prep.sh` to inventory all SMEPro-specific references
- [ ] Replace all hard-coded `SMEPro-Technologies-LLC` references with parameterized variables
- [ ] Replace all hard-coded `smepro` domain references with env vars
- [ ] Replace all hard-coded `smepro-cos-*` project IDs with Terraform variables
- [ ] Remove all SMEPro email addresses, Slack webhooks, and notification channels from code
- [ ] Ensure no secrets (passwords, API keys, private keys) are in git history
- [ ] Run `git-secrets` or BFG Repo-Cleaner to verify
- [ ] Replace all real data in fixtures/seeds with synthetic data
- [ ] Ensure `LICENSE` file defines ownership terms clearly
- [ ] Add `CODEOWNERS` with Lamar + SMEPro teams
- [ ] Add `CONTRIBUTING.md` with Lamar's process
- [ ] Archive or delete old branches
- [ ] Ensure `main` is the default branch and is protected

### 2. Documentation Completeness

- [ ] `README.md` updated with Lamar-specific setup instructions
- [ ] `docs/ENVIRONMENT_BOOTSTRAP.md` complete
- [ ] `docs/OPERATIONS_HANDOFF.md` complete
- [ ] `docs/SECURITY_MODEL.md` complete
- [ ] `docs/BREAK_GLASS_RUNBOOK.md` complete
- [ ] `docs/DEPLOYMENT_RUNBOOK.md` complete
- [ ] `docs/PRODUCTION_READINESS_AND_TRANSFER_PLAN.md` complete
- [ ] All architecture docs updated with final implementation details

### 3. Infrastructure Parameterization

- [ ] Terraform variables for org name, project prefix, domain, region
- [ ] K8s manifests use ConfigMaps and env vars, not hard-coded values
- [ ] CI/CD workflows use GitHub repository variables, not hard-coded org names
- [ ] Container registries parameterized (Artifact Registry, Harbor, etc.)
- [ ] DNS zones parameterized
- [ ] TLS certificate issuer parameterized (Let's Encrypt, DigiCert, etc.)

### 4. Secret Seeding

- [ ] All secrets documented in `docs/SECRET_INVENTORY.md` (template below)
- [ ] Secret generation scripts created (e.g., `scripts/generate-secrets.sh`)
- [ ] No secrets in repo; all in Secret Manager / Vault
- [ ] SMEPro access to Lamar secrets revoked after transfer

---

## Transfer Phases

### Phase 1: Joint Ownership (Week 1–2)

**Goal:** Lamar gets read access and observes. SMEPro remains primary implementer.

**Actions:**

1. **Lamar creates GitHub organization** (if not existing)
   - e.g., `github.com/LamarUniversity`
   - Enable 2FA for all members
   - Configure SSO if using GitHub Enterprise

2. **SMEPro invites Lamar users to existing repo**
   - Grant `Read` or `Triage` access
   - Add to `CODEOWNERS` as reviewers

3. **Lamar reviews all documentation**
   - Architecture docs
   - Deployment runbook
   - Security model
   - Meeting to discuss questions

4. **Lamar provisions their own GCP project(s)**
   - Create `lamar-ios-dev`, `lamar-ios-staging`, `lamar-ios-prod`
   - Link to Lamar billing account
   - Add SMEPro service account as `Editor` (temporary)

5. **SMEPro deploys to Lamar-owned staging**
   - Using Lamar's GCP project
   - Using SMEPro's CI/CD (still running in SMEPro GitHub org)
   - Verify all services work in Lamar environment

### Phase 2: Shared Operations (Week 3–6)

**Goal:** Lamar owns the environment. SMEPro deploys into it. Joint incident response.

**Actions:**

1. **Lamar owns target environments**
   - All GCP projects under Lamar billing
   - All DNS records under Lamar domain
   - All TLS certificates under Lamar ownership

2. **SMEPro deploys into Lamar-owned infra**
   - SMEPro CI/CD uses Lamar's GCP credentials (temporary)
   - SMEPro's GitHub Actions deploys to Lamar's GKE cluster
   - Verify deployment works without SMEPro-owned infrastructure

3. **Lamar validates access and monitoring**
   - Can access Grafana dashboards
   - Can read Cloud Monitoring logs
   - Can access GCP Console
   - Can run `kubectl` commands (with proper IAM)

4. **Lamar tests incident response**
   - Simulate a service failure
   - Lamar team follows runbook to diagnose
   - SMEPro available as backup

5. **Lamar begins CI/CD migration**
   - Fork repo into Lamar GitHub org
   - Configure Lamar's GitHub Actions secrets
   - Configure Lamar's self-hosted runners (if on-prem)
   - Test Lamar CI/CD on a feature branch

### Phase 3: Controlled Handoff (Week 7–8)

**Goal:** Lamar owns repo, environments, and deployment. SMEPro becomes contributor.

**Actions:**

1. **Transfer repository to Lamar org**
   - GitHub Settings → Transfer ownership
   - Or: Lamar forks and SMEPro archives original
   - Ensure all issues, PRs, and discussions transfer

2. **Lamar CI/CD becomes primary**
   - Disable SMEPro GitHub Actions
   - Enable Lamar GitHub Actions
   - All deployments from Lamar org

3. **Rotate all secrets**
   - Generate new JWT signing keys
   - Generate new DB passwords
   - Generate new API keys
   - Revoke old secrets SMEPro may have had access to

4. **Remove SMEPro service accounts**
   - Remove SMEPro SA from Lamar GCP projects
   - Remove SMEPro users from Lamar GitHub repo
   - Add SMEPro users as external contributors (if needed)

5. **Joint ops sign-off**
   - Lamar can deploy without SMEPro
   - Lamar can restore from backup
   - Lamar can handle a P1 incident
   - Document rollback authority

### Phase 4: Full Lamar Operation (Week 9+)

**Goal:** Lamar runs the platform independently. SMEPro supports by agreement only.

**Actions:**

1. **Lamar runs all releases**
   - Feature branch → PR → merge → staging → production
   - No SMEPro involvement unless requested

2. **Lamar handles all incidents**
   - On-call rotation in Lamar team
   - SMEPro available via support agreement only

3. **SMEPro contributes via PR**
   - Fork Lamar repo (if needed)
   - Submit PRs for features/bug fixes
   - Lamar reviews and merges

4. **Support agreement activated**
   - SLA definitions (response times, resolution times)
   - Escalation matrix
   - Contact information
   - Billing and invoicing terms

---

## Secret Inventory Template

Create `docs/SECRET_INVENTORY.md` with this structure:

```markdown
# Secret Inventory

| Secret Name | Environment | Source | Rotation Frequency | Owner | Notes |
|-------------|-------------|--------|-------------------|-------|-------|
| db-password | all | Random gen | 90 days | Lamar | PostgreSQL master password |
| jwt-signing-key | all | Random gen | 90 days | Lamar | HS256 or RS256 key |
| idp-client-secret | all | IdP admin | 180 days | Lamar | SAML/OIDC client credential |
| tls-cert | all | cert-manager | 90 days | Lamar | Let's Encrypt auto-renewal |
| banner-api-credentials | prod | Banner admin | 90 days | Lamar | Banner SIS API |
| blackboard-api-key | prod | Blackboard admin | 180 days | Lamar | LMS API |
| slack-webhook-url | all | Slack admin | On demand | Lamar | Incident notifications |
| trace-chain-private-key | prod | Random gen | 90 days | Lamar | Ethereum signing key |
| gcp-service-account-key | all | GCP IAM | 90 days | Lamar | Workload identity preferred |
| github-pat | ci | GitHub admin | 90 days | Lamar | CI/CD token |
```

**Rule:** Every secret must have a generation script, a rotation procedure, and an owner.

---

## GitHub Org Setup Checklist (Lamar)

When Lamar creates their GitHub org, configure these settings:

### Organization Settings
- [ ] **Require 2FA** for all members
- [ ] **Enable SSO** (if GitHub Enterprise)
- [ ] **Configure SCIM** (if using IdP for user provisioning)
- [ ] **Enable secret scanning** for all repos
- [ ] **Enable Dependabot alerts** for all repos
- [ ] **Enable code scanning** with CodeQL
- [ ] **Configure branch protection rules** for `main` and `develop`
- [ ] **Configure repository roles** (Admin, Maintainer, Write, Triage, Read)

### Repository Settings (for COS repo)
- [ ] **Default branch:** `main`
- [ ] **Branch protection for `main`:**
  - Require pull request reviews before merging (minimum 2)
  - Require status checks to pass (CI pipeline)
  - Require signed commits (recommended)
  - Include administrators
- [ ] **Branch protection for `develop`:**
  - Require pull request reviews (minimum 1)
  - Require status checks
- [ ] **GitHub Actions:**
  - Enable actions
  - Configure required secrets and variables
  - Configure self-hosted runners (if on-prem)
- [ ] **Deploy keys:** None (use Workload Identity or deploy tokens)
- [ ] **Webhooks:** Configure for Slack/Teams notifications
- [ ] **Environment protection rules:**
  - `staging`: Require review from 1 person
  - `production`: Require review from 2 people + SMEPro (temporary)

### Team Structure
- [ ] **Team: `ios-plus-admins`** — Full admin access
- [ ] **Team: `ios-plus-developers`** — Write access
- [ ] **Team: `ios-plus-ops`** — Maintainer access (can deploy)
- [ ] **Team: `ios-plus-security`** — Triage + security alerts
- [ ] **Team: `ios-plus-auditors`** — Read access (compliance team)

---

## GCP Project Setup Checklist (Lamar)

### Organization & Folders
- [ ] Create GCP organization (if not existing) or use existing
- [ ] Create folder: `Lamar-IOS-Plus`
- [ ] Create projects under folder:
  - `lamar-ios-shared` (or `live-499913` if reusing)
  - `lamar-ios-dev`
  - `lamar-ios-staging`
  - `lamar-ios-prod`

### Billing
- [ ] Link all projects to Lamar billing account
- [ ] Set budget alerts ($500, $1000, $2000)
- [ ] Configure billing export to BigQuery

### IAM
- [ ] Add `operator@ioscos.com` as `Editor` on shared/staging (temporary)
- [ ] Add `operator@ioscos.com` as `Viewer` on prod (temporary)
- [ ] Create Lamar service accounts:
  - `github-actions-deploy` (for CI/CD)
  - `terraform-admin` (for IaC)
  - `backup-manager` (for backups)
  - `monitoring-reader` (for ops team)
- [ ] Configure Workload Identity Federation for GitHub Actions

### APIs
- [ ] Enable all required APIs in each project (see `infra/terraform/main.tf` for list)
- [ ] Verify API quotas are sufficient

### Networking
- [ ] Configure VPC with Lamar-specific CIDR ranges
- [ ] Configure VPN or Cloud Interconnect if on-prem hybrid
- [ ] Configure DNS zones and delegation
- [ ] Configure TLS certificates (cert-manager or Google-managed)

---

## On-Prem / Hybrid Setup Notes

If Lamar requires on-prem data residency:

### Kubernetes
- [ ] Provision on-prem K8s cluster (RKE, OpenShift, vanilla)
- [ ] Configure node pools for compute and storage separation
- [ ] Configure storage classes (Ceph, NFS, local SSD)
- [ ] Configure network CNI (Calico, Cilium)

### Data Layer
- [ ] PostgreSQL HA on-prem (Patroni + etcd + HAProxy)
- [ ] Redis HA on-prem (Redis Sentinel or Cluster)
- [ ] Kafka on-prem (if needed) or use Pub/Sub via VPC-SC
- [ ] Elasticsearch/OpenSearch on-prem (if needed)

### GCP Services (If Allowed)
- [ ] Artifact Registry (for container images)
- [ ] Secret Manager (via External Secrets Operator sync)
- [ ] Cloud Monitoring (via Ops Agent)
- [ ] GCS (for backups and artifacts)
- [ ] Cloud Build (for builds, if not using GitHub Actions)

### Identity
- [ ] Integrate on-prem K8s with Lamar Active Directory / LDAP
- [ ] Configure SAML/OIDC for web apps
- [ ] Configure RBAC with AD groups

---

## Post-Transfer Validation

After transfer is complete, verify:

1. **Lamar can clone the repo and build locally**
   ```bash
   git clone https://github.com/LamarUniversity/ios-plus.git
   cd ios-plus
   docker-compose up --build  # or equivalent
   ```

2. **Lamar can deploy to staging**
   ```bash
   git checkout -b feature/test-deploy
   # make a trivial change
   git push origin feature/test-deploy
   # open PR, merge to develop
   # verify staging deployment succeeds
   ```

3. **Lamar can access all monitoring**
   - Grafana dashboards load
   - Logs are visible
   - Alerts fire correctly

4. **Lamar can restore from backup**
   - Run restore drill
   - Verify data integrity
   - Verify app functionality

5. **Lamar can handle a P1 incident**
   - Simulate service failure
   - Follow break-glass runbook
   - Verify rollback works

---

## Rollback Plan

If transfer fails, SMEPro can roll back:

1. **Revert repository transfer**
   - If GitHub transfer was used, GitHub support can reverse within 24 hours
   - If fork was used, no action needed (original repo still owned by SMEPro)

2. **Revert infrastructure**
   - SMEPro still has Editor access during Phase 1
   - SMEPro can destroy and recreate resources in SMEPro projects
   - DNS can be reverted to SMEPro nameservers

3. **Revert secrets**
   - SMEPro never had access to Lamar production secrets (if rotated properly)
   - No secret rollback needed

4. **Communication**
   - Notify all stakeholders of rollback
   - Document lessons learned
   - Reschedule transfer with fixes

---

*This guide is a living document. Update it as the transfer progresses. Both SMEPro and Lamar must sign off on each phase before proceeding to the next.*
