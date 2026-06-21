# SMEPro COS Architecture v2 — Deployment Specification
## Formal Engineering Architecture
## Version: 2026.06.20-LAMAR-ARCH-v2.0
## Date: 2026-06-20

---

## 1. Executive Summary

This document is the **formal deployment architecture** for the SMEPro Compliance Operating System (COS) at Lamar University. It addresses three architectural clarifications identified during design review:

1. **Connector taxonomy** — Three distinct source bands, not one generic "API connectors" layer
2. **On-prem engine decomposition** — Execution/runtime layer added inside the trust boundary
3. **Governed AI orchestration** — Copilot and AI tools consume bounded context, not free-standing intelligence

The architecture is **buyer-legible** (for board/leadership review) and **engineer-credible** (for implementation).

---

## 2. Source Bands (3-Tier Cloud Row)

### 2.1 Band A: Campus Systems (Institutional Data)

| System | Connection | Protocol | Data Direction | Authentication |
|--------|-----------|----------|--------------|----------------|
| **Banner** (Student, FinAid, Finance, HR) | Ethos API + Oracle CDC | REST / JDBC | Pull + Change Data Capture | OAuth 2.0 + institution cert |
| **Blackboard Ultra** (LMS) | Blackboard REST API | REST / LTI 1.3 | Pull (grades, assignments, logins) | OAuth 2.0 + API key |
| **Concourse** (Syllabus) | Concourse API + SFTP | REST / SFTP | Pull (syllabus text, CLO mappings) | API key + SFTP key |
| **TouchNet** (Payments) | TouchNet API | REST | Pull (payment status, due dates) | OAuth 2.0 |
| **StarRez** (Housing) | StarRez API | REST | Pull (housing assignments, occupancy) | API key |
| **PeopleSoft** (TSUS) | PeopleSoft Integration Broker | REST / SOAP | Pull (AFR, budget, audit data) | WS-Security |
| **Cayuse** (Research) | Cayuse API | REST | Pull (proposals, awards, IRB) | OAuth 2.0 |
| **Omnigo** (Safety) | Omnigo API | REST | Pull (incidents, daily logs) | API key |
| **TeamMate** (Audit) | TeamMate API | REST | Pull (audit findings, workpapers) | OAuth 2.0 |
| **CITI** (Training) | CITI API | REST | Pull (training completion, certificates) | API key |
| **NSC** (Clearinghouse) | NSC StudentTracker | SFTP / API | Pull (enrollment verification) | SFTP key |
| **SEVIS** (ICE) | SEVIS API | REST | Pull (international student status) | DHS cert |

**Connector Class:** `InstitutionalSystemConnector`  
**Pattern:** Scheduled pull (nightly) + CDC (real-time for critical events) + webhook (for async events)  
**Normalization:** Raw data → Staging tables → Canonical definitions → Agency marts

### 2.2 Band B: Public Regulatory Sources (Rules & Standards)

| Source | Connection | Protocol | Data Direction | Check Frequency |
|--------|-----------|----------|--------------|-----------------|
| **Federal Register** | Firecrawl MCP + Claude MCP | HTTP scrape + NLP | Pull (regulatory text) | Every 60 minutes |
| **Texas Register** | Firecrawl MCP | HTTP scrape | Pull (state rules) | Every 120 minutes |
| **IPEDS Data Center** | NCES API | REST | Pull (survey forms, definitions) | Annual (manual trigger) |
| **THECB CBM Manuals** | Firecrawl / Manual upload | HTTP + SFTP | Pull (reporting specs) | Annual + on change |
| **Clery Handbook** | ED website + Firecrawl | HTTP scrape | Pull (guidance updates) | Weekly |
| **SACSCOC Standards** | Manual upload + NLP index | PDF parse | Pull (accreditation criteria) | On update |
| **AACSB Standards** | Manual upload + NLP index | PDF parse | Pull (AoL requirements) | On update |
| **ABET Criteria** | Manual upload + NLP index | PDF parse | Pull (program criteria) | On update |
| **ACEN Standards** | Manual upload + NLP index | PDF parse | Pull (nursing standards) | On update |
| **CCNE Standards** | Manual upload + NLP index | PDF parse | Pull (nursing standards) | On update |
| **NCSBN** | nursys.com API | REST | Pull (compact status, licensure rules) | Monthly |
| **DEA Diversion** | DEA website + Firecrawl | HTTP scrape | Pull (controlled substance rules) | Weekly |
| **TX BON** | Texas Board of Nursing website | HTTP scrape | Pull (program approval rules) | Weekly |
| **eNLC / IMLC / PSYPACT** | Compact websites | HTTP scrape | Pull (member status changes) | Monthly |
| **Court Dockets** | PACER / State court feeds | API / RSS | Pull (litigation affecting higher ed) | Daily |

