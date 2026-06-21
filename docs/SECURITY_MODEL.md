# Security Model

**Project:** SMEPro COS / Lamar IOS+  
**Version:** 1.0  
**Date:** 2026-06-21  
**Purpose:** Threat model, security controls, compliance requirements, and enforcement mechanisms for the Lamar IOS+ platform.

---

## 1. Threat Model

### Threat Actors

| Actor | Motivation | Capability | Likelihood | Impact |
|-------|------------|------------|------------|--------|
| **External attacker (criminal)** | Data theft, ransomware, financial gain | High (tools, time, skill) | Medium | High |
| **External attacker (nation-state)** | Espionage, disruption | Very High | Low | Very High |
| **Malicious insider (student)** | Grade manipulation, data access | Low–Medium | Low | Medium |
| **Malicious insider (staff)** | Financial fraud, unauthorized access | Medium | Low | High |
| **Compromised vendor (SMEPro)** | Supply chain attack | Medium | Low | High |
| **Compromised third-party (Banner/Blackboard)** | Lateral movement | Medium | Medium | High |
| **Accidental insider** | Misconfiguration, phishing victim | Medium | High | Medium |

### Attack Scenarios

1. **Data Exfiltration:** Attacker gains access to student PII/FAFSA data and exfiltrates it.
2. **Auth Bypass:** Attacker bypasses SAML/OIDC to impersonate a registrar or dean.
3. **SQL Injection:** Attacker injects SQL via API to access unauthorized records.
4. **Privilege Escalation:** Low-privilege user (advisor) escalates to admin access.
5. **Supply Chain:** Compromised Docker image or dependency introduces malware.
6. **Insider Threat:** Staff member with legitimate access modifies grades or financial aid.
7. **Ransomware:** Attacker encrypts database backups and demands payment.
8. **DDoS:** Attacker floods API gateway, causing denial of service during enrollment.
9. **AI Misuse:** Unapproved AI model generates biased or incorrect compliance decisions.
10. **Audit Tampering:** Attacker modifies evidence chain logs to hide unauthorized actions.

### Trust Boundaries

