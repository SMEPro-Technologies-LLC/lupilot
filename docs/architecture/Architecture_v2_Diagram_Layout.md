# SMEPro COS Architecture v2 — Diagram Layout for Designer
## Text-Box Specification for Visual Production
## Version: 2026.06.20-LAMAR-ARCH-v2.0
## Date: 2026-06-20

---

## Instructions for Designer

This is a **text-box specification** for the architecture diagram. Each section is a visual layer. Inside each section, every `┌────┐` block is a box with a label. Arrows (`→` or `↓`) indicate data flow. Colors are specified per layer.

**Overall dimensions:** 1920 × 1080 (16:9) or 2400 × 1350 (print)  
**Style:** Flat, modern, corporate. No gradients. Solid fills. White borders between boxes.  
**Typography:** Sans-serif (Inter or Helvetica Neue). 12pt for box labels. 10pt for sub-labels. 14pt bold for section headers.

---

## Layer 1: Cloud / External Sources (Top Band)

**Background color:** Light blue `#E8F4F8`  
**Section header:** "EXTERNAL SOURCES — Data enters via governed connectors"  
**Header background:** `#1A5F7A` (dark teal)  
**Header text:** White, bold, 14pt

### 1A. Campus Systems (Left third of top band)
**Box fill:** `#2E7D32` (institutional green)  
**Box text:** White, bold 12pt + regular 10pt sub-label

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   BANNER        │  │  BLACKBOARD     │  │   CONCOURSE     │
│   (Student,     │  │   ULTRA         │  │   (Syllabus,    │
│   FinAid, HR)   │  │   (LMS)         │  │   CLO mapping)  │
│   Ethos API     │  │   REST API      │  │   API + SFTP    │
└─────────────────┘  └─────────────────┘  └─────────────────┘

┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   TOUCHNET       │  │   STARREZ        │  │   PEOPLESOFT    │
│   (Payments)     │  │   (Housing)      │  │   (TSUS)        │
│   REST API       │  │   REST API       │  │   Integration   │
│                  │  │                  │  │   Broker        │
└─────────────────┘  └─────────────────┘  └─────────────────┘

┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   CAYUSE         │  │   OMNIGO         │  │   TEAMMATE      │
│   (Research)     │  │   (Safety)       │  │   (Audit)       │
│   REST API       │  │   REST API       │  │   REST API      │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

**Sub-label for section:**  
"Institutional system connectors — scheduled pull, CDC, webhooks.  
Data never leaves campus. All PII pseudonymized at ingestion."

**Small icon suggestion:** Shield with checkmark (green) next to "Data never leaves campus"

---

### 1B. Public Regulatory Sources (Middle third of top band)
**Box fill:** `#F57C00` (regulatory orange)  
**Box text:** White, bold 12pt + regular 10pt sub-label

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  FEDERAL        │  │  TEXAS          │  │  IPEDS /        │
│  REGISTER       │  │  REGISTER       │  │  THECB /        │
│  (Firecrawl MCP)│  │  (Firecrawl)    │  │  CLERY /        │
│  60 min checks  │  │  120 min checks │  │  CBM MANUALS    │
└─────────────────┘  └─────────────────┘  └─────────────────┘

┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  SACSCOC /      │  │  ABET /         │  │  eNLC /         │
│  AACSB / ACEN / │  │  CCNE /         │  │  IMLC /         │
│  CCNE Standards │  │  NCSBN / DEA    │  │  PSYPACT /      │
│  (Manual + NLP) │  │  (Web scrape)   │  │  COURT Dockets  │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

**Sub-label for section:**  
"Public regulatory source connectors — web scrape, NLP extraction, change detection.  
All detected changes go to HUMAN APPROVAL QUEUE before deployment."

**Small icon suggestion:** Magnifying glass with alert bell (orange) next to "Change detection"

---

