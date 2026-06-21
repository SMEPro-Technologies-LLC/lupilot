# SMEPro COS Architecture v2 — Clean Narrative for the Deck
## Buyer-Legible, Engineer-Credible Architecture Story
## Version: 2026.06.20-LAMAR-ARCH-v2.0
## Date: 2026-06-20

---

## The Story in One Paragraph

The SMEPro Compliance Operating System is a **governed intelligence engine** that lives on Lamar's campus. It connects to three kinds of external sources—campus systems, public regulatory feeds, and governed AI services—each through a purpose-built connector with appropriate security posture. Inside the trust boundary, data is normalized, canonicalized, and mapped to the Universal Decoding Matrix (UDM). Operational intelligence (UC-01 through UC-08) runs on this governed layer. AI governance (Module 3) oversees every prediction. Nothing deploys without human approval. Every answer is traceable to a UCO_NODE_ID. Data never leaves campus.

---

## Section 1: What We Connect To (3 Source Bands)

### Band A: Campus Systems — Institutional Data

These are the systems Lamar already owns. They contain student records, financial data, course information, and operational logs. SMEPro connects to them via **read-only APIs and change-data-capture streams**. No data is pushed back except through explicit, approved write-back channels (e.g., Banner Ethos for transcript credit).

| System | What We Pull | How Often | Security |
|--------|-------------|-----------|----------|
| Banner (Student, FinAid, Finance, HR) | Enrollment, GPA, financial aid, personnel | Nightly + CDC | OAuth 2.0 + institution cert |
| Blackboard Ultra | Grades, assignments, logins, engagement | Nightly + LTI events | OAuth 2.0 + API key |
| Concourse | Syllabus text, CLO mappings, course outcomes | Nightly + SFTP | API key + SFTP key |
| TouchNet | Payment status, due dates, holds | Nightly | OAuth 2.0 |
| StarRez | Housing assignments, occupancy | Nightly | API key |
| PeopleSoft (TSUS) | Budget, AFR, audit data | Nightly | WS-Security |
| Cayuse | Research proposals, awards, IRB | Nightly | OAuth 2.0 |
| Omnigo | Safety incidents, daily logs | Nightly | API key |
| TeamMate | Internal audit findings | Nightly | OAuth 2.0 |

**Key message:** These connectors are **institutional system connectors**. They move data into canonical storage. They do not modify source systems. All PII is pseudonymized at ingestion.

---

### Band B: Public Regulatory Sources — Rules & Standards

These are external agencies, publications, and guidance documents that define what Lamar must comply with. SMEPro monitors them via **web scraping and NLP** to detect changes in real time.

| Source | What We Monitor | How Often | Governance |
|--------|---------------|-----------|------------|
| Federal Register | New rules, final rules, guidance | Every 60 minutes | Human approval required |
| Texas Register | State rules, THECB updates | Every 120 minutes | Human approval required |
| IPEDS / NCES | Survey specifications, definitions | Annually | Manual trigger |
| THECB CBM Manuals | Reporting requirements, forms | Annually + on change | Manual upload + NLP |
| Clery Handbook | Guidance, compliance updates | Weekly | Human approval required |
| SACSCOC / AACSB / ABET / ACEN / CCNE | Accreditation standards, criteria | On update | Manual upload + NLP |
| NCSBN / DEA / TX BON | Licensure rules, compact status | Monthly / Weekly | Human approval required |
| Court Dockets | Litigation affecting higher ed | Daily | Human review |

**Key message:** These are **regulatory source connectors**. They feed the "watchtower" function. Every detected change is matched to UCO_NODE_IDs in the UDM and routed to a **human approval queue** before any system update is deployed. No automated rule deployment. Ever.

---

### Band C: Governed AI Services — Orchestrated Intelligence

These are AI tools that consume bounded context from the UDM, not free-standing intelligence layers. They never have direct database access.

| Service | What It Does | Governance Control |
|---------|------------|-------------------|
| Microsoft Copilot | Synthesizes answers from cited UDM nodes | Bounded context only; no direct DB access |
| Claude MCP | Powers NLP extraction, regulatory analysis | Role-lens filtered; no PII in prompts |
| Firecrawl MCP | Scrapes public regulatory sources | URL whitelist; no institutional data sent |
| Anthropic AVA | Provides formative feedback on student work | Professor approval gate; BAA in place |
| SHAP / LIME | Explains model predictions | Runs on-prem; no external data sent |
| BERT / NLP Models | Course equivalency, evidence matching | Runs on-prem; no external API calls |

**Key message:** These are **governed AI service connectors**. They sit in an **orchestration boundary**. The orchestration layer resolves allowed context via RBAC, fetches cited nodes from the UDM, constructs a bounded prompt, and presents the AI's response with full traceability. The AI is a **constrained reasoning layer**, not the system of record.

