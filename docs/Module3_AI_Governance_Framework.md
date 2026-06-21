# Module 3: AI Governance Framework
## SMEPro COS — Algorithmic Accountability & Risk Management
## Version: 2026.06.20-LAMAR-MOD3-1.0
## Date: 2026-06-20

---

## 1. Executive Summary

Module 3 provides the **governance layer** for all AI/ML systems deployed at Lamar University. It ensures that the operational intelligence engines built in Module 2 (UC-01 through UC-08) operate within a framework of **accountability, transparency, fairness, and human oversight**.

**Key Principles:**
- **Human-in-the-loop always** — No automated decision affecting individual students without human review
- **Explainability by default** — Every high-risk prediction must be explainable (SHAP, LIME, or equivalent)
- **Bias audits annually** — All student-facing systems audited for disparate impact on protected classes
- **Risk tiering** — Minimal → Limited → High → Unacceptable, with escalating governance requirements
- **Trace chain immutability** — All incidents, audits, and regulatory changes deployed to blockchain for audit-proof evidence
- **NIST AI RMF alignment** — Govern, Map, Measure, Manage functions mapped to every system

---

## 2. Regulatory Landscape

### 2.1 NIST AI Risk Management Framework (AI RMF) 1.0

| Function | Sub-function | Module 3 Implementation |
|----------|-------------|----------------------|
| **GOVERN** | GOVERN-1.1: Policies established | `ai_system_inventory` — every system registered with owner, department, risk tier |
| | GOVERN-1.2: Accountability assigned | `system_owner` + `technical_contact` mandatory; risk owner in `model_risk_register` |
| | GOVERN-3.1: Workforce diversity | Bias audits on protected attributes; training on algorithmic fairness |
| | GOVERN-5.1: Incident response | `ai_incident_log` with auto-escalation; CRITICAL → CCO within 4 hours |
| | GOVERN-5.2: Third-party risk | `third_party_ai_assessment` pre-procurement mandatory; annual review |
| **MAP** | MAP-1.1: Context identified | `model_risk_register` documents context, stakeholders, and use cases |
| | MAP-1.2: Risk tolerance | Risk scores 1-25; thresholds defined for each tier |
| **MEASURE** | MEASURE-1.1: Appropriate methods | `model_lifecycle_events` tracks validation, drift detection, retraining |
| | MEASURE-2.1: Bias evaluation | `bias_audit_log` with EEOC 80% rule; demographic parity monitoring |
| | MEASURE-2.2: Explainability | `explainability_log` with SHAP/LIME; human review required |
| | MEASURE-3.1: Tracking incidents | `ai_incident_log` with severity, escalation, and remediation |
| **MANAGE** | MANAGE-1.1: Risk treated | `model_risk_register` with mitigation plans and residual risk |
| | MANAGE-2.1: Regular review | Quarterly risk assessment; annual bias audit; pre-deployment review |
| | MANAGE-3.1: Response communicated | Incident response with external notification (ED-OCR, FTC, state AG) |

### 2.2 EU AI Act (Reference for US Institutions)

While Lamar is a US institution, the EU AI Act provides the **global gold standard** for AI governance. Module 3 maps all systems to EU AI Act classes as a **reference framework** for institutional policy.

| EU AI Act Class | Definition | Lamar Systems | Governance Requirements |
|-----------------|------------|---------------|------------------------|
| **Minimal Risk** | Basic AI (spam filters, inventory management) | None at Lamar | Voluntary transparency |
| **Limited Risk** | Chatbots, emotion recognition | CoPilot (assistive) | Disclosure obligations |
| **High Risk** | Critical infrastructure, education, employment | UC-01 (Persistence), UC-03 (Accreditation), UC-06 (AI-Grader), UC-08 (Compliance) | Conformity assessment, risk management, data governance, transparency, human oversight, accuracy testing, bias audits, CE marking (if applicable) |
| **Prohibited** | Social scoring, manipulation, biometric mass surveillance | None at Lamar | Absolute ban |

### 2.3 US Federal & State Requirements