### 1C. Governed AI Services (Right third of top band)
**Box fill:** `#7B1FA2` (AI purple)  
**Box text:** White, bold 12pt + regular 10pt sub-label

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  MICROSOFT      │  │  CLAUDE MCP     │  │  FIRECRAWL      │
│  COPILOT        │  │  (Anthropic)    │  │  MCP            │
│  (Graph API)    │  │  (API + SSE)    │  │  (Scraping)     │
│  Bounded context│  │  Role-lens only │  │  URL whitelist  │
└─────────────────┘  └─────────────────┘  └─────────────────┘

┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  ANTHROPIC AVA  │  │  SHAP / LIME    │  │  BERT / NLP     │
│  (Third-Party)  │  │  Explainability │  │  Models (Local) │
│  Blackboard LTI │  │  (Local Python) │  │  (Hugging Face) │
│  Professor gate │  │  No external    │  │  No external    │
│  required       │  │  data sent      │  │  API calls      │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

**Sub-label for section:**  
"Governed AI service connectors — orchestrated by the UDM, bounded by cited nodes, role-lens filtered.  
AI services NEVER have direct database access."

**Small icon suggestion:** Brain inside a fence (purple) next to "Bounded by cited nodes"

---

### 1D. Unified Label for All Three Bands

**Above the three bands, full width:**

```
┌─────────────────────────────────────────────────────────────────┐
│  SOURCE BANDS — 3 connector classes, 3 governance postures          │
│  Campus systems (green) → pull/CDC/webhook → institutional data│
│  Public sources (orange) → scrape/NLP → approval queue → rules   │
│  AI services (purple) → orchestrated → bounded context → no DB  │
└─────────────────────────────────────────────────────────────────┘
```

**Background:** `#263238` (dark slate)  
**Text:** White, 11pt, regular

---

## Layer 2: DMZ / API Gateway (Thin Horizontal Band)

**Background color:** `#37474F` (gray)  
**Height:** ~60px  
**Section header:** "DMZ / API GATEWAY — TLS 1.3, WAF, rate limiting, DDoS protection"

```
┌─────────────────────────────────────────────────────────────────┐
│  NGINX / CLOUDFLARE / AWS ALB                                   │
│  TLS 1.3 termination │ WAF │ Rate limiting │ Auth (JWT + RBAC)  │
└─────────────────────────────────────────────────────────────────┘
```

**Text:** White, 10pt, regular  
**Small icons:** Lock, shield, speedometer, key

---

## Layer 3: On-Prem IOS+ Engine (Main Green Box)

**Background color:** `#E8F5E9` (light green) — THE TRUST BOUNDARY  
**Border:** 4px solid `#2E7D32` (green) with rounded corners (8px)  
**Label on top border:** "ON-PREM IOS+ ENGINE — Data never leaves campus"  
**Label background:** `#2E7D32`  
**Label text:** White, bold, 14pt

---

### 3A. Row 1 — Execution / Runtime Services (Inside green box, top half)
**Background:** `#C8E6C9` (lighter green)  
**Section header:** "EXECUTION / RUNTIME SERVICES"  
**Header text:** `#2E7D32`, bold, 12pt

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  CONNECTOR      │  │  NORMALIZATION  │  │  RULES /        │  │  ML JOBS        │
│  INGESTION      │  │  & CANONICAL    │  │  WORKFLOW       │  │  (UC-01 to      │
│  WORKERS        │  │  PIPELINE       │  │  ENGINE         │  │  UC-08)         │
│  (Kafka, CDC,   │  │  (dbt, Spark,   │  │  (Drools,       │  │  (Python,       │
│  Airflow)       │  │  dbt tests)     │  │  Camunda)       │  │  PyTorch, BERT) │
└─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘
```

**Box fill:** `#81C784` (medium green)  
**Box text:** `#1B5E20` (dark green), 11pt bold + 9pt regular

---

### 3B. Row 2 — Trust Model (Inside green box, bottom half)
**Background:** `#A5D6A7` (soft green)  
**Section header:** "TRUST MODEL — THE CORE IP"  
**Header text:** `#2E7D32`, bold, 12pt