---

## Section 2: The On-Prem Engine (What Lives on Campus)

The on-prem engine is a **5-layer decomposition** inside a single trust boundary. Everything in this box is controlled by Lamar. No student data leaves this box.

### Layer 1: Connector Ingestion Workers

These are the pipes that pull data from the three source bands. They run on a schedule (Apache Airflow), listen to change streams (Debezium + Kafka), and receive webhooks (async events).

**What happens here:**
- Banner data is extracted and staged nightly
- Blackboard events are captured in real time via LTI
- Regulatory sources are scraped every 15–60 minutes
- AI orchestration requests are queued and context-bounded

**Technology:** Apache Kafka, Debezium, Apache Airflow, Python, Go

---

### Layer 2: Normalization & Canonical Pipeline

Raw data from 15 source systems is messy. This layer cleans it, validates it, deduplicates it, and maps it to **17 canonical definitions**—one authoritative definition per concept.

**Example:** "Full-time student" means the same thing in IPEDS, Title IV, and THECB reports because it is defined once in `canonical_student` and reused everywhere.

**What happens here:**
- Staging tables → Data quality tests (Great Expectations)
- Entity resolution → Probabilistic matching of person IDs, course IDs
- Canonical building → 17 canonical definitions populated
- Cross-mart validation → Ensures consistency across 12 agency marts

**Technology:** dbt, Great Expectations, Apache Spark, PostgreSQL

---

### Layer 3: Rules, Workflow & Approval Engine

This is where governance is enforced. Business rules, approval workflows, policy checks, and notifications all live here.

**What happens here:**
- A detected regulatory change triggers an approval queue item
- A bias audit failure triggers an incident workflow
- A registrar clicks "approve" on a transcript crosswalk → Banner Ethos write-back is queued
- An AI-grader tier recommendation waits for chair approval

**Technology:** Drools (business rules), Camunda / Temporal (workflows), SendGrid / Slack (notifications)

**Key message:** This is the **approval gate**. Human-in-the-loop is mandatory for all decisions affecting individual students, regulatory updates, and high-risk AI operations.

---

### Layer 4: Scoring, Analytics & ML Jobs

These are the operational intelligence engines—UC-01 through UC-08. They run on the canonical data, produce predictions and insights, and log everything.

| Job | What It Calculates | Frequency | Output |
|-----|-------------------|-----------|--------|
| UC-01 Persistence | Weekly composite risk scores | Weekly (Monday 6 AM) | Red-tier digest |
| UC-02 Transcript NLP | Course equivalency confidence | Real-time (webhook) | Queue with scores |
| UC-03 Accreditation NLP | Evidence-to-standard matching | Weekly (NLP scan) | Gap heat map |
| UC-04 Alignment | CLO ↔ Syllabus ↔ Blackboard check | Nightly | Flagged courses |
| UC-05 Grading Load | GLI = Weight × Items × Rubric × Enrollment | End of registration | Dashboard + alerts |
| UC-06 AI-Grader | Complexity-weighted tier assignment | End of registration | Routing recommendations |
| UC-07 Enrollment Funnel | Stage conversion and cycle time | Real-time (event stream) | Funnel dashboard |
| UC-08 Compliance Monitor | Regulatory change detection | Every 15–60 minutes | Alert queue |

**Technology:** Python (scikit-learn, PyTorch, Transformers), Apache Spark, MLflow, Aequitas, SHAP, LIME

---

### Layer 5: The Trust Model (The Core IP)

This is the center of the architecture. Three durable assets that make SMEPro different from "just dashboards" or "just AI chat."

#### Canonical Layer
17 canonical definitions. One source of truth for every concept. No more reconciling three different student counts from three different reports.

#### Universal Decoding Matrix (UDM)
399 UCO_NODE_IDs mapping every regulation, form, agency, and compliance chain to a traceable node. The UDM is the **lens** that constrains CoPilot to a curated answer space.

> "The UDM is the lens, the swarm is the eye, CoPilot is the voice. Every answer must be traceable to a UCO_NODE_ID."

#### Evidence Chain
An immutable audit trail connecting model factors, transcript decisions, accreditation narratives, regulatory updates, bias audit results, and incident logs. Deployed on a **Trace chain** (blockchain) for tamper-proof evidence.

**Technology:** PostgreSQL (canonical), Elasticsearch (UDM search), Redis (cache), Ethereum / Trace chain (immutable logging)

---

### Governance Controls (Wraps Everything)

These are not a separate box—they are a **cross-cutting layer** that wraps around every other layer.