| Regulation | Applicability | Module 3 Control |
|------------|--------------|------------------|
| **FERPA** | All student education records | `fERPA_applicable` flag; data retention 7 years; role-based access; encryption |
| **Title IX / ED-OCR** | Gender equity in education | Bias audits on gender; incident escalation to Title IX coordinator |
| **EEOC Disparate Impact** | Employment and educational decisions | `bias_audit_log` with 80% rule; demographic parity monitoring |
| **Texas Data Privacy Act** | Texas residents' personal data | `pii_involved` flag; data minimization; consent tracking |
| **FTC Section 5** | Unfair/deceptive practices | `third_party_ai_assessment` pre-procurement; vendor transparency requirements |
| **State AG Enforcement** | State-level consumer protection | External notification pipeline for Texas AG; compliance monitoring |

---

## 3. AI System Inventory

### 3.1 Inventory Requirements

**Every AI/ML system** — built internally or procured — must be registered in `ai_system_inventory` before deployment.

| Field | Requirement | Example |
|-------|-------------|---------|
| `system_name` | Unique, descriptive | "Predictive Persistence Model (UC-01)" |
| `system_owner` | Named individual with authority | "Student Success Director" |
| `system_owner_department` | Budget authority | "Student Success Center" |
| `technical_contact` | Day-to-day operations | "Data Analytics Team" |
| `vendor_name` | If third-party | "Anthropic (AVA)" |
| `data_sources` | JSON array of source systems | `["Banner SIS", "Blackboard Ultra"]` |
| `output_destinations` | JSON array of consumers | `["Advisor Dashboard", "CoPilot"]` |
| `model_type` | ENUM | `predictive_model`, `nlp_model`, `generative_model`, etc. |
| `risk_tier` | Dynamic (can change) | `high` (student-facing, high impact) |
| `eu_ai_act_class` | Reference mapping | `minimal`, `limited`, `high_risk`, `prohibited` |
| `nist_ai_rmf_governance_map` | JSON mapping to NIST functions | `{"govern": ["GOVERN-1.1"], ...}` |
| `human_in_the_loop_required` | BOOLEAN | `TRUE` for all student-facing systems |
| `human_in_the_loop_description` | Specific oversight mechanism | "Advisors review Red-tier students before intervention" |

### 3.2 Lamar's AI Systems (Current)

| System | UC | Model Type | Risk Tier | Status | Human-in-the-Loop |
|--------|----|-----------|-----------|--------|-------------------|
| Predictive Persistence Model | UC-01 | Predictive | **High** | Production | Advisors review all Red-tier students |
| Transcript Crosswalk NLP | UC-02 | NLP | Limited | Production | Registrar reviews all recommendations |
| Accreditation Gap Analyzer | UC-03 | NLP | **High** | Pilot | Accreditation Officer reviews all verdicts |
| Outcome Alignment Auditor | UC-04 | Classification | Limited | Production | Chairs review flagged courses |
| Grading Load Analyzer | UC-05 | Predictive | Limited | Production | Chairs review GLI recommendations |
| AI-Grader Routing Engine | UC-06 | Recommendation | **High** | Pilot | Lead Professor retains final grade authority |
| Enrollment Funnel Analytics | UC-07 | Predictive | Limited | Production | Admissions team uses aggregate insights only |
| Continuous Compliance Monitoring | UC-08 | Anomaly Detector | **High** | Production | Compliance Officer reviews all CRITICAL/HIGH alerts |
| Anthropic AVA (Third-Party) | — | Generative | **High** | Pilot | Professor reviews all feedback before release |

---

## 4. Risk Management

### 4.1 Risk Tiering Framework

| Tier | Risk Score | Requirements | Review Frequency |
|------|-----------|--------------|------------------|
| **Minimal** | 1-4 | Annual inventory review | Annual |
| **Limited** | 5-9 | Annual risk assessment; bias audit every 2 years | Annual |
| **High** | 10-19 | Quarterly risk assessment; annual bias audit; explainability log; human-in-the-loop mandatory | Quarterly |
| **Unacceptable** | 20-25 | Immediate suspension review; CCO notification; Board notification; external legal review | Immediate |

### 4.2 Risk Categories