```
┌─────────────────────────────────────────────────────────────────┐
│  CANONICAL LAYER                                                │
│  17 canonical definitions: student, course, instructor,         │
│  program, enrollment, completion, financial_aid, budget,        │
│  research_award, compliance_event, facility, employee,          │
│  admission, advisor, degree, transfer_credit, learner_outcome   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  UNIVERSAL DECODING MATRIX (UDM)                                │
│  399 UCO_NODE_IDs: CIP → SOC → NAICS → Agency → Regulation →   │
│  Form → Frequency → Penalty → UCO_NODE_ID → Compliance Chain    │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  EVIDENCE CHAIN                                                 │
│  Immutable audit trail: model factors → transcript decisions →  │
│  accreditation narratives → regulatory updates → bias audits →  │
│  incident logs → Trace chain (blockchain) deployment            │
└─────────────────────────────────────────────────────────────────┘
```

**Box fill:** `#4CAF50` (core green)  
**Box text:** White, 11pt bold + 10pt regular  
**Special treatment:** The UDM box should be the widest and most visually prominent in the entire diagram. It is the centerpiece.

---

### 3C. Governance Controls (Vertical sidebar on right edge of green box)
**Background:** `#FFEBEE` (light red)  
**Section header:** "GOVERNANCE CONTROLS"  
**Header text:** `#C62828`, bold, 11pt

```
┌─────────────────┐
│  RBAC /         │
│  ROLE-LENS      │
│  (advisor,      │
│  faculty,       │
│  registrar,     │
│  compliance,    │
│  dean, provost) │
└─────────────────┘

┌─────────────────┐
│  PSEUDONYMIZE   │
│  (SYN IDs,      │
│  SHA-256,       │
│  FERPA 7yr)     │
└─────────────────┘

┌─────────────────┐
│  APPROVAL       │
│  GATES          │
│  (human-in-the- │
│  loop mandatory)│
└─────────────────┘

┌─────────────────┐
│  TRACE CHAIN    │
│  DEPLOYER       │
│  (immutable     │
│  audit trail)   │
└─────────────────┘
```

**Box fill:** `#EF9A9A` (soft red)  
**Box text:** `#B71C1C` (dark red), 10pt bold + 9pt regular

**Position:** Right edge of the green box, vertically aligned with execution + trust layers. Governance wraps around everything.

---

## Layer 4: Approval Gate (Explicit Visual Element)

**Position:** Between the green box (on-prem engine) and the bottom outcome layer  
**Background:** `#FFF3E0` (light orange)  
**Border:** 3px dashed `#F57C00` (orange) with rounded corners  
**Height:** ~80px

```
┌─────────────────────────────────────────────────────────────────┐
│  APPROVAL GATE — HUMAN-IN-THE-LOOP MANDATORY                    │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐   │
│  │ UC-08:  │    │ UC-06:  │    │ UC-02:  │    │ MOD-3:  │   │
│  │ Regulatory│ → │ AI-Grader│ → │ Transcript│ → │ Bias    │   │
│  │ Change  │    │ Tier    │    │ Auto-   │    │ Audit   │   │
│  │ Review  │    │ Assignment│   │ Approve │    │ FAIL    │   │
│  └─────────┘    └─────────┘    └─────────┘    └─────────┘   │
│  No automated regulatory updates. No AI grades without          │
│  professor approval. No auto-approve below 0.95 confidence.    │
│  No system deployment after failed audit without remediation.  │
└─────────────────────────────────────────────────────────────────┘
```

**Text:** `#E65100` (dark orange), 11pt bold + 10pt regular  
**Icons:** Hand stopping an arrow (approval gate), checkmark with clock (human review), X with person (rejection possible)

---

## Layer 5: Product Capability / Outcome Layer (Bottom)