| Control | What It Does |
|---------|-------------|
| **RBAC / Role-Lens** | Advisor sees own caseload. Faculty sees department aggregate. Registrar sees system-wide anonymized data. Compliance officer sees everything with audit logging. |
| **Pseudonymization** | SYN IDs replace SSNs and student IDs. SHA-256 hashes for ML input features. No raw PII in external queries. |
| **Approval Gates** | Human-in-the-loop mandatory for all student-affecting decisions, regulatory updates, and high-risk AI operations. |
| **Trace Chain Deployer** | Immutable audit trail for governance, accreditation, and legal defense. |

---

## Section 3: The Product Capabilities (What Users See)

The bottom layer is what Lamar staff actually interact with. Not "EDU Reporter" as a single monolith, but **buyer-visible outcomes** mapped to the use cases.

| Capability | User | What They See | Module |
|-----------|------|--------------|--------|
| **UC-01: Predictive Persistence** | Advisor | Weekly Red-tier digest, ranked student list, top-3 factors, intervention log | Module 2 |
| **UC-02: Transcript Crosswalk** | Registrar | Evaluation queue with confidence scores, one-click approve/modify/reject, equivalency rules | Module 2 |
| **UC-03: Accreditation Gap** | Accreditation Officer | Color-coded heat map (Green/Yellow/Orange/Red) per SACSCOC/AACSB/ABET/ACEN/CCNE standard | Module 2 |
| **UC-04: Outcome Alignment** | Department Chair | Flagged courses: MISSING_CLO, GHOST_ASSESSMENT, WEIGHT_MISMATCH | Module 2 |
| **UC-05: Grading Load Analyzer** | Department Chair / Dean | GLI dashboard, crunch-week heat map, GA allocation recommendations | Module 2 |
| **UC-06: AI-Grader Routing** | Department Chair / Lead Professor | Tier recommendations (NONE → AVA_FEEDBACK → AUTO_GRADE → HUMAN_REVIEW) | Module 2 |
| **UC-07: Enrollment Funnel** | Admissions / Dean | Stage conversion rates, cycle times, dropout analysis by stage and reason | Module 2 |
| **UC-08: Compliance Monitor** | Compliance Officer | Regulatory alert queue with severity, impact assessment, human review workflow | Module 2 |
| **EDU Reporter** | All roles | Unified reporting portal across 12 agency marts, 17 canonical definitions | Module 1 |
| **AI Governance Dashboard** | CCO / Provost / Board | Risk summary, overdue audits, open incidents, high-risk systems, bias audit results | Module 3 |

**Key message:** The architecture is **outcome-aligned**. We don't sell "a compliance platform." We sell **predictive persistence**, **transcript automation**, **accreditation confidence**, **workload visibility**, **AI grading efficiency**, **enrollment clarity**, and **regulatory peace of mind**.

---

## Section 4: The Governance Posture (Why This Is Different)

### Compared to "Just Dashboards"

| Feature | Traditional Dashboard | SMEPro COS |
|---------|----------------------|------------|
| Data source | Manual CSV uploads | 15 automated connectors |
| Data quality | "Trust me, it's clean" | Great Expectations tests, cross-mart validation |
| Regulatory awareness | Someone reads the Federal Register | Firecrawl + Claude MCP, 24/7 monitoring |
| AI governance | "We have an AI policy" | NIST AI RMF, bias audits, explainability logs, incident tracking |
| Audit trail | Spreadsheet version history | Blockchain-deployed immutable evidence |
| Student data | In the cloud, somewhere | On-prem, pseudonymized, FERPA-compliant |

### Compared to "Just AI Chat"

| Feature | Generic AI Chatbot | SMEPro CoPilot |
|---------|-------------------|----------------|
| Context | Entire internet | Bounded by UDM cited nodes, role-lens filtered |
| Accuracy | Hallucination risk | Every answer traceable to UCO_NODE_ID |
| Compliance | "AI-generated, use at own risk" | Human-in-the-loop mandatory, approval gates, audit trail |
| Data access | Direct to database | Orchestrated—no direct DB access |
| Bias | Unaudited | Annual bias audits, EEOC 80% rule, disparate impact monitoring |

---

## Section 5: The Data Flow Story (3 Examples)

### Example 1: A Student Is Flagged as High-Risk (UC-01)

1. **Monday 6 AM:** ETL job pulls Banner enrollment, Blackboard logins, TouchNet payments, StarRez housing
2. **Monday 6:15 AM:** Canonical builder deduplicates and pseudonymizes. ML job calculates composite score: 34 (Red tier)
3. **Monday 6:30 AM:** SHAP explainability engine identifies top-3 factors: no BB login (7 days), 2 missing assignments, tuition overdue
4. **Monday 8 AM:** Advisor opens dashboard. Sees Red-tier digest. Clicks student. Sees factors. Makes phone call.
5. **Monday 10 AM:** Advisor logs intervention: "Student cited financial stress. Referred to Financial Aid. Follow-up 9/22."
6. **Monday 2 PM:** CoPilot sends automated resource email to student. Intervention logged. Trace chain deployed.