**Connector Class:** `RegulatorySourceConnector`  
**Pattern:** Web scrape → NLP extraction → Change detection → UDM impact mapping → Human approval queue → Rule update  
**Key Control:** No automated rule deployment. All detected changes go to **approval queue** before landing in canonical layer.

### 2.3 Band C: Governed AI Services (Orchestrated Intelligence)

| Service | Connection | Protocol | Data Direction | Governance Control |
|---------|-----------|----------|--------------|-------------------|
| **Microsoft Copilot** | Microsoft Graph API | REST / Graph | Push (context) + Pull (synthesis) | Bounded context only; no direct DB access |
| **Claude MCP** | Anthropic API | REST / SSE | Push (prompts) + Pull (responses) | Role-lens filtering; no PII in prompts |
| **Firecrawl MCP** | Firecrawl API | REST | Push (URLs) + Pull (scraped content) | URL whitelist; no institutional data sent |
| **Anthropic AVA** (Third-Party) | Anthropic API + Blackboard LTI | REST / LTI | Push (student submissions) + Pull (feedback) | Professor approval gate; BAA in place |
| **SHAP / LIME Explainability** | Local Python service | Internal API | Pull (model predictions) + Push (explanations) | Runs on-prem; no external data sent |
| **BERT / NLP Models** | Local Python service (Hugging Face) | Internal API | Pull (text) + Push (embeddings, classifications) | Runs on-prem; no external API calls |

**Connector Class:** `GovernedAIServiceConnector`  
**Pattern:** Orchestration layer receives user query → resolves allowed context via RBAC → fetches cited nodes from UDM → constructs bounded prompt → calls AI service → receives response → logs with references → presents to user  
**Key Control:** AI services **never** have direct database access. All context is mediated by the orchestration layer.

---

## 3. On-Prem IOS+ Engine (5-Layer Decomposition)

### 3.1 Layer 1: Connector Ingestion Services

```
┌─────────────────────────────────────────────────────────────────┐
│  CONNECTOR INGESTION SERVICES                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐│
│  │  Banner     │  │  Blackboard │  │  Regulatory Scrape      ││
│  │  Worker     │  │  Worker     │  │  Worker (Firecrawl)     ││
│  │  (nightly)  │  │  (nightly)  │  │  (every 15-60 min)      ││
│  └─────────────┘  └─────────────┘  └─────────────────────────┘│
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐│
│  │  Concourse  │  │  TouchNet   │  │  Claude MCP             ││
│  │  Worker     │  │  Worker     │  │  Worker                 ││
│  └─────────────┘  └─────────────┘  └─────────────────────────┘│
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐│
│  │  CDC Stream │  │  Webhook    │  │  AI Orchestration       ││
│  │  Listener   │  │  Receiver   │  │  Gateway                ││
│  └─────────────┘  └─────────────┘  └─────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

**Services:**
- `connector-worker-banner` — Scheduled ETL + CDC listener
- `connector-worker-blackboard` — REST API polling + LTI event listener
- `connector-worker-concourse` — SFTP + API polling
- `connector-worker-touchnet` — REST API polling
- `connector-worker-starrez` — REST API polling
- `connector-worker-regulatory` — Firecrawl MCP scheduling + change detection
- `connector-worker-ai-orchestration` — Claude MCP / Copilot context management
- `connector-cdc-listener` — Debezium/Kafka for real-time change capture
- `connector-webhook-receiver` — Async event ingestion

**Technology:** Apache Kafka (event bus), Debezium (CDC), Apache Airflow (scheduling), Python (custom workers), Go (high-throughput connectors)

### 3.2 Layer 2: Normalization & Canonical Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│  NORMALIZATION & CANONICAL PIPELINE                           │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │  Staging Tables │→ │  Data Quality   │→ │  Canonical      ││
│  │  (raw import)   │  │  Engine         │  │  Definitions    ││
│  └─────────────────┘  └─────────────────┘  └─────────────────┘│
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │  Entity         │→ │  Cross-Mart     │→ │  Agency         ││
│  │  Resolution     │  │  Validation     │  │  Data Marts     ││
│  │  (deduplication)│  │  (consistency)  │  │  (12 marts)     ││
│  └─────────────────┘  └─────────────────┘  └─────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

**Services:**
- `normalization-service` — Raw data → clean, typed, validated staging tables
- `data-quality-engine` — Great Expectations / dbt tests on staging data
- `canonical-builder` — Staging → 17 canonical definitions (student, course, instructor, etc.)
- `entity-resolution-service` — Probabilistic matching (SYN IDs, person IDs, course IDs)
- `cross-mart-validator` — Ensures consistency across 12 agency marts (e.g., same student count in IPEDS and Title IV)
- `mart-builder` — Canonical definitions → 12 agency-shaped marts with agency-specific transforms

**Technology:** dbt (data transformations), Great Expectations (data quality), Apache Spark (entity resolution at scale), PostgreSQL (storage)

### 3.3 Layer 3: Rules, Workflow & Approval Engine

```
┌─────────────────────────────────────────────────────────────────┐
│  RULES, WORKFLOW & APPROVAL ENGINE                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │  Business Rules │  │  Approval       │  │  Policy         ││
│  │  Engine (Drools)│  │  Queue Service  │  │  Enforcement    ││
│  └─────────────────┘  └─────────────────┘  └─────────────────┘│
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │  Workflow       │  │  Notification   │  │  Trace Chain    ││
│  │  Orchestrator   │  │  Service        │  │  Deployment     ││
│  │  (Camunda)      │  │  (email/Slack)  │  │  Service        ││
│  └─────────────────┘  └─────────────────┘  └─────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