**Background color:** `#E3F2FD` (light blue)  
**Section header:** "PRODUCT CAPABILITIES — What Lamar Staff See"  
**Header background:** `#1565C0` (blue)  
**Header text:** White, bold, 14pt

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  UC-01: Advisor │  │  UC-02: Registrar│  │  UC-03: Accred  │
│  Dashboard      │  │  Portal          │  │  Gap Heat Map   │
│  (Red-tier      │  │  (Transcript     │  │  (SACSCOC,      │
│  digest,        │  │  queue,          │  │  AACSB, ABET,   │
│  intervention)  │  │  equivalency)    │  │  ACEN, CCNE)    │
└─────────────────┘  └─────────────────┘  └─────────────────┘

┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  UC-04: Chair   │  │  UC-05: Chair   │  │  UC-06: Chair   │
│  Alignment      │  │  Grading Load   │  │  AI-Grader      │
│  Dashboard      │  │  Dashboard      │  │  Routing        │
│  (CLO↔Syllabus  │  │  (GLI, crunch-  │  │  (AVA feedback, │
│  ↔Blackboard)   │  │  week heat map) │  │  tier assignment)│
└─────────────────┘  └─────────────────┘  └─────────────────┘

┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  UC-07: Dean /  │  │  UC-08: Compliance│  │  EDU REPORTER   │
│  Admissions     │  │  Alert Dashboard  │  │  (Unified        │
│  Funnel         │  │  (Regulatory      │  │  Reporting       │
│  Dashboard      │  │  watchtower,      │  │  Portal)         │
│  (conversion,   │  │  Trace chain)     │  │  (12 marts,     │
│  cycle time)    │  │                  │  │  17 canonical)   │
└─────────────────┘  └─────────────────┘  └─────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  MODULE 3: AI GOVERNANCE DASHBOARD                              │
│  Risk Summary | Overdue Audits | Open Incidents | High-Risk     │
│  Systems | Bias Audit Results | Third-Party Assessments         │
└─────────────────────────────────────────────────────────────────┘
```

**Box fill:** `#64B5F6` (medium blue)  
**Box text:** White, 11pt bold + 10pt regular  
**Special treatment:** The "EDU REPORTER" box should be visually distinct — perhaps with a border or badge indicating it's the "Module 1" surface.

---

## Arrows & Data Flow (Connect Everything)

### Vertical arrows (top to bottom)

```
Campus Systems (green) ───────┐
                                 │
                                 ▼
                          DMZ / API Gateway (gray)
                                 │
                                 ▼
                     ┌─────────────────────┐
                     │  On-Prem Engine     │
                     │  (green trust box)  │
                     │  ┌───────────────┐  │
                     │  │ Execution   │  │
                     │  │ Services    │  │
                     │  └─────────────┘  │
                     │  ┌───────────────┐  │
                     │  │ Trust Model │  │
                     │  │ (UDM center)│  │
                     │  └─────────────┘  │
                     │  ┌───────────────┐  │
                     │  │ Governance  │  │
                     │  │ (sidebar)   │  │
                     │  └─────────────┘  │
                     └─────────────────────┘
                                 │
                                 ▼
                     ┌─────────────────────┐
                     │  APPROVAL GATE      │
                     │  (dashed orange)    │
                     │  human-in-the-loop  │
                     └─────────────────────┘
                                 │
                                 ▼
Product Capabilities (blue) ─────┘
```

### Horizontal arrows (within layers)

```
Connector Workers → Normalization → Rules Engine → ML Jobs
     │                    │              │              │
     └────────────────────┴──────────────┴──────────────┘
                          │
                          ▼
                   Canonical Layer → UDM → Evidence Chain
                          │
                          ▼
                   Governance Controls (wraps everything)
```

### Arrow style
- **Solid arrows:** Data flow (black, 2px)
- **Dashed arrows:** Approval/governance flow (orange, 2px, dashed)
- **Dotted arrows:** Audit/logging flow (red, 1px, dotted) → Trace chain

---

## Color Palette (Summary)