| Category | Description | Example at Lamar |
|----------|-------------|-----------------|
| **Algorithmic Bias** | Disparate impact on protected groups | Persistence model flags more Black students as high-risk |
| **Data Privacy** | Unauthorized access or misuse of student data | FERPA breach of persistence model data |
| **Model Drift** | Performance degradation over time | Persistence model accuracy drops after curriculum change |
| **Adversarial Attack** | Manipulation of model inputs | Student artificially inflates BB login count to avoid Red tier |
| **Lack of Explainability** | Inability to explain predictions to stakeholders | AVA feedback cannot be explained to student on appeal |
| **Overreliance** | Humans defer to model without critical thinking | Advisors only contact Red-tier students, ignore Yellow |
| **Third-Party Dependency** | Vendor outage, price change, or contract termination | Anthropic AVA API outage during finals week |
| **Regulatory Noncompliance** | Failure to meet applicable regulations | Compliance monitoring misses state emergency order |
| **Reputational** | Public trust damage from AI failure | Media coverage of biased persistence model |
| **Financial** | Direct monetary loss from AI failure | Incorrect AI grading causes tuition refund |
| **Operational** | Disruption of business operations | AI-Grader system failure during peak grading period |
| **Safety** | Physical or psychological harm | AI counseling chatbot gives harmful advice |

### 4.3 Risk Register Example

**System:** Predictive Persistence Model (UC-01) — UCO-MOD3-0001

| Risk ID | Category | Description | Likelihood | Impact | Score | Mitigation | Residual | Status |
|---------|----------|-------------|------------|--------|-------|------------|----------|--------|
| R1 | Algorithmic Bias | Model disproportionately flags underrepresented groups | 3 | 4 | 12 | Annual bias audits; demographic parity monitoring; advisor override | 6 | Open |
| R2 | Overreliance | Advisors defer to model without individual context | 4 | 3 | 12 | Mandatory training; case review; intervention documentation | 6 | Open |
| R3 | Data Privacy | FERPA breach of student activity data | 2 | 5 | 10 | Encryption; RBAC; annual security audit; 7-year retention | 4 | Open |

---

## 5. Bias Auditing

### 5.1 Audit Requirements

| System Tier | Audit Frequency | Attributes | Methodology |
|-------------|----------------|------------|-------------|
| Minimal | Every 2 years | Combined | Self-assessment |
| Limited | Annual | Race, Gender | Aequitas or Fairlearn |
| High | Annual + pre-deployment | All protected classes | Independent third-party audit |
| Unacceptable | Immediate + quarterly | All protected classes | Independent third-party + legal review |

### 5.2 Protected Attributes

| Attribute | Audit Metric | Threshold | Source |
|-----------|-------------|-----------|--------|
| **Race** | Disparate Impact Ratio | ≥ 0.80 | EEOC 80% rule |
| **Gender** | Demographic Parity Difference | ≤ 0.05 | NIST AI RMF |
| **Age** | Equal Opportunity Difference | ≤ 0.05 | NIST AI RMF |
| **Disability** | Predictive Parity | ≤ 0.05 | NIST AI RMF |
| **Socioeconomic Status** | Calibration by Group | ≤ 0.05 | Institutional policy |
| **Combined** | Equalized Odds | ≤ 0.05 | NIST AI RMF |

### 5.3 Audit Workflow

1. **Schedule:** `fn_schedule_bias_audit()` creates audit record 30 days in advance
2. **Sample:** Auditor extracts data from `sample_date_range` (minimum 1,000 records or full population if smaller)
3. **Calculate:** Run Aequitas/Fairlearn metrics on protected attributes
4. **Evaluate:** Compare against thresholds (EEOC 80% rule = 0.80)
5. **Verdict:** PASS (≥ threshold), WARNING (0.75-0.79), FAIL (< 0.75)
6. **Remediate:** If FAIL, remediation plan required within 30 days; system may be suspended
7. **Update:** `trg_audit_completion_update()` updates `next_bias_audit_date` to +1 year

---

## 6. Explainability & Interpretability

### 6.1 Explainability Requirements

| System Tier | Method | Log | Human Review |
|-------------|--------|-----|--------------|
| Minimal | Feature importance | Optional | Optional |
| Limited | SHAP or LIME | Required | For appeals |
| High | SHAP + counterfactual + rule extraction | Required | Mandatory for all predictions affecting individuals |
| Unacceptable | SHAP + LIME + counterfactual + human-readable narrative | Required | Mandatory + independent review |

### 6.2 Example: Persistence Model Explanation

**Student:** SYN-12345  
**Prediction:** Red tier (composite score: 34)  
**Explanation Method:** SHAP  
**Top Factors:**
- `bb_login_count`: -2.1 z-score (35% weight) — "No Blackboard login in 7 days"
- `bb_assignment_submissions`: -1.8 z-score (28% weight) — "2 missing assignments"
- `touchnet_payment_activity`: -1.5 z-score (20% weight) — "Tuition payment overdue"