**Services:**
- `rules-engine` — Drools / DRL for business rules (e.g., "if disparate impact ratio < 0.80, flag for review")
- `approval-queue-service` — Human-in-the-loop approval workflows (UC-08 regulatory changes, UC-06 AI-grader tier assignments)
- `policy-enforcement-service` — RBAC, data residency, retention policy enforcement
- `workflow-orchestrator` — Camunda / Temporal for long-running workflows (e.g., accreditation evidence gathering, bias audit remediation)
- `notification-service` — Email, Slack, SMS alerts for approvals, incidents, overdue audits
- `trace-chain-deployer` — Blockchain deployment for immutable audit trails (regulatory changes, incident logs, bias audit results)

**Technology:** Drools (rules), Camunda (workflows), Temporal (orchestration), Ethereum/Trace chain (immutable logging), SendGrid/Slack (notifications)

### 3.4 Layer 4: Scoring, Analytics & ML Jobs

```
┌─────────────────────────────────────────────────────────────────┐
│  SCORING, ANALYTICS & ML JOBS                                   │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │  Persistence    │  │  Transcript     │  │  Accreditation  ││
│  │  Model (UC-01)  │  │  NLP (UC-02)    │  │  NLP (UC-03)    ││
│  │  (Python/Spark) │  │  (BERT)         │  │  (BERT)         ││
│  └─────────────────┘  └─────────────────┘  └─────────────────┘│
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │  Alignment      │  │  Grading Load   │  │  AI-Grader      ││
│  │  Auditor (UC-04)│  │  Analyzer (UC-05)│  │  Router (UC-06) ││
│  │  (Python)       │  │  (Python)       │  │  (Python + AVA) ││
│  └─────────────────┘  └─────────────────┘  └─────────────────┘│
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │  Enrollment     │  │  Compliance     │  │  Explainability ││
│  │  Funnel (UC-07) │  │  Monitor (UC-08)│  │  Engine (SHAP)  ││
│  │  (Python)       │  │  (MCP + rules)  │  │  (Python)       ││
│  └─────────────────┘  └─────────────────┘  └─────────────────┘│
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │  Bias Audit     │  │  Risk Scoring   │  │  Model Drift    ││
│  │  Toolkit        │  │  Engine         │  │  Detection      ││
│  │  (Aequitas)     │  │  (Python)       │  │  (Python)       ││
│  └─────────────────┘  └─────────────────┘  └─────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

**Services:**
- `ml-job-persistence` — Weekly composite score calculation (UC-01)
- `ml-job-transcript-nlp` — BERT-based course equivalency scoring (UC-02)
- `ml-job-accreditation-nlp` — BERT-based evidence-to-standard matching (UC-03)
- `ml-job-alignment` — Three-way alignment check (UC-04)
- `ml-job-grading-load` — GLI calculation and crunch-week detection (UC-05)
- `ml-job-ai-grader` — Complexity scoring and tier recommendation (UC-06)
- `ml-job-enrollment-funnel` — Conversion and cycle time analytics (UC-07)
- `ml-job-compliance-monitor` — Regulatory change detection and UDM mapping (UC-08)
- `ml-job-explainability` — SHAP/LIME explanation generation
- `ml-job-bias-audit` — Aequitas/Fairlearn bias metric calculation
- `ml-job-risk-scoring` — Dynamic risk tier calculation
- `ml-job-drift-detection` — Model performance drift monitoring

**Technology:** Python (scikit-learn, PyTorch, Transformers), Apache Spark (distributed scoring), MLflow (model registry), Aequitas/Fairlearn (bias), SHAP/LIME (explainability)

### 3.5 Layer 5: Trust Model (The Core IP)

```
┌─────────────────────────────────────────────────────────────────┐
│  TRUST MODEL — THE CORE IP                                      │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  CANONICAL LAYER                                        ││
│  │  17 canonical definitions: student, course, instructor, ││
│  │  program, enrollment, completion, financial_aid, budget,  ││
│  │  research_award, compliance_event, facility, employee,    ││
│  │  admission, advisor, degree, transfer_credit,             ││
│  │  learner_outcome                                          ││
│  └─────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────┐│
│  │  UNIVERSAL DECODING MATRIX (UDM)                         ││
│  │  399 UCO_NODE_IDs mapping:                                ││
│  │  CIP → SOC → NAICS → Agency → Regulation → Form →       ││
│  │  Frequency → Penalty → UCO_NODE_ID → Compliance Chain   ││
│  └─────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────┐│
│  │  EVIDENCE CHAIN                                        ││
│  │  Immutable audit trail: model factors → transcript      ││
│  │  decisions → accreditation narratives → regulatory      ││
│  │  updates → bias audit results → incident logs             ││
│  │  Deployed on Trace chain (blockchain)                   ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