```
┌─────────────────────────────────────────────────────────────────────┐
│                          INTERNET                                   │
│  (Untrusted — DDoS, scanning, credential stuffing)                │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      DMZ / EDGE LAYER                               │
│  Cloud Armor WAF → HTTPS LB → Ingress Controller                    │
│  TLS termination, rate limiting, geo-blocking, bot detection        │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    APPLICATION LAYER                                │
│  API Gateway → Services (Auth, UDM, Rules, Workflow)                │
│  Kubernetes namespaces, network policies, service mesh              │
│  Auth: SAML/OIDC → JWT → RBAC → Row-level security                │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      DATA LAYER                                     │
│  PostgreSQL (encrypted, HA, PITR)                                 │
│  Redis (encrypted, session cache)                                   │
│  GCS / On-prem storage (encrypted, versioned)                     │
│  Pub/Sub (encrypted, access-controlled)                            │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      AI / ML LAYER                                  │
│  Model training (isolated environment)                            │
│  Inference (sandboxed, explainable, approved models only)         │
│  Governance: approval gate, trace chain, human-in-the-loop        │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. Security Controls

### A. Authentication & Authorization

| Control | Implementation | Enforced By | Verification |
|---------|---------------|-------------|------------|
| **SAML/OIDC Identity** | Lamar SSO (or Google/Azure) | Auth service + Ingress | IdP metadata validation |
| **MFA** | Required for all admin roles | IdP policy | SSO login test |
| **JWT Token Validation** | RS256, short expiry (1h), refresh tokens | API Gateway | Token decode test |
| **RBAC** | Role-based (Advisor, Faculty, Registrar, etc.) | Auth service + DB RLS | Access matrix test |
| **Row-Level Security (RLS)** | PostgreSQL policies per role | Database | SQL query test |
| **Session Management** | Redis-backed, 30-min idle timeout | Auth service + Redis | Session expiry test |
| **Break-glass Access** | Emergency admin account, audit-logged | Manual + Evidence chain | Drill every quarter |

### B. Network Security

| Control | Implementation | Enforced By | Verification |
|---------|---------------|-------------|------------|
| **TLS Everywhere** | TLS 1.3, HSTS, cert pinning | cert-manager + Ingress | SSL Labs test |
| **mTLS (internal)** | Service mesh or sidecar proxies | Istio/Linkerd (future) | Certificate validation |
| **Network Policies** | Default deny, whitelist-only | Kubernetes CNI | `kubectl describe netpol` |
| **WAF** | Cloud Armor (SQLi, XSS, LFI, rate limiting) | GCP Load Balancer | Penetration test |
| **DDoS Protection** | Cloud Armor + rate limiting | GCP Load Balancer | Load test + audit |
| **Egress Filtering** | Allowlist for outbound APIs (AI, connectors) | Network policies | Traffic capture test |
| **VPC Isolation** | Private subnets, no public IPs for DB/Redis | Terraform | Network diagram review |
| **VPN / Interconnect** | On-prem hybrid connectivity | Cloud VPN / Interconnect | Connectivity test |

### C. Data Protection

| Control | Implementation | Enforced By | Verification |
|---------|---------------|-------------|------------|
| **Encryption at Rest** | CMEK (Cloud KMS) for all storage | Terraform + GCP | Encryption key audit |
| **Encryption in Transit** | TLS 1.3 for all connections | cert-manager + Applications | SSL Labs test |
| **Pseudonymization** | PII replaced with tokens at ingestion | Normalization engine | Data sampling audit |
| **Data Classification** | FERPA, public, internal, confidential | Application logic | Classification tag review |
| **Field-Level Encryption** | Sensitive fields encrypted in DB | Application layer | Decryption test |
| **Backup Encryption** | Backups encrypted with separate key | Cloud SQL / pgBackRest | Restore test |
| **Data Retention** | Automated deletion per policy | Application + DB jobs | Retention audit |
| **Data Residency** | US-only (or campus-only for on-prem) | Network policies + storage locations | Geo-audit |

### D. Application Security

| Control | Implementation | Enforced By | Verification |
|---------|---------------|-------------|------------|
| **Input Validation** | Strict schema validation, parameterized queries | Application code + WAF | Fuzz testing |
| **Output Encoding** | Context-aware encoding (HTML, JSON, URL) | Application code | XSS test |
| **CSRF Protection** | Double-submit cookies, SameSite | Application code | CSRF test |
| **Rate Limiting** | Per-IP and per-user limits | API Gateway + Redis | Load test |
| **Security Headers** | CSP, X-Frame-Options, X-Content-Type-Options | Ingress / API Gateway | Header scan |
| **Dependency Scanning** | Snyk, Dependabot, Trivy | CI/CD pipeline | SBOM review |
| **Secret Detection** | git-secrets, truffleHog, GitHub secret scanning | CI/CD + GitHub | Commit scan |
| **Container Hardening** | Non-root user, minimal base image, no shell | Dockerfile + CI/CD | Container scan |
| **Immutable Tags** | Image digests, not mutable tags | CI/CD + Artifact Registry | Tag verification |

### E. AI / ML Security

| Control | Implementation | Enforced By | Verification |
|---------|---------------|-------------|------------|
| **Model Approval Gate** | All models must be approved by governance board | Governance service | Audit log review |
| **Model Provenance** | Training data, code, and config versioned | MLflow + Git | Reproducibility test |
| **Explainability** | SHAP/LIME explanations for all predictions | Explainability service | Output review |
| **Bias Testing** | Demographic parity tests before deployment | ML pipeline | Bias report review |
| **Sandboxed Inference** | Models run in isolated environment | K8s network policies | Network isolation test |
| **Human-in-the-Loop** | All student-affecting decisions require human approval | Workflow engine | Approval log audit |
| **AI Usage Logging** | Every AI inference logged to evidence chain | Evidence chain service | Log audit |
| **Approved APIs Only** | Only pre-approved external AI APIs (OpenAI, Anthropic) | Egress allowlist + approval | API call audit |
| **Context Mediation** | Student PII never sent to external AI; synthetic/masked data only | Normalization engine | Data sampling audit |

### F. Audit & Compliance

| Control | Implementation | Enforced By | Verification |
|---------|---------------|-------------|------------|
| **Immutable Audit Log** | All events to evidence chain (blockchain-backed) | Evidence chain service | Tamper test |
| **Structured Logging** | JSON logs with correlation IDs, user IDs, actions | All services | Log review |
| **Access Reviews** | Quarterly review of all roles and permissions | Compliance service | Access review report |
| **FERPA Compliance** | Pseudonymization, consent tracking, audit trails | Application + DB | FERPA audit |
| **Trace Chain** | Immutable governance event ledger | Blockchain smart contract | Smart contract audit |
| **Log Retention** | 7 years for compliance logs, 90 days for app logs | Cloud Logging + GCS | Retention audit |
| **Alerting on Anomalies** | Unusual access patterns trigger alerts | Monitoring + ML | Alert test |

---

## 3. Compliance Requirements

### FERPA (Family Educational Rights and Privacy Act)

| Requirement | Implementation | Evidence |
|-------------|---------------|----------|
| **Consent for disclosure** | Consent tracking in DB, audit log | `consent_log` table |
| **Directory information opt-out** | Student preference stored, enforced in queries | `student_preferences` table |
| **Access by school officials** | RBAC with legitimate educational interest check | `access_log` table |
| **Record of access** | Every data access logged with timestamp, user, purpose | Evidence chain |
| **Right to inspect** | Student self-service portal (future) | Portal audit log |
| **Right to amend** | Correction workflow with approval chain | `amendment_requests` table |
| **Data security** | Encryption, access controls, pseudonymization | Security scan reports |
| **Third-party sharing** | Contractual controls, data use agreements | `data_sharing_agreements` table |

### Other Applicable Regulations

| Regulation | Relevance | Controls |
|------------|-----------|----------|
| **GLBA** | Financial aid data | Encryption, access controls, audit |
| **HIPAA** | Health center data (if integrated) | BAAs, encryption, access controls |
| **PCI-DSS** | Payment processing (if integrated) | Network segmentation, encryption, audit |
| **Texas Privacy Laws** | Student data in Texas | Data residency, breach notification |
| **State Authorization** | Distance education compliance | Documentation, reporting |
| **NC-SARA** | Interstate distance education | Compliance tracking, reporting |

---

## 4. Security Testing Schedule

| Test Type | Frequency | Tool | Owner | Deliverable |
|-----------|-----------|------|-------|-------------|
| **SAST (Static Analysis)** | Every PR | CodeQL, SonarQube | Dev Team | SARIF report |
| **DAST (Dynamic Analysis)** | Weekly | OWASP ZAP | Security Team | Vulnerability report |
| **Container Scan** | Every build | Trivy, Snyk | DevOps | CVE report |
| **Dependency Scan** | Daily | Dependabot, Snyk | DevOps | Dependency audit |
| **Secret Scan** | Every commit | GitHub secret scanning, git-secrets | DevOps | Secret scan report |
| **Penetration Test** | Quarterly | Third-party or internal | Security Team | Pen test report |
| **Compliance Audit** | Annually | Internal + external | Compliance | FERPA audit report |
| **Fuzz Testing** | Monthly | AFL, Burp Suite | Security Team | Fuzz results |
| **Load / DDoS Test** | Quarterly | k6, Locust | Performance Team | Load test report |
| **Social Engineering** | Annually | Phishing simulation | Security Team | Training results |
| **Tabletop Exercise** | Quarterly | Scenario-based | Leadership | Exercise report |

---

## 5. Incident Response — Security Specific

### Security Incident Categories

| Category | Examples | Response Priority |
|----------|----------|-------------------|
| **Data Breach** | Unauthorized access to FERPA data | P1 — Immediate |
| **Ransomware** | Encryption of data or backups | P1 — Immediate |
| **Insider Threat** | Staff misuse of privileges | P1 — Immediate |
| **Malware** | Compromised container or host | P1 — Immediate |
| **Credential Compromise** | Leaked password, API key, or cert | P2 — Urgent |
| **DDoS** | Service unavailable due to traffic | P2 — Urgent |
| **Vulnerability Exploitation** | Active exploitation of known CVE | P2 — Urgent |
| **Supply Chain** | Compromised dependency or image | P2 — Urgent |
| **Phishing** | User credentials stolen | P3 — High |
| **Misconfiguration** | Exposed database, open S3 bucket | P3 — High |

### Security Incident Response Steps

1. **Contain** (first 15 minutes)
   - Isolate affected systems (network policies, firewall rules)
   - Revoke compromised credentials
   - Block malicious IPs
   - Preserve evidence (snapshots, logs, memory dumps)

2. **Eradicate** (15–60 minutes)
   - Remove malware / backdoors
   - Patch exploited vulnerabilities
   - Rotate all potentially compromised secrets
   - Rebuild affected containers from clean base

3. **Recover** (1–4 hours)
   - Restore from clean backup (if needed)
   - Verify system integrity
   - Re-enable services with monitoring
   - Verify no persistence mechanisms remain

4. **Report** (within 24 hours)
   - FERPA breach notification (if applicable)
   - Texas breach notification (if applicable)
   - Internal leadership notification
   - SMEPro notification (if vendor compromise)
   - Law enforcement (if criminal activity)

5. **Post-Incident** (within 48 hours)
   - Forensic analysis
   - Root cause documentation
   - Control gap analysis
   - Remediation plan
   - Training update (if human error)

---

## 6. Roles & Responsibilities

| Role | Security Responsibilities |
|------|--------------------------|
| **Lamar CISO / Security Lead** | Overall security posture, compliance, incident authority |
| **Lamar IT Leadership** | Infrastructure security, budget, vendor management |
| **Lamar Dev Team** | Secure coding, SAST/DAST, vulnerability remediation |
| **Lamar Ops Team** | Network security, monitoring, incident response, backups |
| **Lamar Compliance Officer** | FERPA audits, regulatory reporting, training |
| **SMEPro Architect** | Security architecture review, threat model updates |
| **SMEPro Dev Team** | Secure development, dependency updates, patch delivery |
| **SMEPro Support** | Security incident support, forensic assistance |

---

## 7. Security Baselines

### Minimum Viable Security (Wave 1)

Before Wave 1 goes live, these must be in place:

- [ ] TLS 1.3 on all external and internal endpoints
- [ ] SAML/OIDC auth with MFA for admin roles
- [ ] RBAC enforced in application and database
- [ ] Network policies (default deny) in Kubernetes
- [ ] WAF with SQLi, XSS, and rate limiting rules
- [ ] Secrets in Secret Manager / Vault (none in repo)
- [ ] Container scanning in CI/CD (block critical CVEs)
- [ ] Structured logging with correlation IDs
- [ ] Immutable audit trail (evidence chain)
- [ ] Backup encryption and tested restore
- [ ] PII pseudonymization at ingestion
- [ ] Security headers on all web responses
- [ ] Dependency scanning (Dependabot + Snyk)
- [ ] Incident response runbook accessible to on-call

### Enhanced Security (Wave 2+)

- [ ] Service mesh with mTLS (Istio/Linkerd)
- [ ] Runtime security (Falco, PodSecurityPolicy)
- [ ] Advanced threat detection (Chronicle, Splunk)
- [ ] Automated security posture management (SCC, CSPM)
- [ ] AI governance automation (approval gates, bias detection)
- [ ] Blockchain-backed evidence chain
- [ ] Zero-trust network architecture
- [ ] HSM for key management (if regulatory requirement)

---

*This security model is a living document. Update it after every security incident, quarterly threat model review, and annual compliance audit.*