**Advisor Action:** Phone call to student with Financial Aid and Student Success Center referrals.

**Human Review:** Advisor notes: "Student answered. Cited financial stress and work schedule conflict. Referred to Financial Aid and Student Success Center. Follow-up scheduled 2025-09-22."

---

## 7. Incident Management

### 7.1 Incident Classification

| Severity | Definition | Response Time | Escalation | Example |
|----------|------------|---------------|------------|---------|
| **CRITICAL** | Immediate harm to students; legal exposure; regulatory violation | 4 hours | CCO + General Counsel + Board | Bias complaint from 45 students; ED-OCR investigation |
| **HIGH** | Significant operational impact; potential harm | 24 hours | CCO | Model drift causes 20% false positive rate in persistence |
| **MEDIUM** | Limited impact; contained | 72 hours | System Owner | Explainability log failure for 3 days |
| **LOW** | Minor issue; no immediate impact | 5 business days | Technical Contact | Vendor API latency spike |
| **INFO** | Observation; no action required | N/A | None | Model performance within expected variance |

### 7.2 Incident Response Workflow

1. **Detect:** Automated monitoring or human report
2. **Register:** `fn_register_ai_incident()` — auto-escalates CRITICAL
3. **Assess:** CCO reviews severity and affected individuals within response time
4. **Contain:** Immediate mitigation (suspend model, switch to human review, etc.)
5. **Investigate:** Root cause analysis documented in `root_cause_analysis`
6. **Remediate:** Fix documented in `remediation_actions`; owner assigned
7. **Verify:** Independent verification that fix is effective
8. **Close:** Incident marked resolved; `trace_chain_tx_hash` recorded
9. **Learn:** Post-incident review with system owner, technical contact, and CCO

---

## 8. Third-Party AI Assessment

### 8.1 Pre-Procurement Requirements

Before any third-party AI tool is deployed:

| Requirement | Evidence | Owner |
|-------------|----------|-------|
| Vendor security audit | SOC 2 Type II report | CISO |
| Data processing agreement | BAA (if FERPA) or DPA | General Counsel |
| Model cards / documentation | Vendor-provided model cards | Technical Contact |
| Bias audit | Vendor bias audit report or independent assessment | Compliance Officer |
| Explainability | Vendor explanation of model logic | Technical Contact |
| Exit strategy | Data portability plan; model extraction | Procurement |
| Contract terms | SLA ≥ 99.9%; price caps; termination rights | Procurement |

### 8.2 Annual Vendor Review

| Assessment Type | Frequency | Trigger for Action |
|-----------------|-----------|-------------------|
| Security audit | Annual | Any critical finding → contract renegotiation |
| Bias audit | Annual | FAIL → suspension or termination |
| Performance review | Quarterly | SLA breach 2× consecutive → vendor review |
| Contract renewal | Annual | Conditional or Rejected → renegotiate or replace |

---

## 9. Model Lifecycle Management

### 9.1 Lifecycle Stages

```
┌─────────────────────────────────────────────────────────────────────┐
│  CONCEPT → DEVELOPMENT → VALIDATION → PILOT → PRODUCTION → RETIRE │
│                                                                     │
│  CONCEPT:    Business case; risk assessment; UCO_NODE_ID assigned   │
│  DEVELOPMENT: Training; initial testing; bias audit (pre-deployment)│
│  VALIDATION: Independent testing; holdout validation; explainability│
│  PILOT:      Limited deployment (1 department); 90-day monitoring  │
│  PRODUCTION: Full deployment; quarterly review; annual bias audit   │
│  RETIRE:     Data archival; model artifact preservation; incident  │
│              history retained for 7 years (FERPA)                   │
└─────────────────────────────────────────────────────────────────────┘
```

### 9.2 Stage Gates

| Gate | Requirement | Approval |
|------|-------------|----------|
| **Development → Validation** | Model passes internal testing; initial bias audit clean | Technical Contact + System Owner |
| **Validation → Pilot** | Independent validation complete; explainability verified; risk register populated | System Owner + CCO |
| **Pilot → Production** | 90-day pilot metrics met; no CRITICAL incidents; user feedback positive | System Owner + CCO + Provost (for High-risk) |
| **Production → Retirement** | Business case no longer valid; replacement deployed; data archived | System Owner + CCO + Records Manager |

---

## 10. Governance Roles & Responsibilities