**Services:**
- `canonical-layer-service` — CRUD operations on 17 canonical definitions
- `udm-query-service` — UCO_NODE_ID resolution, compliance chain traversal, crosswalk lookups
- `evidence-chain-service` — Evidence logging, Trace chain deployment, audit trail retrieval
- `udm-indexer` — Full-text search on UDM (regulations, forms, penalties, notes)

**Technology:** PostgreSQL (canonical tables), Elasticsearch (UDM full-text search), Ethereum/Trace chain (immutable evidence), Redis (UDM cache)

---

## 4. Governance Controls (Cross-Cutting Layer)

### 4.1 RBAC & Role-Lens Governance

```
┌─────────────────────────────────────────────────────────────────┐
│  ROLE-LENS GOVERNANCE                                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────┐│
│  │  Advisor    │  │  Faculty    │  │  Registrar  │  │Compliance││
│  │  Lens       │  │  Aggregate  │  │  Authoritative│  │  Lens   ││
│  │  (student-  │  │  Lens       │  │  Lens       │  │ (full    ││
│  │   specific) │  │  (dept-level)│  │  (system-wide)│  │  access) ││
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────┘│
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────┐│
│  │  Dean       │  │  Provost    │  │  System     │  │  Admin   ││
│  │  Lens       │  │  Lens       │  │  Owner      │  │  Lens    ││
│  │  (college-  │  │  (institution│  │  Lens       │  │         ││
│  │   level)    │  │  -wide)     │  │  (technical)│  │         ││
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────┘│
└─────────────────────────────────────────────────────────────────┘
```

| Role | Data Visibility | Can See | Cannot See | UDM Query Scope |
|------|----------------|---------|------------|-----------------|
| **Advisor** | Own caseload only | Student activity signals, transcript queue for assigned students | Other advisors' students, PII, financial details | `WHERE advisor_id = current_user` |
| **Faculty (Aggregate)** | Department aggregate only | GLI, alignment status, AI-grader recommendations for own courses | Individual student records, other departments | `WHERE department_id = user_dept` |
| **Registrar** | System-wide, anonymized | All transcript queues, equivalency rules, cross-mart validation | Individual PII (hashed), advisory notes | Full access with pseudonymization |
| **Compliance Officer** | Full access, de-identified | All governance dashboards, incident logs, bias audits, regulatory alerts | Raw PII without audit trail | Full access with logging |
| **Dean** | College-level aggregate | College persistence rates, funnel metrics, accreditation status | Individual student records, other colleges | `WHERE college_id = user_college` |
| **Provost** | Institution-wide aggregate | All aggregate dashboards, budget, faculty workload, compliance posture | Individual records without justification | Full aggregate access |
| **System Owner** | System-specific | Model performance, drift metrics, risk register for owned system | Other systems' data without authorization | `WHERE system_owner = current_user` |
| **Admin** | Full access with logging | Everything | Nothing | Full access with immutable audit |

**Implementation:** JWT claims (`role`, `department_id`, `college_id`, `advisor_id`) + Row-Level Security (RLS) in PostgreSQL + API gateway filtering

### 4.2 Pseudonymization & Data Residency

| Control | Implementation | Standard |
|---------|---------------|----------|
| **Pseudonymization** | SYN IDs replace SSNs, student IDs in all external queries | FERPA §99.31 |
| **Hashing** | SHA-256 for input features in explainability logs | NIST AI RMF |
| **Encryption at rest** | AES-256 for PostgreSQL, S3, Elasticsearch | NIST SP 800-53 |
| **Encryption in transit** | TLS 1.3 for all APIs, mTLS for internal services | NIST SP 800-53 |
| **Data residency** | All student data on-prem or Lamar-controlled cloud | TSUS policy |
| **Retention** | 7 years standard; 10 years for financial aid | FERPA + state law |
| **Deletion** | Right to deletion for non-regulatory data; regulatory data archived | GDPR-style |

### 4.3 Approval Gates