| Layer | Background | Box Fill | Text | Border |
|-------|-----------|----------|------|--------|
| Campus Systems | `#E8F4F8` | `#2E7D32` | White | `#1B5E20` |
| Public Sources | `#E8F4F8` | `#F57C00` | White | `#E65100` |
| AI Services | `#E8F4F8` | `#7B1FA2` | White | `#4A148C` |
| DMZ Gateway | `#37474F` | `#455A64` | White | `#263238` |
| On-Prem Engine | `#E8F5E9` | `#C8E6C9` (exec) / `#4CAF50` (trust) | `#1B5E20` / White | `#2E7D32` (thick) |
| Governance Sidebar | `#FFEBEE` | `#EF9A9A` | `#B71C1C` | `#C62828` |
| Approval Gate | `#FFF3E0` | `#FFE0B2` | `#E65100` | `#F57C00` (dashed) |
| Product Capabilities | `#E3F2FD` | `#64B5F6` | White | `#1565C0` |
| Source Band Header | `#263238` | — | White | — |
| Outcome Header | `#1565C0` | — | White | — |

---

## Legend (Bottom Right Corner)

```
┌─────────────────────────────────────────┐
│  LEGEND                                 │
│  ─────────                              │
│  ■ Green box = Campus system          │
│  ■ Orange box = Public regulatory     │
│  ■ Purple box = Governed AI service   │
│  ■ Green fill = On-prem trust engine  │
│  ■ Red sidebar = Governance controls   │
│  ■ Dashed orange = Approval gate      │
│  ■ Blue box = Product capability      │
│  ─── Solid arrow = Data flow          │
│  - - Dashed arrow = Approval flow     │
│  · · Dotted arrow = Audit trail       │
│  🛡️ = Data never leaves campus        │
│  🔒 = Human-in-the-loop mandatory    │
│  ⛓️ = Trace chain (immutable)         │
└─────────────────────────────────────────┘
```

**Background:** White  
**Border:** `#9E9E9E` (gray), 1px solid  
**Text:** `#424242` (dark gray), 9pt regular

---

## Annotations (Callouts)

### Annotation 1: "Data never leaves campus"
**Position:** Left side of on-prem green box, vertically centered  
**Style:** Speech bubble pointing to green box  
**Background:** `#2E7D32`  
**Text:** White, bold, 11pt  
**Icon:** Shield with checkmark 🛡️

### Annotation 2: "The UDM is the lens, the swarm is the eye, CoPilot is the voice"
**Position:** Centered above the UDM box (inside the green box)  
**Style:** Subtitle text, no box  
**Text:** `#2E7D32`, italic, 10pt

### Annotation 3: "Every answer traceable to a UCO_NODE_ID"
**Position:** Below the UDM box, inside the green box  
**Style:** Small text with arrow pointing to UDM  
**Text:** `#2E7D32`, italic, 9pt

### Annotation 4: "No AI service has direct DB access"
**Position:** Right side of AI services band, pointing to the purple boxes  
**Style:** Warning-style callout  
**Background:** `#FFEBEE`  
**Text:** `#C62828`, bold, 10pt  
**Icon:** Lock 🔒

### Annotation 5: "All regulatory changes → approval queue"
**Position:** Below public sources band, pointing to orange boxes  
**Style:** Process callout  
**Background:** `#FFF3E0`  
**Text:** `#E65100`, bold, 10pt  
**Icon:** Hand with clock ✋

---

## Version & Footer

**Bottom center:**
```
SMEPro COS Architecture v2.0 | Lamar University | June 20, 2026
```
**Text:** `#9E9E9E`, 8pt, regular

**Bottom left:**
```
Data never leaves campus. All PII pseudonymized. FERPA compliant.
```
**Text:** `#2E7D32`, 8pt, bold

**Bottom right:**
```
399 UCO_NODE_IDs | 52 PostgreSQL tables | 25+ API endpoints | NIST AI RMF aligned
```
**Text:** `#9E9E9E`, 8pt, regular

---

*End of Diagram Layout Specification.*