| Role | Responsibility | Authority |
|------|---------------|-----------|
| **Board of Regents** | Ultimate oversight; policy approval; major incident review | Approve AI governance policy; review CRITICAL incidents |
| **President** | Institutional accountability; external representation | Delegate authority to CCO |
| **Provost** | Academic AI systems; faculty affairs; student success | Approve High-risk academic systems; suspend if needed |
| **Chief Compliance Officer (CCO)** | Day-to-day governance; incident response; regulatory liaison | Escalate CRITICAL incidents; mandate bias audits; suspend systems |
| **General Counsel** | Legal risk; contract review; external notification | Approve third-party contracts; authorize ED-OCR/FTC notification |
| **CISO** | Data security; access control; breach response | Revoke system access; mandate security patches |
| **System Owner** | Business case; user training; risk acceptance | Approve pilot → production; accept residual risk |
| **Technical Contact** | Model operations; monitoring; maintenance | Deploy patches; trigger retraining; generate reports |
| **Compliance Officer** | Audit coordination; regulatory monitoring; policy enforcement | Schedule audits; review findings; enforce remediation |
| **Data Analytics Team** | Model development; data engineering; explainability | Build models; maintain pipelines; generate SHAP/LIME outputs |
| **External Auditor** | Independent bias audits; security assessments; compliance reviews | Issue PASS/FAIL; recommend suspension |

---

## 11. Dashboards & Reporting

### 11.1 Executive Dashboard (v_ai_system_risk_summary)

| Widget | Metric | Audience |
|--------|--------|----------|
| System Risk Posture | Total systems by risk tier | Board / President |
| Overdue Assessments | Count of systems with overdue risk assessments or bias audits | CCO |
| Open Incidents | CRITICAL and HIGH incidents by age | CCO / General Counsel |
| Failed Audits | Systems with failed bias audits requiring remediation | Compliance Officer |
| High-Risk Systems | All systems in High or Unacceptable tier | Provost / CCO |

### 11.2 Operational Dashboard (v_ai_incident_open)

| Column | Description |
|--------|-------------|
| Incident ID | UUID for tracking |
| System Name | Affected system |
| Severity | CRITICAL / HIGH / MEDIUM / LOW |
| Days Open | Age of incident |
| Escalation To | Current escalation level |
| External Notification Required | ED-OCR / FTC / State AG |

### 11.3 Compliance Dashboard (v_bias_audit_overdue)

| Column | Description |
|--------|-------------|
| System Name | System requiring audit |
| Days Overdue | Age of overdue audit |
| Risk Tier | Current risk classification |
| Owner | Responsible party |

---

## 12. Integration with Module 1 & Module 2

### 12.1 Module 1 → Module 3
- **Regulatory changes detected by UC-08** may trigger updates to AI governance policies (e.g., new state law requiring bias audits for public university AI systems)
- **12 agency marts** provide historical data for bias audit baselines and trend analysis
- **Canonical definitions** ensure consistent counting across risk metrics and audit samples

### 12.2 Module 2 → Module 3
- **Every UC-01 through UC-08 system** is registered in `ai_system_inventory` with UCO_NODE_ID mapping
- **Module 2 predictions** are logged in `explainability_log` with SHA-256 hashed input features
- **Module 2 incidents** (e.g., incorrect persistence flag, flawed crosswalk recommendation) are registered in `ai_incident_log`
- **Module 2 bias** (e.g., disparate impact in persistence model) is tracked in `bias_audit_log`
- **Module 2 lifecycle** (model updates, drift detection, retraining) is tracked in `model_lifecycle_events`

### 12.3 Module 3 → Module 2
- **Risk tier changes** in Module 3 may trigger suspension or modification of Module 2 systems
- **Failed bias audits** may require model retraining or feature engineering in Module 2
- **Incident remediation** may require updates to Module 2 ETL pipelines or model logic
- **Governance policy changes** (e.g., new FERPA guidance) may require Module 2 data handling updates

---

## 13. Files & Deliverables

| File | Path | Description |
|------|------|-------------|
| PostgreSQL Schema | `ios-plus/db/migrations/V14__module3_ai_governance.sql` | 1 schema, 7 tables, 4 views, 3 functions, 2 triggers, 9 systems seeded, 6 risks seeded |
| AI Governance Framework | `ios-plus/docs/Module3_AI_Governance_Framework.md` | This file — NIST AI RMF, EU AI Act, risk management, bias audit, incident response, lifecycle, roles, dashboards |

---

*End of AI Governance Framework.*