```
┌─────────────────────────────────────────────────────────────────┐
│  APPROVAL GATES — HUMAN-IN-THE-LOOP MANDATORY                   │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  UC-08: REGULATORY CHANGE DETECTION                     ││
│  │  Firecrawl detects change → NLP impact mapping →         ││
│  │  UDM node matching → HUMAN APPROVAL QUEUE →            ││
│  │  Compliance Officer review → APPROVE / MODIFY / REJECT││
│  │  → Trace chain deployment → Rule update → Notification  ││
│  └─────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────┐│
│  │  UC-06: AI-GRADER TIER ASSIGNMENT                       ││
│  │  System recommends tier → Chair review →                 ││
│  │  APPROVE / MODIFY / REJECT → Professor notification →   ││
│  │  Student appeal process → Human review → Final grade    ││
│  └─────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────┐│
│  │  UC-02: TRANSCRIPT AUTO-APPROVE                         ││
│  │  NLP confidence > 0.95 + canonical rule match →         ││
│  │  AUTO-APPROVE (no human needed)                         ││
│  │  NLP confidence 0.80-0.95 → REGISTRAR REVIEW REQUIRED  ││
│  │  NLP confidence < 0.80 → MANUAL EVALUATION REQUIRED    ││
│  └─────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────┐│
│  │  MODULE 3: AI INCIDENT ESCALATION                      ││
│  │  Incident detected → Severity classification →          ││
│  │  CRITICAL → CCO within 4 hours + Board notification     ││
│  │  HIGH → CCO within 24 hours                             ││
│  │  MEDIUM → System Owner within 72 hours                  ││
│  │  LOW → Technical Contact within 5 business days         ││
│  └─────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────┐│
│  │  MODULE 3: BIAS AUDIT FAIL                              ││
│  │  Audit FAIL → Remediation plan required within 30 days →││
│  │  System Owner + CCO review → Suspension decision →     ││
│  │  Trace chain deployment → Public notification (if req)  ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. Product Capability Layer (Buyer-Visible Outcomes)

```
┌─────────────────────────────────────────────────────────────────┐
│  PRODUCT CAPABILITY LAYER — WHAT LAMAR STAFF SEE              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │  UC-01: Advisor │  │  UC-02: Registrar│  │  UC-03: Accred  ││
│  │  Dashboard      │  │  Portal          │  │  Gap Heat Map   ││
│  │  (Red-tier digest)│  │  (Transcript queue)│  │  (SACSCOC/AACSB)││
│  └─────────────────┘  └─────────────────┘  └─────────────────┘│
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │  UC-04: Chair   │  │  UC-05: Chair   │  │  UC-06: Chair   ││
│  │  Alignment      │  │  Grading Load   │  │  AI-Grader      ││
│  │  Dashboard      │  │  Dashboard      │  │  Routing        ││
│  └─────────────────┘  └─────────────────┘  └─────────────────┘│
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │  UC-07: Admissions│  │  UC-08: Compliance│  │  EDU Reporter   ││
│  │  Funnel Dashboard │  │  Alert Dashboard  │  │  (Unified Reporting)││
│  └─────────────────┘  └─────────────────┘  └─────────────────┘│
│  ┌─────────────────────────────────────────────────────────┐│
│  │  MODULE 3: AI GOVERNANCE DASHBOARD                      ││
│  │  Risk Summary | Overdue Audits | Open Incidents | High-Risk ││
│  │  Systems | Bias Audit Results | Third-Party Assessments  ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

**Frontend Applications:**
- `app-advisor-dashboard` — React/Next.js (UC-01)
- `app-registrar-portal` — React/Next.js (UC-02)
- `app-accreditation-dashboard` — React/Next.js (UC-03)
- `app-chair-dashboard` — React/Next.js (UC-04, UC-05, UC-06)
- `app-dean-dashboard` — React/Next.js (UC-05 aggregate, UC-07)
- `app-compliance-dashboard` — React/Next.js (UC-08, Module 3)
- `app-edu-reporter` — React/Next.js (Module 1 unified reporting)
- `app-admin-console` — React/Next.js (system administration, user management)

**Technology:** React 18, Next.js 14, TypeScript, Tailwind CSS, TanStack Query, Recharts (visualization), React Table (data grids)

---

## 6. Data Flow Examples

### 6.1 UC-01: Predictive Persistence (End-to-End)

```
Banner (enrollment, GPA) ──┐
Blackboard (logins, assignments) ──┼──► Connector Workers ──► Staging ──►
Concourse (advising notes) ──┤     (nightly, 2 AM)    Tables
TouchNet (payment status) ──┤
StarRez (housing status) ──┘

Staging ──► Canonical Builder ──► canonical_student ──►
     (deduplication, SYN IDs)

canonical_student ──► ML Job: Persistence ──► student_activity_signals ──►
     (composite score, risk tier, top factors)

student_activity_signals ──► API: /persistence/digest ──►
     (RBAC: advisor_id filter)

Advisor Dashboard ──► Human Review ──► Intervention Log ──►
     (phone call, email, referral)

Intervention Log ──► Trace Chain ──► Immutable Audit ──►
     (compliance evidence, accreditation narrative)
```

### 6.2 UC-08: Continuous Compliance (End-to-End)