**Governance checks:** Bias audit ensures disparate impact ratio ≥ 0.80. Advisor override always available. FERPA 7-year retention. No automated decision—human makes the call.

---

### Example 2: A Regulatory Change Is Detected (UC-08)

1. **Tuesday 6 AM:** Firecrawl detects new FSA final rule on 90/10 reporting requirements
2. **Tuesday 6:05 AM:** Claude MCP extracts change summary. NLP maps to UCO_NODE_IDs: UCO-MOD1-0011 (90/10), UCO-MOD1-0008 (FSA)
3. **Tuesday 6:10 AM:** Impact assessment: "Quarterly reporting required starting Q1 2026. ETL schedule must change."
4. **Tuesday 6:15 AM:** Alert queued as CRITICAL. Compliance Officer notified.
5. **Tuesday 10 AM:** Officer reviews alert. Approves for implementation. Clicks "Deploy to Trace chain."
6. **Tuesday 10:05 AM:** Trace chain deployed (tx hash: 0xabc123...). Rule updated in canonical layer. ETL schedule modified. Notification sent to Financial Aid Director and Controller.

**Governance checks:** No automated deployment. Human approval mandatory. Trace chain provides immutable evidence. Cross-mart validation ensures no inconsistency introduced.

---

### Example 3: A Bias Audit Fails (Module 3)

1. **Wednesday:** Annual bias audit on Predictive Persistence Model (UC-01). Race attribute. Disparate impact ratio = 0.72 (FAIL, below 0.80 threshold).
2. **Wednesday 2 PM:** `fn_register_ai_incident()` triggers. Severity: HIGH. CCO notified within 24 hours.
3. **Thursday:** CCO review. Remediation plan: retrain model with balanced dataset, add socioeconomic features, mandatory advisor override audit.
4. **Week 2–4:** Model retrained. Validated. Bias re-audit. Ratio = 0.85 (PASS).
5. **Week 5:** Model deployed (v2.2). `model_lifecycle_events` logged. Trace chain deployed. Student Success Director trained on new override requirements.

**Governance checks:** No system operates after failed audit without remediation. Independent audit or CCO + legal review. Trace chain documents the entire process. Board may be notified if systemic.

---

## Section 6: The Build Story (What Happens Next)

### Phase 1: Foundation (30 days)
- PostgreSQL staging with V11–V14 migrations
- ETL pipelines for 15 source systems
- Authentication layer (JWT + RBAC + Lamar SSO)
- API gateway (all 25+ endpoints)
- Advisor dashboard (UC-01) and Registrar portal (UC-02)

### Phase 2: Operational Intelligence (30 days)
- BERT NLP training for transcript crosswalk (UC-02)
- Accreditation standards library loading (UC-03)
- Chair dashboards for alignment (UC-04) and grading load (UC-05)
- Bias audit for UC-01 (pre-deployment)

### Phase 3: Governance & Advanced (30 days)
- Anthropic AVA integration (UC-06 pilot)
- Firecrawl + Claude MCP activation (UC-08)
- Compliance monitoring dashboard
- AI governance executive dashboard (Module 3)
- UAT with all roles
- Security review & penetration test
- Go-live for UC-01 through UC-05

---

## Summary: The 5 Architectural Principles

1. **Three source bands, three governance postures.** Campus systems (green), public sources (orange), AI services (purple). Each connector class is purpose-built and appropriately secured.

2. **Execution layer inside the trust boundary.** The on-prem engine is not just semantic. It has ingestion workers, normalization pipelines, rules engines, ML jobs, and the trust model itself.

3. **CoPilot is governed, not free.** AI services consume bounded context from the UDM. They do not have direct database access. Every response is traceable to cited nodes.

4. **Approval gates are explicit and mandatory.** Human-in-the-loop for all student-affecting decisions, regulatory updates, and high-risk AI operations. No exceptions.

5. **Outcomes are buyer-visible, not feature-lists.** We don't sell "a platform." We sell persistence, crosswalk automation, accreditation confidence, workload visibility, grading efficiency, enrollment clarity, and regulatory peace of mind.

---

*Prepared for: Lamar University Leadership and Board Governance Committee*  
*Prepared by: SMEPro COS Engineering*  
*Date: June 20, 2026*  
*Architecture Version: v2.0*

---

**Companion Documents:**
- `Architecture_v2_Deployment_Spec.md` — Formal engineering specification (52 tables, 17 views, 7 functions, service mesh, K8s deployment)
- `Architecture_v2_Diagram_Layout.md` — Text-box specification for designer (1920×1080, color palette, box labels, arrow styles, annotations, legend)
- `Architecture_v2_Repo_Mapping.md` — Repository folder structure and service-to-code mapping
