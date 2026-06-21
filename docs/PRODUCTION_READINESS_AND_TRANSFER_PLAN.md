# Production Readiness & Transfer Plan

**Project:** SMEPro Compliance Operating System (COS) for Lamar University  
**Version:** 1.0  
**Date:** 2026-06-21  
**Status:** Draft — Ready for Review  
**Owner:** SMEPro Technologies / Lamar University (Joint)  

---

## Executive Summary

This document converts the SMEPro COS architecture specification into an executable production readiness and transfer program. It is designed to close the gap between **reference architecture** (what exists in `docs/`) and **deployable platform** (what runs in Lamar's environment).

The plan is organized into two parallel workstreams:

1. **Production Hardening** — making the platform deployable, observable, secure, and compliant
2. **Portability Packaging** — ensuring Lamar can take full ownership without re-architecting

### Current State Assessment

| Dimension | Status | Evidence |
|-----------|--------|----------|
| Architecture docs | ✅ Complete | 4 reference documents, interactive HTML diagram |
| Database schema | ✅ Partial | PLpgSQL migrations (V1–V14), 52 tables, 17 views |
| Infrastructure as Code | ✅ Partial | Terraform modules for VPC, GKE, Cloud SQL, Redis, Pub/Sub, Storage |
| CI/CD pipelines | ✅ Partial | GitHub Actions CI + CD skeletons, Cloud Deploy config |
| Kubernetes manifests | ✅ Partial | Base deployments, Kustomize overlays, network policies |
| Application services | ⚠️ Missing | No runnable Docker images beyond spec |
| Secrets management | ⚠️ Spec only | Secret Manager references, no actual secret provisioning |
| Observability | ⚠️ Spec only | Grafana/Prometheus/Loki references, no dashboards/alerts |
| Auth/RBAC | ⚠️ Spec only | SAML/OIDC described, no IdP integration code |
| Compliance evidence | ⚠️ Spec only | FERPA/pseudonymization described, no enforcement tooling |

**Bottom line:** The repo is ~30% implementation, 70% specification. This plan closes that gap in 90 days.

---

## 1. Production Wave Definition

Do not ship the full reference architecture at once. Define three waves:

### Production Wave 1 — Core Platform (Days 1–45)
**Goal:** A single vertical slice that Lamar can log into, run a report, and approve a decision.

| Component | Scope | Owner |
|-----------|-------|-------|
| PostgreSQL HA | Cloud SQL or on-prem Postgres, migrations, PITR | SMEPro |
| Redis | Session cache, job state | SMEPro |
| API Gateway | Health probes, rate limiting, TLS termination | SMEPro |
| UDM Query Service | Read-only canonical data queries | SMEPro |
| Evidence Chain Service | Immutable audit trail (simplified, no blockchain v1) | SMEPro |
| One Frontend | React/Vue app, auth-protected, role-lens views | SMEPro |
| Auth/RBAC | SAML/OIDC integration, group-to-role mapping | Joint |
| CI/CD | Build, test, deploy to staging with approval gate | SMEPro |
| Logging/Monitoring | Structured logs, health dashboards, basic alerts | SMEPro |
| Backup/Restore | Daily backups, documented restore procedure | SMEPro |

### Production Wave 2 — Data Pipeline (Days 46–75)
**Goal:** Ingest data from Banner/SIS, normalize it, and drive workflow triggers.

| Component | Scope | Owner |
|-----------|-------|-------|
| Connector Ingestion | Banner API, Blackboard API, CSV upload | SMEPro |
| Normalization Engine | UDM canonical mapping, field validation | SMEPro |
| Rules Engine | Drools-based policy checks, basic rule set | SMEPro |
| Workflow Orchestrator | Approval queues, state machine, notifications | SMEPro |
| Pub/Sub Event Bus | Internal events, decoupled services | SMEPro |
| Kafka/CDC | Debezium for change data capture (deferred if Pub/Sub sufficient) | SMEPro |
| Expanded Frontend | Additional role lenses, dashboards | SMEPro |

### Production Wave 3 — Intelligence & Governance (Days 76–90)
**Goal:** AI-assisted insights, full governance automation, and trace chain integrity.

| Component | Scope | Owner |
|-----------|-------|-------|
| ML Jobs | Risk scoring, anomaly detection, cohort analysis | SMEPro |
| Explainability Layer | SHAP/LIME-style model explanations | SMEPro |
| Trace Chain / Blockchain | Immutable governance event ledger | SMEPro |
| Advanced Governance | Automated approval routing, escalation policies | SMEPro |
| Compliance Automation | FERPA audit reports, retention enforcement | SMEPro |

---

## 2. 90-Day Execution Timeline

### Phase 1: Foundation & Inventory (Days 1–15)

**Day 1–3: Repo Audit**
- [ ] Inventory all files vs. architecture docs
- [ ] Tag every file as `spec-only`, `partial-impl`, or `production-ready`
- [ ] Identify missing Dockerfiles, Helm charts, service code
- [ ] Document language mix: PLpgSQL, HCL, YAML, Markdown (no app runtime)

**Day 4–7: Scope Lock**
- [ ] Finalize Wave 1 component list with Lamar stakeholders
- [ ] Define "production-ready" acceptance criteria per component
- [ ] Assign owners (SMEPro vs. Lamar vs. Joint)
- [ ] Create GitHub project board with milestones

**Day 8–12: Environment Decision**
- [ ] Confirm target runtime: GKE, on-prem K8s, or hybrid
- [ ] Confirm data residency requirements (on-prem trust boundary)
- [ ] Confirm IdP: Lamar SSO, Azure AD, Google Workspace, etc.
- [ ] Confirm network topology: DMZ, campus VLAN, VPN requirements
- [ ] Document decision in `docs/TARGET_ENVIRONMENT_DECISION.md`

**Day 13–15: Transfer Readiness Setup**
- [ ] Create `docs/TRANSFER_GUIDE.md`
- [ ] Create `docs/ENVIRONMENT_BOOTSTRAP.md`
- [ ] Create `docs/OPERATIONS_HANDOFF.md`
- [ ] Create `docs/SECURITY_MODEL.md`
- [ ] Create `docs/BREAK_GLASS_RUNBOOK.md`
- [ ] Run `scripts/transfer-prep.sh` to inventory SMEPro-specific references

### Phase 2: Standardization & Containerization (Days 16–30)

**Day 16–20: Repo Restructure**
- [ ] Move all SMEPro-specific names to env vars / config
- [ ] Parameterize Terraform: `org_name`, `project_prefix`, `domain`, `region`
- [ ] Parameterize K8s: `registry`, `image_tag`, `replicas`, `resources`
- [ ] Parameterize CI/CD: `workload_identity_provider`, `service_account`, `project_id`
- [ ] Add `CODEOWNERS` file
- [ ] Add branch protection rules template
- [ ] Add Dependabot configuration

**Day 21–25: Dockerfile Baseline**
- [ ] Create deterministic Dockerfile for API Gateway
- [ ] Create deterministic Dockerfile for UDM Query Service
- [ ] Create deterministic Dockerfile for Evidence Chain Service
- [ ] Create deterministic Dockerfile for Frontend
- [ ] All Dockerfiles: non-root user, pinned base image, healthcheck, SBOM-ready
- [ ] Add `.dockerignore` files
- [ ] Add `docker-compose.yml` for local dev (optional but recommended)

**Day 26–30: Kubernetes Packaging**
- [ ] Choose canonical packaging: Helm (recommended) or Kustomize
- [ ] Create Helm chart for Wave 1 services
- [ ] Define `values.yaml` with all environment variables
- [ ] Define `values-staging.yaml` and `values-production.yaml`
- [ ] Add health/readiness probes to all deployments
- [ ] Add resource requests/limits (CPU, memory)
- [ ] Add pod disruption budgets for HA
- [ ] Add HPA (Horizontal Pod Autoscaler) templates
- [ ] Add network policies (default deny, selective allow)
- [ ] Add pod security policies / security contexts

### Phase 3: Environment Provisioning & Deploy (Days 31–45)

**Day 31–35: Dev/Staging Provisioning**
- [ ] Provision `dev` environment (can be shared project or namespace)
- [ ] Provision `staging` environment
- [ ] Verify Terraform applies cleanly with parameterized vars
- [ ] Verify GKE cluster creation and node pool health
- [ ] Verify Cloud SQL / on-prem Postgres connectivity
- [ ] Verify Redis / Memorystore connectivity
- [ ] Verify Secret Manager / Vault secret injection
- [ ] Verify Ingress + TLS + DNS

**Day 36–40: Application Deploy**
- [ ] Build and push Wave 1 images to Artifact Registry
- [ ] Deploy Helm chart to staging
- [ ] Run database migrations (Flyway job)
- [ ] Verify service-to-service communication
- [ ] Verify health endpoints respond 200
- [ ] Verify frontend loads and authenticates
- [ ] Run smoke tests (login, query, approval flow)

**Day 41–45: Observability Baseline**
- [ ] Deploy Prometheus + Grafana (or Cloud Monitoring)
- [ ] Deploy Loki (or Cloud Logging)
- [ ] Create dashboards: API health, DB health, queue health
- [ ] Create alerts: service down, 5xx spike, cert expiry, backup failure
- [ ] Add structured logging (JSON) to all services
- [ ] Add correlation IDs to all requests
- [ ] Add distributed tracing (OpenTelemetry or Cloud Trace)
- [ ] Run load test and verify metrics capture

### Phase 4: Security & Hardening (Days 46–60)

**Day 46–50: Auth & RBAC**
- [ ] Integrate Lamar IdP (SAML or OIDC)
- [ ] Configure group-to-role mapping
- [ ] Implement role-lens enforcement (Advisor, Faculty, Registrar, etc.)
- [ ] Test MFA enforcement
- [ ] Test break-glass admin access
- [ ] Document auth failure scenarios

**Day 51–55: Network & Secrets**
- [ ] Verify all secrets are in Secret Manager / Vault (none in repo)
- [ ] Rotate all default/example passwords
- [ ] Verify TLS everywhere (external + internal mTLS if possible)
- [ ] Verify WAF rules (SQLi, XSS, rate limiting)
- [ ] Verify network policies block unauthorized traffic
- [ ] Run penetration test or vulnerability scan
- [ ] Generate SBOMs for all images
- [ ] Run Trivy/Snyk scan and fix critical issues

**Day 56–60: Compliance & Audit**
- [ ] Implement FERPA data classification tags
- [ ] Verify pseudonymization at ingestion
- [ ] Verify row-level security on sensitive tables
- [ ] Test audit trail completeness (who, what, when)
- [ ] Test data export restrictions
- [ ] Document retention policies
- [ ] Run compliance readiness review with Lamar

### Phase 5: Lamar Integration & Joint Ops (Days 61–75)

**Day 61–65: Lamar Environment Setup**
- [ ] Lamar creates their own GCP project/org (or on-prem cluster)
- [ ] Lamar grants SMEPro deployment access (temporary)
- [ ] SMEPro deploys to Lamar-owned staging
- [ ] Lamar validates access, logs, monitoring
- [ ] Lamar tests IdP integration with their SSO

**Day 66–70: Self-Hosted Runner Setup (if on-prem)**
- [ ] Deploy GitHub self-hosted runners in Lamar network
- [ ] Configure runner groups: dev, staging, prod
- [ ] Verify runners can reach private K8s API
- [ ] Test deployment pipeline through private runner
- [ ] Document runner maintenance procedures

**Day 71–75: Joint Operations Exercise**
- [ ] Simulate incident: service failure → pager alert → rollback
- [ ] Simulate incident: DB corruption → restore from backup
- [ ] Simulate incident: cert expiry → renewal
- [ ] Lamar team runs deployment without SMEPro help
- [ ] Document gaps and fix

### Phase 6: Go-Live & Formal Handoff (Days 76–90)

**Day 76–80: Production Readiness Review**
- [ ] All Wave 1 acceptance criteria met
- [ ] Security scan clean (no critical/high findings)
- [ ] Performance test passed (expected load + 2x burst)
- [ ] DR test passed (RTO/RPO validated)
- [ ] Compliance review passed
- [ ] Runbook review complete
- [ ] Sign-off from Lamar stakeholders

**Day 81–85: Production Deployment**
- [ ] Deploy to production with SMEPro + Lamar joint supervision
- [ ] Enable monitoring and alerting
- [ ] Enable backup schedules
- [ ] Run production smoke tests
- [ ] Switch DNS / load balancer to production
- [ ] Announce go-live

**Day 86–90: Formal Handoff**
- [ ] Transfer GitHub repo to Lamar org (or fork)
- [ ] Transfer GCP project ownership to Lamar billing
- [ ] Rotate all secrets (SMEPro no longer has access)
- [ ] Remove SMEPro service accounts from Lamar environments
- [ ] Final documentation sign-off
- [ ] Support agreement activated (SLA, escalation, contacts)
- [ ] Close Phase 1 transfer

---

## 3. Transfer Readiness Checklist

### A. Repository Transferability

| Item | Status | Action |
|------|--------|--------|
| No hard-coded SMEPro org names | ⬜ | `scripts/transfer-prep.sh` |
| No hard-coded SMEPro domains | ⬜ | Search/replace to env vars |
| No hard-coded SMEPro email/Slack | ⬜ | Move to config/secrets |
| No hard-coded GCP project IDs | ⬜ | Terraform variables |
| No secrets in git history | ⬜ | `git-secrets` or BFG scrub |
| No real data in fixtures/seeds | ⬜ | Synthetic data only |
| `CODEOWNERS` file | ⬜ | Define Lamar + SMEPro owners |
| Branch protection template | ⬜ | PR required, reviews required |
| Dependabot enabled | ⬜ | Security updates auto |
| License file | ⬜ | Define ownership terms |
| `CONTRIBUTING.md` | ⬜ | Lamar contribution process |

### B. Infrastructure Ownership

| Item | Status | Action |
|------|--------|--------|
| Lamar owns GCP org / billing | ⬜ | Create projects under Lamar |
| Lamar owns DNS / domains | ⬜ | Delegate or transfer |
| Lamar owns TLS certificates | ⬜ | cert-manager or purchased |
| Lamar owns artifact registry | ⬜ | Artifact Registry or Harbor |
| Lamar owns CI/CD runners | ⬜ | Self-hosted or GitHub-hosted |
| Lamar owns monitoring | ⬜ | Cloud Monitoring or self-hosted |
| Lamar owns backups | ⬜ | Backup schedules in Lamar project |
| SMEPro has no persistent admin | ⬜ | Temporary access only |

### C. Knowledge Transfer

| Item | Status | Action |
|------|--------|--------|
| Architecture docs complete | ⬜ | All components documented |
| Deployment runbook complete | ⬜ | Step-by-step with commands |
| Operations runbook complete | ⬜ | Incident response, on-call |
| Security model documented | ⬜ | Threat model, controls |
| Break-glass procedure documented | ⬜ | Emergency access, rollback |
| Training delivered | ⬜ | Lamar team walkthrough |
| Support contact established | ⬜ | SLA, escalation matrix |

---

## 4. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Architecture ahead of implementation | High | High | Ruthlessly scope Wave 1; prove vertical slice |
| Too many moving parts for v1 | High | High | Defer Kafka, Spark, ML, blockchain to Wave 3 |
| Lamar IdP integration complexity | Medium | High | Start IdP integration in Week 1; test early |
| Transfer friction (SMEPro assumptions) | Medium | High | Parameterize everything now; `transfer-prep.sh` |
| Compliance posture not operationalized | Medium | High | Security review Week 4; audit tests Week 8 |
| On-prem network complexity | Medium | Medium | Hybrid option: GCP control plane, on-prem data |
| SMEPro resource constraints | Medium | Medium | Weekly milestone reviews; early scope cuts |
| Lamar team availability | Medium | Medium | Joint ops exercises; documentation heavy |

---

## 5. Success Criteria

This plan is complete when:

1. **A new team can clone the repo and stand up dev/staging/prod predictably** within 4 hours
2. **Deployment requires no tribal knowledge** — every step is in a runbook or pipeline
3. **All infrastructure is codified** — `terraform apply` + `helm install` = running platform
4. **Secrets, IAM, certificates, and audit are environment-owned** — not vendor-owned
5. **Lamar can deploy to their GitHub org + GCP, or on-prem K8s, without re-architecting**
6. **All Wave 1 services pass health checks, auth flows, and backup/restore tests**
7. **Formal handoff is signed by both SMEPro and Lamar leadership**

---

## 6. Document References

| Document | Purpose | Location |
|----------|---------|----------|
| `DEPLOYMENT_RUNBOOK.md` | Day-by-day deployment procedures | `docs/` |
| `GITHUB_ACTIONS_SECRETS.md` | CI/CD secrets and configuration | `docs/` |
| `TRANSFER_GUIDE.md` | How to move repo to Lamar org | `docs/` |
| `ENVIRONMENT_BOOTSTRAP.md` | Bootstrap a new environment from scratch | `docs/` |
| `OPERATIONS_HANDOFF.md` | Runbooks, incident response, on-call | `docs/` |
| `SECURITY_MODEL.md` | Threat model, controls, compliance | `docs/` |
| `BREAK_GLASS_RUNBOOK.md` | Emergency access, disaster recovery | `docs/` |
| `DEPLOYMENT_READINESS_MATRIX.md` | Component-by-component readiness tracker | `docs/` |
| `Module3_AI_Governance_Framework.md` | AI governance and approval gates | `docs/` |
| `SMEPro_COS_Master_Delivery_Summary_2026-06-20.md` | Architecture and delivery summary | `docs/` |

---

## 7. Next Immediate Actions (This Week)

1. **SMEPro leadership reviews and approves this plan**
2. **Lamar stakeholders confirm Wave 1 scope and target environment**
3. **SMEPro creates GitHub project board with milestones**
4. **SMEPro runs `scripts/transfer-prep.sh` to inventory SMEPro-specific references**
5. **SMEPro and Lamar schedule weekly standup (30 min, same time each week)**
6. **SMEPro begins repo restructure: parameterize org names, domains, project IDs**

---

*This plan is a living document. Update it weekly during standups. Track progress in the GitHub project board. Escalate blockers immediately.*