```
Federal Register ──┐
Texas Register ─────┼──► Firecrawl MCP ──► Regulatory Text ──►
Agency RSS Feeds ──┤     (every 60 min)    Extraction
Court Dockets ─────┘

Regulatory Text ──► Claude MCP ──► Change Detection ──► NLP Impact ──►
     (what changed? vs. what was before?)    Mapping

NLP Impact ──► UDM Query ──► Affected UCO_NODE_IDs ──►
     (which rules, forms, agencies affected?)

Affected Nodes ──► Approval Queue ──► HUMAN REVIEW ──►
     (Compliance Officer: CRITICAL within 4 hours)

APPROVE ──► Trace Chain Deployment ──► Rule Update ──►
     (immutable tx hash)    (canonical layer update)

Rule Update ──► Notification ──► Affected Stakeholders ──►
     (email/Slack: Provost, Dean, Compliance, System Owners)

Rule Update ──► Cross-Mart Validation ──► Report Recalculation ──►
     (did any mart become inconsistent?)
```

### 6.3 Module 3: AI Governance Incident (End-to-End)

```
Persistence Model ──► Bias Audit ──► FAIL (disparate impact ratio = 0.72) ──►
     (annual audit, race attribute)

FAIL ──► fn_register_ai_incident() ──► ai_incident_log ──►
     (severity: HIGH, type: bias_complaint)

ai_incident_log ──► Auto-escalation ──► CCO Notification ──►
     (severity HIGH → CCO within 24 hours)

CCO Review ──► Remediation Plan ──► Model Retraining ──►
     (feature engineering, balanced dataset, advisor override audit)

Model Retraining ──► Validation ──► Bias Re-audit ──► PASS ──►
     (holdout test, Aequitas metrics)

PASS ──► Model Deployment ──► model_lifecycle_events ──►
     (event: model_updated, approved_by: CCO)

Model Deployment ──► Trace Chain ──► Immutable Audit ──►
     (tx hash: remediation complete, model v2.2 deployed)
```

---

## 7. Infrastructure & Deployment

### 7.1 Network Topology

```
┌─────────────────────────────────────────────────────────────────┐
│  INTERNET                                                        │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐            │
│  │  Campus │  │  Public │  │  Anthropic│  │ Microsoft │      │
│  │  Systems│  │  Sources│  │  AVA API │  │  Graph API │      │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘            │
└───────┼────────────┼────────────┼────────────┼────────────────┘
        │            │            │            │
        ▼            ▼            ▼            ▼
┌─────────────────────────────────────────────────────────────────┐
│  DMZ / API GATEWAY                                               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  NGINX / Cloudflare / AWS ALB                            │    │
│  │  TLS 1.3 termination, WAF, rate limiting, DDoS protection │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│  ON-PREM IOS+ ENGINE (Lamar Data Center or Lamar VPC)          │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Kubernetes Cluster (K8s)                                │    │
│  │  ┌─────────────────────────────────────────────────┐   │    │
│  │  │  Namespace: connector-ingestion                   │   │    │
│  │  │  (Kafka, Debezium, Airflow, custom workers)        │   │    │
│  │  └─────────────────────────────────────────────────┘   │    │
│  │  ┌─────────────────────────────────────────────────┐   │    │
│  │  │  Namespace: normalization-pipeline               │   │    │
│  │  │  (dbt, Spark, Great Expectations)                │   │    │
│  │  └─────────────────────────────────────────────────┘   │    │
│  │  ┌─────────────────────────────────────────────────┐   │    │
│  │  │  Namespace: rules-workflow                      │   │    │
│  │  │  (Drools, Camunda, Temporal, notification)     │   │    │
│  │  └─────────────────────────────────────────────────┘   │    │
│  │  ┌─────────────────────────────────────────────────┐   │    │
│  │  │  Namespace: ml-jobs                              │   │    │
│  │  │  (Python, PyTorch, Spark, MLflow)                │   │    │
│  │  └─────────────────────────────────────────────────┘   │    │
│  │  ┌─────────────────────────────────────────────────┐   │    │
│  │  │  Namespace: trust-model                          │   │    │
│  │  │  (PostgreSQL, Elasticsearch, Redis, Trace chain) │   │    │
│  │  └─────────────────────────────────────────────────┘   │    │
│  │  ┌─────────────────────────────────────────────────┐   │    │
│  │  │  Namespace: api-gateway                          │   │    │
│  │  │  (Node.js/Express, Fastify, JWT, RBAC)           │   │    │
│  │  └─────────────────────────────────────────────────┘   │    │
│  │  ┌─────────────────────────────────────────────────┐   │    │
│  │  │  Namespace: frontend-apps                      │   │    │
│  │  │  (Next.js, Nginx static serving)                 │   │    │
│  │  └─────────────────────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│  DATA STORAGE                                                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────┐│
│  │  PostgreSQL │  │  Elasticsearch│  │  Redis      │  │  S3    ││
│  │  (primary)  │  │  (search)   │  │  (cache)    │  │  (logs)││
│  │  16+ nodes  │  │  (UDM index) │  │  (session)  │  │  (artifacts)│
│  └─────────────┘  └─────────────┘  └─────────────┘  └────────┘│
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Trace Chain (Ethereum / Hyperledger)                   │   │
│  │  Immutable audit trail for governance                  │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 7.2 Deployment Units (Docker / K8s)

| Service | Docker Image | Replicas | Resources | Notes |
|---------|-------------|----------|-----------|-------|
| `connector-worker-banner` | `smepro/connector-banner:latest` | 2 | 2 CPU, 4GB RAM | Scheduled + CDC |
| `connector-worker-regulatory` | `smepro/connector-regulatory:latest` | 3 | 2 CPU, 4GB RAM | High-frequency scrape |
| `connector-worker-ai-orchestration` | `smepro/connector-ai:latest` | 2 | 4 CPU, 8GB RAM | GPU optional for local models |
| `normalization-service` | `smepro/normalization:latest` | 2 | 4 CPU, 8GB RAM | dbt + Spark |
| `rules-engine` | `smepro/rules-engine:latest` | 2 | 2 CPU, 4GB RAM | Drools |
| `workflow-orchestrator` | `smepro/workflow:latest` | 2 | 2 CPU, 4GB RAM | Camunda |
| `ml-job-persistence` | `smepro/ml-persistence:latest` | 1 | 4 CPU, 16GB RAM | Weekly batch |
| `ml-job-transcript-nlp` | `smepro/ml-transcript-nlp:latest` | 1 | 8 CPU, 32GB RAM | BERT inference; GPU required |
| `ml-job-accreditation-nlp` | `smepro/ml-accreditation-nlp:latest` | 1 | 8 CPU, 32GB RAM | BERT inference; GPU required |
| `api-gateway` | `smepro/api-gateway:latest` | 3 | 2 CPU, 4GB RAM | Load balanced |
| `udm-query-service` | `smepro/udm-query:latest` | 2 | 2 CPU, 4GB RAM | Cached |
| `evidence-chain-service` | `smepro/evidence-chain:latest` | 2 | 2 CPU, 4GB RAM | Trace chain interaction |
| `frontend-advisor` | `smepro/frontend-advisor:latest` | 2 | 1 CPU, 2GB RAM | Nginx static |
| `frontend-registrar` | `smepro/frontend-registrar:latest` | 2 | 1 CPU, 2GB RAM | Nginx static |
| `frontend-compliance` | `smepro/frontend-compliance:latest` | 2 | 1 CPU, 2GB RAM | Nginx static |
| `postgres-primary` | `postgres:16` | 2 | 8 CPU, 32GB RAM | Patroni HA |
| `postgres-replica` | `postgres:16` | 2 | 8 CPU, 32GB RAM | Streaming replica |
| `elasticsearch` | `elasticsearch:8` | 3 | 4 CPU, 16GB RAM | Cluster |
| `redis` | `redis:7` | 2 | 2 CPU, 8GB RAM | Sentinel HA |
| `kafka` | `kafka:3` | 3 | 4 CPU, 8GB RAM | KRaft mode |

---

## 8. Trace Chain Integration

### 8.1 What Gets Logged to Trace Chain

| Event Type | Data | Hash Method | Frequency |
|------------|------|-------------|-----------|
| **Regulatory Change Approval** | Change ID, approver, timestamp, affected UCO_NODE_IDs | SHA-256 | On approval |
| **Bias Audit Result** | Audit ID, system ID, pass/fail, metric values | SHA-256 | On completion |
| **AI Incident** | Incident ID, severity, description, remediation | SHA-256 | On registration |
| **Model Deployment** | Model version, validation metrics, approver | SHA-256 | On deployment |
| **Transcript Crosswalk Approval** | Queue ID, registrar ID, action, timestamp | SHA-256 | On approve |
| **AI-Grader Tier Assignment** | Course ID, tier, chair ID, professor ID | SHA-256 | On apply |
| **Compliance Alert Review** | Alert ID, reviewer, action, timestamp | SHA-256 | On review |
| **Explainability Log** | Prediction ID, explanation hash, reviewer | SHA-256 | On human review |

### 8.2 Trace Chain Smart Contract (Simplified)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SMEProEvidenceChain {
    struct Evidence {
        string evidenceType;      // "regulatory_change", "bias_audit", "ai_incident"
        string ucoNodeId;         // UCO_NODE_ID affected
        string descriptionHash;   // SHA-256 of description
        string dataHash;          // SHA-256 of full evidence data
        address submitter;        // Ethereum address of submitter
        uint256 timestamp;        // Block timestamp
        string institutionId;     // "lamar-university"
    }

    mapping(bytes32 => Evidence) public evidence;
    bytes32[] public evidenceList;

    event EvidenceSubmitted(
        bytes32 indexed evidenceId,
        string evidenceType,
        string ucoNodeId,
        address submitter,
        uint256 timestamp
    );

    function submitEvidence(
        string memory _evidenceType,
        string memory _ucoNodeId,
        string memory _descriptionHash,
        string memory _dataHash,
        string memory _institutionId
    ) public returns (bytes32) {
        bytes32 evidenceId = keccak256(abi.encodePacked(
            _evidenceType, _ucoNodeId, _dataHash, block.timestamp, msg.sender
        ));

        evidence[evidenceId] = Evidence({
            evidenceType: _evidenceType,
            ucoNodeId: _ucoNodeId,
            descriptionHash: _descriptionHash,
            dataHash: _dataHash,
            submitter: msg.sender,
            timestamp: block.timestamp,
            institutionId: _institutionId
        });

        evidenceList.push(evidenceId);
        emit EvidenceSubmitted(evidenceId, _evidenceType, _ucoNodeId, msg.sender, block.timestamp);
        return evidenceId;
    }

    function getEvidence(bytes32 _evidenceId) public view returns (Evidence memory) {
        return evidence[_evidenceId];
    }

    function getEvidenceCount() public view returns (uint256) {
        return evidenceList.length;
    }
}
```

---

## 9. API Gateway Specification

### 9.1 Route Mapping

| Route | Namespace | Service | Auth Required | Rate Limit |
|-------|-----------|---------|---------------|------------|
| `/v1/compliance/*` | api-gateway | Module 1 services | JWT + RBAC | 120/min |
| `/v1/module2/persistence/*` | api-gateway | UC-01 services | JWT + RBAC | 120/min |
| `/v1/module2/crosswalk/*` | api-gateway | UC-02 services | JWT + RBAC | 120/min |
| `/v1/module2/accreditation/*` | api-gateway | UC-03 services | JWT + RBAC | 120/min |
| `/v1/module2/alignment/*` | api-gateway | UC-04 services | JWT + RBAC | 120/min |
| `/v1/module2/faculty/*` | api-gateway | UC-05/06 services | JWT + RBAC | 60/min |
| `/v1/module2/enrollment/*` | api-gateway | UC-07 services | JWT + RBAC | 60/min |
| `/v1/module2/compliance-monitor/*` | api-gateway | UC-08 services | JWT + RBAC | 60/min |
| `/v1/module3/governance/*` | api-gateway | Module 3 services | JWT + admin | 60/min |
| `/v1/health/*` | api-gateway | Health checks | None | 1000/min |
| `/v1/metrics/*` | api-gateway | Prometheus metrics | Internal | 1000/min |

### 9.2 Authentication Flow

```
User login ──► Lamar SSO (SAML/OIDC) ──► JWT issued ──►
     (Banner credentials, Duo MFA)

JWT ──► API Gateway ──► RBAC resolution ──► Role-lens filter ──►
     (role, department, college, advisor_id)

Role-lens filter ──► Service request ──► PostgreSQL RLS ──►
     (row-level security based on JWT claims)

Response ──► API Gateway ──► PII filtering ──► User ──►
     (SYN IDs replace PII; no raw SSNs, no addresses)
```

---

## 10. Monitoring & Observability

### 10.1 Metrics

| Metric | Source | Alert Threshold | Dashboard |
|--------|--------|-----------------|-----------|
| API response time | API Gateway | p99 > 500ms | Grafana |
| API error rate | API Gateway | > 1% | Grafana |
| ETL job duration | Airflow | > 4 hours (nightly) | Airflow UI |
| ETL job failure | Airflow | Any failure | PagerDuty |
| Model inference time | ML Jobs | p99 > 2s | Grafana |
| Model drift | ML Jobs | Accuracy drop > 5% | Grafana |
| Bias audit metric | Bias Audit | Disparate impact < 0.80 | Compliance Dashboard |
| Data quality score | Great Expectations | < 95% | Data Quality Dashboard |
| Trace chain latency | Evidence Chain | > 30s | Grafana |
| Connector uptime | Connector Workers | < 99.9% | Grafana |

### 10.2 Logging

| Log Type | Destination | Retention | Format |
|----------|-------------|-----------|--------|
| Application logs | Loki / Elasticsearch | 30 days | JSON (structured) |
| Audit logs | Trace chain + S3 | 7 years | Immutable (blockchain) |
| Access logs | S3 + Athena | 2 years | Apache Combined |
| Error logs | Sentry | 90 days | Structured with stack trace |
| ML experiment logs | MLflow | 7 years | MLflow native |

---

## 11. Files & Deliverables

| File | Path | Description |
|------|------|-------------|
| Architecture v2 Narrative | `ios-plus/docs/Architecture_v2_Narrative.md` | Deck-ready narrative |
| Architecture v2 Deployment Spec | `ios-plus/docs/Architecture_v2_Deployment_Spec.md` | This file — formal engineering spec |
| Architecture v2 Diagram Layout | `ios-plus/docs/Architecture_v2_Diagram_Layout.md` | Text boxes for designer |
| Architecture v2 Repo Mapping | `ios-plus/docs/Architecture_v2_Repo_Mapping.md` | Code folder structure |

---

*End of Deployment Specification.*
