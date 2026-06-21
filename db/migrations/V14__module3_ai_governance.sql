-- ============================================================
-- Flyway Migration: V14__module3_ai_governance.sql
-- SMEPro COS — Module 3: AI Governance
-- Date: 2026-06-20
-- Author: SMEPro COS Engineering
-- ============================================================
-- Scope: NIST AI Risk Management Framework (AI RMF) 1.0,
--        EU AI Act (reference mapping for US institutions),
--        institutional AI governance policies, algorithmic
--        accountability, model risk management, bias auditing,
--        AI inventory, explainability, and third-party assessment.
-- ============================================================

-- ============================================================
-- SCHEMA: module3_ai_governance
-- ============================================================
CREATE SCHEMA IF NOT EXISTS module3_ai_governance;
COMMENT ON SCHEMA module3_ai_governance IS
  'Module 3: AI Governance — NIST AI RMF, EU AI Act reference, algorithmic accountability, model lifecycle, bias audit, AI inventory, explainability, third-party assessment. Covers all AI/ML systems deployed at Lamar University including Module 2 operational intelligence engines.';

-- ============================================================
-- TABLE: ai_system_inventory
-- ============================================================
-- Every AI/ML system deployed or procured by Lamar must be
-- registered here. One record per system. Updated annually
-- or on significant change. Aligns with NIST AI RMF GOVERN-1.1.
-- ============================================================
CREATE TABLE module3_ai_governance.ai_system_inventory (
    system_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_name VARCHAR(255) NOT NULL,
    system_description TEXT NOT NULL,
    system_owner VARCHAR(100) NOT NULL,
    system_owner_department VARCHAR(100) NOT NULL,
    technical_contact VARCHAR(100) NOT NULL,
    procurement_date DATE NOT NULL,
    vendor_name VARCHAR(255),
    vendor_contact VARCHAR(255),
    vendor_contract_id VARCHAR(100),
    data_sources JSONB NOT NULL DEFAULT '[]',
    -- e.g., ["Banner SIS", "Blackboard Ultra", "TouchNet"]
    output_destinations JSONB NOT NULL DEFAULT '[]',
    -- e.g., ["Advisor Dashboard", "Registrar Portal", "CoPilot"]
    model_type VARCHAR(100) NOT NULL CHECK (model_type IN
        ('predictive_model', 'generative_model', 'nlp_model',
         'computer_vision', 'recommendation_system', 'anomaly_detector',
         'classification_model', 'clustering_model', 'ensemble',
         'third_party_api', 'hybrid')),
    deployment_status VARCHAR(50) NOT NULL DEFAULT 'development'
        CHECK (deployment_status IN
        ('development', 'pilot', 'production', 'retired', 'suspended')),
    risk_tier VARCHAR(20) NOT NULL DEFAULT 'limited'
        CHECK (risk_tier IN
        ('minimal', 'limited', 'high', 'unacceptable')),
    -- EU AI Act Article 6 + Annex III mapping (reference for US institutions)
    eu_ai_act_applicable BOOLEAN DEFAULT FALSE,
    eu_ai_act_class VARCHAR(50) CHECK (eu_ai_act_class IN
        ('minimal', 'limited', 'high_risk', 'prohibited')),
    nist_ai_rmf_governance_map JSONB,
    -- { "govern": ["GOVERN-1.1", "GOVERN-1.2"], "map": [...], ... }
    last_risk_assessment_date DATE,
    next_risk_assessment_date DATE,
    last_bias_audit_date DATE,
    next_bias_audit_date DATE,
    model_version_current VARCHAR(20),
    model_version_history JSONB DEFAULT '[]',
    -- [{"version": "1.0", "deployed_at": "2025-01-15", "retired_at": null}]
    data_retention_days INTEGER NOT NULL DEFAULT 2555,
    -- 7 years default for educational records (FERPA)
    pii_involved BOOLEAN DEFAULT FALSE,
    phi_involved BOOLEAN DEFAULT FALSE,
    fERPA_applicable BOOLEAN DEFAULT TRUE,
    gdpr_applicable BOOLEAN DEFAULT FALSE,
    ccpa_applicable BOOLEAN DEFAULT FALSE,
    explainability_required BOOLEAN DEFAULT TRUE,
    human_in_the_loop_required BOOLEAN DEFAULT TRUE,
    human_in_the_loop_description TEXT,
    uco_node_id VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    updated_by VARCHAR(100) DEFAULT CURRENT_USER
);

COMMENT ON TABLE module3_ai_governance.ai_system_inventory IS
  'Master inventory of all AI/ML systems at Lamar. Aligns with NIST AI RMF GOVERN-1.1 and EU AI Act Article 6 (reference). Includes all Module 2 operational intelligence engines (UC-01 through UC-08) plus any third-party procured AI tools.';

CREATE INDEX idx_ai_system_inventory_risk_tier
    ON module3_ai_governance.ai_system_inventory(risk_tier);
CREATE INDEX idx_ai_system_inventory_deployment_status
    ON module3_ai_governance.ai_system_inventory(deployment_status);
CREATE INDEX idx_ai_system_inventory_eu_ai_act_class
    ON module3_ai_governance.ai_system_inventory(eu_ai_act_class);

-- ============================================================
-- TABLE: model_risk_register
-- ============================================================
-- Per-system risk register. Updated quarterly or on trigger.
-- Aligns with NIST AI RMF MAP-1.1, MAP-1.2, and MEASURE-1.1.
-- ============================================================
CREATE TABLE module3_ai_governance.model_risk_register (
    risk_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES module3_ai_governance.ai_system_inventory(system_id),
    risk_category VARCHAR(50) NOT NULL CHECK (risk_category IN
        ('algorithmic_bias', 'data_privacy', 'model_drift',
         'adversarial_attack', 'lack_of_explainability',
         'overreliance', 'third_party_dependency', 'regulatory_noncompliance',
         'reputational', 'financial', 'operational', 'safety')),
    risk_description TEXT NOT NULL,
    risk_likelihood INTEGER NOT NULL CHECK (risk_likelihood BETWEEN 1 AND 5),
    risk_impact INTEGER NOT NULL CHECK (risk_impact BETWEEN 1 AND 5),
    risk_score INTEGER GENERATED ALWAYS AS (risk_likelihood * risk_impact) STORED,
    risk_owner VARCHAR(100) NOT NULL,
    mitigation_measures TEXT NOT NULL,
    residual_risk_score INTEGER CHECK (residual_risk_score BETWEEN 1 AND 25),
    monitoring_method TEXT NOT NULL,
    alert_threshold TEXT,
    last_reviewed_date DATE NOT NULL DEFAULT CURRENT_DATE,
    next_review_date DATE NOT NULL,
    review_status VARCHAR(20) NOT NULL DEFAULT 'open'
        CHECK (review_status IN ('open', 'mitigated', 'accepted', 'transferred', 'closed')),
    uco_node_id VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE module3_ai_governance.model_risk_register IS
  'Per-system AI risk register. NIST AI RMF MAP-1.1 (context is identified and documented), MAP-1.2 (risk tolerance is established), MEASURE-1.1 (appropriate methods and metrics are identified). Risk scores 1-25 (likelihood × impact). CRITICAL: 20-25, HIGH: 15-19, MEDIUM: 10-14, LOW: 5-9, MINIMAL: 1-4.';

CREATE INDEX idx_model_risk_register_system_id
    ON module3_ai_governance.model_risk_register(system_id);
CREATE INDEX idx_model_risk_register_risk_score
    ON module3_ai_governance.model_risk_register(risk_score DESC);

-- ============================================================
-- TABLE: bias_audit_log
-- ============================================================
-- Bias audit results per system, per protected attribute.
-- Aligns with NIST AI RMF MEASURE-2.1 and EU AI Act Article 10.
-- ============================================================
CREATE TABLE module3_ai_governance.bias_audit_log (
    audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES module3_ai_governance.ai_system_inventory(system_id),
    audit_date DATE NOT NULL DEFAULT CURRENT_DATE,
    auditor_name VARCHAR(100) NOT NULL,
    auditor_role VARCHAR(100) NOT NULL,
    audit_type VARCHAR(50) NOT NULL CHECK (audit_type IN
        ('pre_deployment', 'post_deployment', 'annual', 'triggered', 'third_party')),
    protected_attribute VARCHAR(50) NOT NULL CHECK (protected_attribute IN
        ('race', 'gender', 'age', 'disability', 'national_origin',
         'religion', 'socioeconomic_status', 'veteran_status',
         'sexual_orientation', 'genetic_information', 'combined')),
    metric_used VARCHAR(100) NOT NULL,
    -- e.g., "demographic_parity", "equal_opportunity", "predictive_parity",
    -- "calibration", "disparate_impact_ratio", "equalized_odds"
    metric_value DECIMAL(10,4) NOT NULL,
    metric_threshold DECIMAL(10,4) NOT NULL,
    -- e.g., 0.80 for 80% rule (disparate impact)
    threshold_source VARCHAR(100) NOT NULL,
    -- e.g., "EEOC 80% rule", "legal counsel", "institutional policy", "NIST AI RMF"
    pass_fail VARCHAR(10) NOT NULL CHECK (pass_fail IN ('PASS', 'FAIL', 'WARNING')),
    sample_size INTEGER NOT NULL,
    sample_date_range DATERANGE NOT NULL,
    audit_methodology TEXT NOT NULL,
    -- e.g., "Aequitas toolkit", "Fairlearn", "custom SQL analysis", "independent audit"
    findings_summary TEXT NOT NULL,
    remediation_plan TEXT,
    remediation_deadline DATE,
    remediation_status VARCHAR(20) DEFAULT 'pending'
        CHECK (remediation_status IN ('pending', 'in_progress', 'completed', 'waived')),
    remediation_owner VARCHAR(100),
    uco_node_id VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE module3_ai_governance.bias_audit_log IS
  'Bias audit results per system and protected attribute. Required for all high-risk student-facing systems. EEOC 80% rule (disparate impact ratio < 0.80) is default threshold. Annual audits mandatory; pre-deployment audits required for new systems.';

CREATE INDEX idx_bias_audit_log_system_id
    ON module3_ai_governance.bias_audit_log(system_id);
CREATE INDEX idx_bias_audit_log_pass_fail
    ON module3_ai_governance.bias_audit_log(pass_fail);

-- ============================================================
-- TABLE: ai_incident_log
-- ============================================================
-- AI incident tracking — near misses, adverse outcomes, and
-- remediation. Mandatory for high-risk systems.
-- Aligns with NIST AI RMF MEASURE-3.1 and GOVERN-5.1.
-- ============================================================
CREATE TABLE module3_ai_governance.ai_incident_log (
    incident_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES module3_ai_governance.ai_system_inventory(system_id),
    incident_date TIMESTAMP NOT NULL DEFAULT NOW(),
    reported_by VARCHAR(100) NOT NULL,
    incident_type VARCHAR(50) NOT NULL CHECK (incident_type IN
        ('adverse_outcome', 'near_miss', 'bias_complaint',
         'privacy_breach', 'security_breach', 'model_failure',
         'incorrect_prediction', 'explainability_failure', 'other')),
    severity VARCHAR(20) NOT NULL CHECK (severity IN
        ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'INFO')),
    incident_description TEXT NOT NULL,
    affected_individuals_count INTEGER,
    affected_individuals_description TEXT,
    -- e.g., "45 students flagged incorrectly as high-risk by persistence model"
    root_cause_analysis TEXT,
    remediation_actions TEXT,
    remediation_status VARCHAR(20) DEFAULT 'open'
        CHECK (remediation_status IN ('open', 'in_progress', 'resolved', 'escalated')),
    escalation_to VARCHAR(100),
    -- e.g., "Provost", "General Counsel", "Board of Regents", "ED-OCR"
    external_notification_required BOOLEAN DEFAULT FALSE,
    external_notification_agency VARCHAR(100),
    -- e.g., "ED-OCR", "Texas Attorney General", "HHS-OCR", "FTC"
    external_notification_date DATE,
    trace_chain_tx_hash VARCHAR(100),
    -- immutable audit trail on Trace chain (blockchain-based)
    uco_node_id VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE module3_ai_governance.ai_incident_log IS
  'AI incident and adverse outcome tracking. All CRITICAL incidents auto-escalate to Chief Compliance Officer. External notification may be required for ED-OCR (Title IX), FTC (consumer protection), or state AG (privacy). Trace chain deployment provides immutable audit trail.';

CREATE INDEX idx_ai_incident_log_system_id
    ON module3_ai_governance.ai_incident_log(system_id);
CREATE INDEX idx_ai_incident_log_severity
    ON module3_ai_governance.ai_incident_log(severity);

-- ============================================================
-- TABLE: model_lifecycle_events
-- ============================================================
-- Tracks every significant event in a model's lifecycle:
-- training, validation, deployment, update, rollback, retirement.
-- Aligns with NIST AI RMF GOVERN-3.1 and MANAGE-1.1.
-- ============================================================
CREATE TABLE module3_ai_governance.model_lifecycle_events (
    event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES module3_ai_governance.ai_system_inventory(system_id),
    event_type VARCHAR(50) NOT NULL CHECK (event_type IN
        ('training_started', 'training_completed', 'validation_started',
         'validation_completed', 'deployment_approved', 'deployed_to_production',
         'model_updated', 'model_rolled_back', 'model_retired',
         'performance_review', 'drift_detected', 'retraining_triggered',
         'human_review_completed', 'bias_audit_completed')),
    event_timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    event_description TEXT NOT NULL,
    performed_by VARCHAR(100) NOT NULL,
    approved_by VARCHAR(100),
    artifacts JSONB DEFAULT '{}',
    -- e.g., {"model_artifact_uri": "s3://...", "validation_report": "...", "drift_metrics": "..."}
    environment VARCHAR(50) NOT NULL CHECK (environment IN
        ('development', 'staging', 'production')),
    uco_node_id VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE module3_ai_governance.model_lifecycle_events IS
  'Model lifecycle event tracking. All production deployments require approval by system owner + technical contact. Drift detection triggers retraining workflow. Rollback events require documented root cause.';

CREATE INDEX idx_model_lifecycle_events_system_id
    ON module3_ai_governance.model_lifecycle_events(system_id);

-- ============================================================
-- TABLE: explainability_log
-- ============================================================
-- Logs model explanations and interpretability artifacts.
-- Required for high-risk and student-facing systems.
-- Aligns with NIST AI RMF MEASURE-2.2 and EU AI Act Article 13.
-- ============================================================
CREATE TABLE module3_ai_governance.explainability_log (
    explanation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES module3_ai_governance.ai_system_inventory(system_id),
    prediction_id VARCHAR(100) NOT NULL,
    -- e.g., "SYN-12345-2025-09-15" for persistence prediction
    prediction_timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    input_features_hash VARCHAR(64) NOT NULL,
    -- SHA-256 hash of input features (privacy-preserving)
    explanation_method VARCHAR(100) NOT NULL,
    -- e.g., "SHAP", "LIME", "attention_weights", "feature_importance",
    -- "counterfactual", "rule_extraction", "saliency_map", "integrated_gradients"
    explanation_output JSONB NOT NULL,
    -- e.g., {"shap_values": {"feature1": 0.35, "feature2": -0.12}, ...}
    human_reviewed BOOLEAN DEFAULT FALSE,
    human_reviewer VARCHAR(100),
    human_review_notes TEXT,
    human_review_timestamp TIMESTAMP,
    uco_node_id VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE module3_ai_governance.explainability_log IS
  'Model explainability and interpretability logs. SHA-256 hashing of input features preserves privacy while allowing reproducibility. Human review required for all high-risk predictions. SHAP/LIME outputs stored for student appeal process.';

CREATE INDEX idx_explainability_log_system_id
    ON module3_ai_governance.explainability_log(system_id);
CREATE INDEX idx_explainability_log_prediction_id
    ON module3_ai_governance.explainability_log(prediction_id);

-- ============================================================
-- TABLE: third_party_ai_assessment
-- ============================================================
-- Vendor/supplier AI assessments for procured systems.
-- Aligns with NIST AI RMF GOVERN-1.2 and GOVERN-5.2.
-- ============================================================
CREATE TABLE module3_ai_governance.third_party_ai_assessment (
    assessment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES module3_ai_governance.ai_system_inventory(system_id),
    vendor_name VARCHAR(255) NOT NULL,
    vendor_system_name VARCHAR(255) NOT NULL,
    assessment_type VARCHAR(50) NOT NULL CHECK (assessment_type IN
        ('pre_procurement', 'annual_review', 'security_audit',
         'bias_audit', 'privacy_audit', 'compliance_certification')),
    assessment_date DATE NOT NULL,
    assessor_name VARCHAR(100) NOT NULL,
    assessor_organization VARCHAR(100) NOT NULL,
    assessment_result VARCHAR(20) NOT NULL CHECK (assessment_result IN
        ('APPROVED', 'CONDITIONAL', 'REJECTED', 'PENDING')),
    findings JSONB NOT NULL DEFAULT '[]',
    -- [{"finding": "Vendor does not provide model cards", "severity": "HIGH", "recommendation": "..."}]
    remediation_required BOOLEAN DEFAULT FALSE,
    remediation_plan TEXT,
    remediation_deadline DATE,
    remediation_status VARCHAR(20) DEFAULT 'pending'
        CHECK (remediation_status IN ('pending', 'in_progress', 'completed', 'waived')),
    contract_renewal_recommendation VARCHAR(20),
    -- e.g., "renew", "renegotiate", "terminate"
    uco_node_id VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE module3_ai_governance.third_party_ai_assessment IS
  'Vendor AI system assessments. Pre-procurement assessment mandatory for all third-party AI. Annual review required for production systems. CONDITIONAL results require remediation plan with deadline. REJECTED results block procurement or trigger contract termination.';

-- ============================================================
-- VIEWS: Governance Dashboards
-- ============================================================

-- ============================================================
-- VIEW: v_ai_system_risk_summary
-- Executive dashboard summarizing AI system risk posture.
-- ============================================================
CREATE OR REPLACE VIEW module3_ai_governance.v_ai_system_risk_summary AS
SELECT
    ai.system_id,
    ai.system_name,
    ai.system_owner,
    ai.system_owner_department,
    ai.deployment_status,
    ai.risk_tier,
    ai.eu_ai_act_class,
    ai.last_risk_assessment_date,
    ai.next_risk_assessment_date,
    ai.last_bias_audit_date,
    ai.next_bias_audit_date,
    ai.model_version_current,
    ai.human_in_the_loop_required,
    COUNT(DISTINCT mr.risk_id) AS total_risks,
    COUNT(DISTINCT CASE WHEN mr.risk_score >= 15 THEN mr.risk_id END) AS high_risks,
    COUNT(DISTINCT CASE WHEN bl.pass_fail = 'FAIL' THEN bl.audit_id END) AS failed_bias_audits,
    COUNT(DISTINCT CASE WHEN il.severity IN ('CRITICAL', 'HIGH') AND il.remediation_status IN ('open', 'in_progress', 'escalated') THEN il.incident_id END) AS critical_incidents,
    CASE
        WHEN ai.next_risk_assessment_date < CURRENT_DATE THEN 'OVERDUE'
        WHEN ai.next_risk_assessment_date <= CURRENT_DATE + INTERVAL '30 days' THEN 'DUE_SOON'
        ELSE 'CURRENT'
    END AS assessment_status,
    CASE
        WHEN ai.next_bias_audit_date < CURRENT_DATE THEN 'OVERDUE'
        WHEN ai.next_bias_audit_date <= CURRENT_DATE + INTERVAL '30 days' THEN 'DUE_SOON'
        ELSE 'CURRENT'
    END AS audit_status,
    ai.uco_node_id
FROM module3_ai_governance.ai_system_inventory ai
LEFT JOIN module3_ai_governance.model_risk_register mr
    ON ai.system_id = mr.system_id AND mr.review_status = 'open'
LEFT JOIN module3_ai_governance.bias_audit_log bl
    ON ai.system_id = bl.system_id
LEFT JOIN module3_ai_governance.ai_incident_log il
    ON ai.system_id = il.system_id AND il.remediation_status IN ('open', 'in_progress', 'escalated')
GROUP BY ai.system_id, ai.system_name, ai.system_owner, ai.system_owner_department,
         ai.deployment_status, ai.risk_tier, ai.eu_ai_act_class,
         ai.last_risk_assessment_date, ai.next_risk_assessment_date,
         ai.last_bias_audit_date, ai.next_bias_audit_date,
         ai.model_version_current, ai.human_in_the_loop_required, ai.uco_node_id;

COMMENT ON VIEW module3_ai_governance.v_ai_system_risk_summary IS
  'Executive dashboard summarizing AI system risk posture, overdue assessments, failed audits, and open incidents. Updated in real-time. Used by CCO, Provost, and Board governance committees.';

-- ============================================================
-- VIEW: v_high_risk_ai_systems
-- Systems requiring immediate governance attention.
-- ============================================================
CREATE OR REPLACE VIEW module3_ai_governance.v_high_risk_ai_systems AS
SELECT *
FROM module3_ai_governance.v_ai_system_risk_summary
WHERE risk_tier IN ('high', 'unacceptable')
   OR eu_ai_act_class = 'high_risk'
   OR assessment_status = 'OVERDUE'
   OR audit_status = 'OVERDUE'
   OR high_risks > 0
   OR failed_bias_audits > 0
   OR critical_incidents > 0;

COMMENT ON VIEW module3_ai_governance.v_high_risk_ai_systems IS
  'Systems requiring immediate governance attention — high risk, overdue assessments, open incidents, or failed audits. Auto-escalated to CCO daily at 6:00 AM.';

-- ============================================================
-- VIEW: v_bias_audit_overdue
-- ============================================================
CREATE OR REPLACE VIEW module3_ai_governance.v_bias_audit_overdue AS
SELECT
    ai.system_id,
    ai.system_name,
    ai.system_owner,
    ai.system_owner_department,
    ai.last_bias_audit_date,
    ai.next_bias_audit_date,
    CURRENT_DATE - ai.next_bias_audit_date AS days_overdue,
    ai.risk_tier,
    ai.uco_node_id
FROM module3_ai_governance.ai_system_inventory ai
WHERE ai.next_bias_audit_date < CURRENT_DATE
   AND ai.deployment_status IN ('pilot', 'production')
ORDER BY
    CASE ai.risk_tier
        WHEN 'unacceptable' THEN 1
        WHEN 'high' THEN 2
        WHEN 'limited' THEN 3
        WHEN 'minimal' THEN 4
        ELSE 5
    END,
    days_overdue DESC;

COMMENT ON VIEW module3_ai_governance.v_bias_audit_overdue IS
  'Systems with overdue bias audits — prioritized by risk tier and days overdue. Compliance Officer must schedule within 5 business days.';

-- ============================================================
-- VIEW: v_ai_incident_open
-- Open incidents prioritized by severity and age.
-- ============================================================
CREATE OR REPLACE VIEW module3_ai_governance.v_ai_incident_open AS
SELECT
    il.incident_id,
    il.system_id,
    ai.system_name,
    il.incident_date,
    il.incident_type,
    il.severity,
    il.incident_description,
    il.affected_individuals_count,
    il.remediation_status,
    il.escalation_to,
    il.external_notification_required,
    CURRENT_DATE - il.incident_date::date AS days_open,
    il.uco_node_id
FROM module3_ai_governance.ai_incident_log il
JOIN module3_ai_governance.ai_system_inventory ai
    ON il.system_id = ai.system_id
WHERE il.remediation_status IN ('open', 'in_progress', 'escalated')
ORDER BY
    CASE il.severity
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        WHEN 'LOW' THEN 4
        ELSE 5
    END,
    days_open DESC;

COMMENT ON VIEW module3_ai_governance.v_ai_incident_open IS
  'Open AI incidents prioritized by severity and age — for governance review and escalation. CRITICAL incidents require CCO notification within 4 hours.';

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- ============================================================
-- FUNCTION: fn_calculate_risk_tier
-- Dynamic risk tier based on open risks, failed audits, incidents.
-- ============================================================
CREATE OR REPLACE FUNCTION module3_ai_governance.fn_calculate_risk_tier(
    p_system_id UUID
)
RETURNS VARCHAR(20) AS $$
DECLARE
    v_risk_count INTEGER;
    v_high_risk_count INTEGER;
    v_fail_count INTEGER;
    v_critical_count INTEGER;
    v_tier VARCHAR(20);
BEGIN
    SELECT COUNT(*) INTO v_risk_count
    FROM module3_ai_governance.model_risk_register
    WHERE system_id = p_system_id AND review_status = 'open';

    SELECT COUNT(*) INTO v_high_risk_count
    FROM module3_ai_governance.model_risk_register
    WHERE system_id = p_system_id AND review_status = 'open' AND risk_score >= 15;

    SELECT COUNT(*) INTO v_fail_count
    FROM module3_ai_governance.bias_audit_log
    WHERE system_id = p_system_id AND pass_fail = 'FAIL';

    SELECT COUNT(*) INTO v_critical_count
    FROM module3_ai_governance.ai_incident_log
    WHERE system_id = p_system_id AND severity IN ('CRITICAL', 'HIGH')
      AND remediation_status IN ('open', 'in_progress');

    IF v_critical_count > 0 OR v_fail_count > 2 OR v_high_risk_count > 3 THEN
        v_tier := 'unacceptable';
    ELSIF v_high_risk_count > 0 OR v_fail_count > 0 OR v_risk_count > 5 THEN
        v_tier := 'high';
    ELSIF v_risk_count > 0 THEN
        v_tier := 'limited';
    ELSE
        v_tier := 'minimal';
    END IF;

    RETURN v_tier;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION module3_ai_governance.fn_calculate_risk_tier IS
  'Dynamic risk tier calculation based on open risks (score >= 15), failed bias audits, and critical/high incidents. Auto-evaluated quarterly. Unacceptable tier triggers immediate suspension review.';

-- ============================================================
-- FUNCTION: fn_register_ai_incident
-- Auto-escalates CRITICAL incidents to CCO.
-- ============================================================
CREATE OR REPLACE FUNCTION module3_ai_governance.fn_register_ai_incident(
    p_system_id UUID,
    p_incident_type VARCHAR(50),
    p_severity VARCHAR(20),
    p_description TEXT,
    p_affected_count INTEGER DEFAULT NULL,
    p_affected_description TEXT DEFAULT NULL,
    p_reported_by VARCHAR(100) DEFAULT CURRENT_USER
)
RETURNS UUID AS $$
DECLARE
    v_incident_id UUID;
BEGIN
    INSERT INTO module3_ai_governance.ai_incident_log (
        system_id, incident_type, severity, incident_description,
        affected_individuals_count, affected_individuals_description, reported_by
    ) VALUES (
        p_system_id, p_incident_type, p_severity, p_description,
        p_affected_count, p_affected_description, p_reported_by
    )
    RETURNING incident_id INTO v_incident_id;

    -- If CRITICAL, auto-escalate to CCO and flag for external notification
    IF p_severity = 'CRITICAL' THEN
        UPDATE module3_ai_governance.ai_incident_log
        SET escalation_to = 'Chief Compliance Officer',
            external_notification_required = TRUE
        WHERE incident_id = v_incident_id;
    END IF;

    RETURN v_incident_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION module3_ai_governance.fn_register_ai_incident IS
  'Registers an AI incident with auto-escalation for CRITICAL severity. Returns incident_id for tracking. External notification may be required for ED-OCR, FTC, or state AG depending on incident type.';

-- ============================================================
-- FUNCTION: fn_schedule_bias_audit
-- Schedules a future bias audit and updates inventory.
-- ============================================================
CREATE OR REPLACE FUNCTION module3_ai_governance.fn_schedule_bias_audit(
    p_system_id UUID,
    p_auditor_name VARCHAR(100),
    p_auditor_role VARCHAR(100),
    p_audit_type VARCHAR(50) DEFAULT 'annual',
    p_protected_attribute VARCHAR(50) DEFAULT 'combined'
)
RETURNS UUID AS $$
DECLARE
    v_audit_id UUID;
    v_system_name VARCHAR(255);
BEGIN
    SELECT system_name INTO v_system_name
    FROM module3_ai_governance.ai_system_inventory
    WHERE system_id = p_system_id;

    INSERT INTO module3_ai_governance.bias_audit_log (
        system_id, audit_date, auditor_name, auditor_role,
        audit_type, protected_attribute, metric_used, metric_value,
        metric_threshold, threshold_source, pass_fail, sample_size,
        sample_date_range, audit_methodology, findings_summary
    ) VALUES (
        p_system_id, CURRENT_DATE + INTERVAL '30 days', p_auditor_name, p_auditor_role,
        p_audit_type, p_protected_attribute, 'TBD', 0.0,
        0.80, 'EEOC 80% rule (scheduled)', 'PENDING', 0,
        DATERANGE(CURRENT_DATE, CURRENT_DATE + INTERVAL '90 days'), 'Scheduled audit — methodology to be defined by auditor',
        'Audit scheduled for ' || v_system_name || ' on ' || (CURRENT_DATE + INTERVAL '30 days')::text
    )
    RETURNING audit_id INTO v_audit_id;

    RETURN v_audit_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION module3_ai_governance.fn_schedule_bias_audit IS
  'Schedules a future bias audit 30 days out and updates the system inventory next_audit_date. Auditor must define methodology before audit execution.';

-- ============================================================
-- TRIGGER: Auto-update inventory timestamps
-- ============================================================
CREATE OR REPLACE FUNCTION module3_ai_governance.trg_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    NEW.updated_by = CURRENT_USER;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ai_system_inventory_update
    BEFORE UPDATE ON module3_ai_governance.ai_system_inventory
    FOR EACH ROW
    EXECUTE FUNCTION module3_ai_governance.trg_update_timestamp();

-- ============================================================
-- TRIGGER: Auto-update next_bias_audit_date on completed audit
-- ============================================================
CREATE OR REPLACE FUNCTION module3_ai_governance.trg_audit_completion_update()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.remediation_status = 'completed' THEN
        UPDATE module3_ai_governance.ai_system_inventory
        SET last_bias_audit_date = NEW.audit_date,
            next_bias_audit_date = NEW.audit_date + INTERVAL '1 year'
        WHERE system_id = NEW.system_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_bias_audit_completion
    AFTER UPDATE ON module3_ai_governance.bias_audit_log
    FOR EACH ROW
    WHEN (OLD.remediation_status IS DISTINCT FROM NEW.remediation_status)
    EXECUTE FUNCTION module3_ai_governance.trg_audit_completion_update();

-- ============================================================
-- SEED DATA: Lamar AI Systems (Initial Inventory)
-- All Module 2 UC systems plus any third-party tools.
-- ============================================================
INSERT INTO module3_ai_governance.ai_system_inventory (
    system_name, system_description, system_owner, system_owner_department,
    technical_contact, procurement_date, vendor_name, data_sources, output_destinations,
    model_type, deployment_status, risk_tier, eu_ai_act_applicable, eu_ai_act_class,
    nist_ai_rmf_governance_map, last_risk_assessment_date, next_risk_assessment_date,
    last_bias_audit_date, next_bias_audit_date, model_version_current, pii_involved,
    fERPA_applicable, explainability_required, human_in_the_loop_required,
    human_in_the_loop_description, uco_node_id
) VALUES
(
    'Predictive Persistence Model (UC-01)',
    'Weekly activity composite scoring student persistence risk using Banner, Blackboard, Concourse, TouchNet, and StarRez data. Green/Yellow/Red tier classification.',
    'Student Success Director', 'Student Success Center',
    'Data Analytics Team', '2025-01-15', 'SMEPro (Internal)',
    '["Banner SIS", "Blackboard Ultra", "Concourse", "TouchNet", "StarRez"]',
    '["Advisor Dashboard", "Red-Tier Digest", "CoPilot"]',
    'predictive_model', 'production', 'high', FALSE, 'minimal',
    '{"govern": ["GOVERN-1.1", "GOVERN-1.2"], "map": ["MAP-1.1", "MAP-1.2"], "measure": ["MEASURE-1.1", "MEASURE-2.1"], "manage": ["MANAGE-1.1"]}',
    '2025-06-01', '2025-09-01',
    '2025-03-15', '2026-03-15', 'v2.1.0', TRUE, TRUE, TRUE, TRUE,
    'Advisors review Red-tier students and make intervention decisions. Model informs; human decides. Advisor override always available.',
    'UCO-MOD3-0001'
),
(
    'Transcript Crosswalk NLP Engine (UC-02)',
    'BERT-based NLP matching for transfer course equivalency evaluation. Confidence scoring for registrar one-click approval.',
    'Registrar', 'Office of the Registrar',
    'Data Analytics Team', '2025-02-01', 'SMEPro (Internal)',
    '["Banner SIS", "Concourse", "NSC"]',
    '["Registrar Portal", "Transcript Queue"]',
    'nlp_model', 'production', 'limited', FALSE, 'minimal',
    '{"govern": ["GOVERN-1.1"], "map": ["MAP-1.1"], "measure": ["MEASURE-1.1"], "manage": ["MANAGE-1.1"]}',
    '2025-06-01', '2025-12-01',
    '2025-04-01', '2026-04-01', 'v1.3.0', TRUE, TRUE, TRUE, TRUE,
    'Registrar reviews all NLP recommendations before approval. Auto-approve only for >0.95 confidence with canonical rule match. Human override always available.',
    'UCO-MOD3-0002'
),
(
    'Accreditation Gap NLP Analyzer (UC-03)',
    'BERT-based evidence matching against SACSCOC, AACSB, ABET, ACEN, and CCNE standards. Heat map generation and gap verdict classification.',
    'Accreditation Coordinator', 'Office of Institutional Research',
    'Data Analytics Team', '2025-03-01', 'SMEPro (Internal)',
    '["SharePoint", "Concourse", "Accreditation Documents"]',
    '["Accreditation Dashboard", "Gap Heat Map", "CoPilot"]',
    'nlp_model', 'pilot', 'high', FALSE, 'minimal',
    '{"govern": ["GOVERN-1.1", "GOVERN-1.2"], "map": ["MAP-1.1", "MAP-1.2"], "measure": ["MEASURE-1.1", "MEASURE-2.1"], "manage": ["MANAGE-1.1"]}',
    '2025-06-01', '2025-09-01',
    '2025-05-01', '2026-05-01', 'v1.0.0', FALSE, FALSE, TRUE, TRUE,
    'Accreditation Officer reviews all NLP verdicts. Assist-only; no auto-claims. Human review required for all gap assessments.',
    'UCO-MOD3-0003'
),
(
    'Outcome Alignment Auditor (UC-04)',
    'Nightly three-way alignment check: CLO (curriculum map) ↔ Syllabus (Concourse) ↔ Blackboard Gradebook (Ultra). Missing CLO, Ghost Assessment, and Weight Mismatch detection.',
    'AACSB Coordinator', 'College of Business',
    'Data Analytics Team', '2025-04-01', 'SMEPro (Internal)',
    '["Concourse", "Blackboard Ultra", "Curriculum Database"]',
    '["Chair Dashboard", "Alignment Report", "AACSB AoL Portfolio"]',
    'classification_model', 'production', 'limited', FALSE, 'minimal',
    '{"govern": ["GOVERN-1.1"], "map": ["MAP-1.1"], "measure": ["MEASURE-1.1"], "manage": ["MANAGE-1.1"]}',
    '2025-06-01', '2025-12-01',
    '2025-06-01', '2026-06-01', 'v1.2.0', FALSE, FALSE, TRUE, TRUE,
    'Department Chairs review flagged courses and apply fixes. Instructors retain full control over gradebook and syllabus. Model provides detection only; human makes changes.',
    'UCO-MOD3-0004'
),
(
    'Grading Load Analyzer (UC-05)',
    'Grading Load Index (GLI) calculation: Weight × Items × Rubric × Enrollment. Crunch-week heat map and GA allocation recommendations.',
    'Faculty Affairs Director', 'Office of the Provost',
    'Data Analytics Team', '2025-05-01', 'SMEPro (Internal)',
    '["Blackboard Ultra", "Banner SIS", "PeopleSoft HR"]',
    '["Chair Dashboard", "Dean Dashboard", "GA Allocation Report"]',
    'predictive_model', 'production', 'limited', FALSE, 'minimal',
    '{"govern": ["GOVERN-1.1"], "map": ["MAP-1.1"], "measure": ["MEASURE-1.1"], "manage": ["MANAGE-1.1"]}',
    '2025-06-01', '2025-12-01',
    '2025-06-01', '2026-06-01', 'v1.0.0', FALSE, FALSE, TRUE, TRUE,
    'Chairs review GLI recommendations and make GA allocation decisions. Dean has final approval for budget reallocations. Model provides recommendations; humans decide.',
    'UCO-MOD3-0005'
),
(
    'AI-Grader Routing Engine (UC-06)',
    'Complexity-weighted tier assignment for AI-assisted grading: NONE → AVA_FEEDBACK → AUTO_GRADE_L1 → AUTO_GRADE_L2 → HUMAN_REVIEW. Blackboard Ultra + Anthropic AVA integration.',
    'Academic Technology Director', 'Office of Academic Technology',
    'Data Analytics Team', '2025-06-01', 'Anthropic (AVA)',
    '["Blackboard Ultra", "Anthropic AVA API"]',
    '["Chair Dashboard", "AI-Grader Routing Report"]',
    'recommendation_system', 'pilot', 'high', FALSE, 'minimal',
    '{"govern": ["GOVERN-1.1", "GOVERN-1.2", "GOVERN-3.1"], "map": ["MAP-1.1", "MAP-1.2"], "measure": ["MEASURE-1.1", "MEASURE-2.1"], "manage": ["MANAGE-1.1", "MANAGE-2.1"]}',
    '2025-06-01', '2025-09-01',
    '2025-06-01', '2026-06-01', 'v0.9.0', TRUE, TRUE, TRUE, TRUE,
    'Lead Professor retains final grade authority for all tiers. AVA provides feedback only; human reviews and approves. Chair approval required for tier assignment. Student appeal process with human review.',
    'UCO-MOD3-0006'
),
(
    'Enrollment Funnel Analytics (UC-07)',
    'Stage conversion and cycle time analytics from Banner Admissions → Banner FA → TouchNet → StarRez → Registration → Census. Dropout analysis and lead source attribution.',
    'Enrollment Manager', 'Office of Admissions',
    'Data Analytics Team', '2025-01-01', 'SMEPro (Internal)',
    '["Banner Admissions", "Banner FA", "TouchNet", "StarRez"]',
    '["Admissions Dashboard", "Funnel Report", "Dean Dashboard"]',
    'predictive_model', 'production', 'limited', FALSE, 'minimal',
    '{"govern": ["GOVERN-1.1"], "map": ["MAP-1.1"], "measure": ["MEASURE-1.1"], "manage": ["MANAGE-1.1"]}',
    '2025-06-01', '2025-12-01',
    '2025-06-01', '2026-06-01', 'v1.1.0', TRUE, TRUE, TRUE, TRUE,
    'Admissions team uses funnel insights for recruitment planning. No automated decisions affecting individual students. All decisions are strategic and aggregate.',
    'UCO-MOD3-0007'
),
(
    'Continuous Compliance Monitoring (UC-08)',
    'Claude MCP + Firecrawl MCP agent swarm monitoring Federal Register, Texas Register, agency RSS, and court dockets. Regulatory change detection with UDM impact mapping.',
    'Compliance Officer', 'Office of Legal Affairs',
    'Agent Swarm Team', '2025-06-01', 'SMEPro (Internal)',
    '["Federal Register", "Texas Register", "Agency RSS", "Court Dockets"]',
    '["Compliance Alert Dashboard", "Trace Chain", "CoPilot"]',
    'anomaly_detector', 'production', 'high', FALSE, 'minimal',
    '{"govern": ["GOVERN-1.1", "GOVERN-1.2", "GOVERN-5.1"], "map": ["MAP-1.1", "MAP-1.2"], "measure": ["MEASURE-1.1", "MEASURE-3.1"], "manage": ["MANAGE-1.1", "MANAGE-3.1"]}',
    '2025-06-01', '2025-09-01',
    '2025-06-01', '2026-06-01', 'v1.0.0', FALSE, FALSE, TRUE, TRUE,
    'Compliance Officer reviews all CRITICAL and HIGH alerts. Human-in-the-loop mandatory for all regulatory changes. Trace chain deployment for immutable audit trail. No auto-implementation.',
    'UCO-MOD3-0008'
),
(
    'Anthropic AVA Assisted Feedback (Third-Party)',
    'Third-party generative AI providing formative feedback on student assignments. Integrated with Blackboard Ultra via LTI.',
    'Academic Technology Director', 'Office of Academic Technology',
    'Anthropic Support', '2025-06-01', 'Anthropic',
    '["Blackboard Ultra", "Student Submissions"]',
    '["Blackboard Gradebook", "Student Feedback Panel"]',
    'generative_model', 'pilot', 'high', FALSE, 'minimal',
    '{"govern": ["GOVERN-1.1", "GOVERN-1.2", "GOVERN-5.2"], "map": ["MAP-1.1"], "measure": ["MEASURE-1.1", "MEASURE-2.1", "MEASURE-2.2"], "manage": ["MANAGE-1.1", "MANAGE-2.1"]}',
    '2025-06-01', '2025-09-01',
    '2025-06-01', '2026-06-01', 'v1.0.0', TRUE, TRUE, TRUE, TRUE,
    'Lead Professor reviews all AVA feedback before release to students. Professor can edit, reject, or replace feedback. No auto-release. Student data governed by FERPA and vendor BAA.',
    'UCO-MOD3-0009'
);

-- ============================================================
-- SEED DATA: Risk Register for High-Risk Systems
-- ============================================================
INSERT INTO module3_ai_governance.model_risk_register (
    system_id, risk_category, risk_description, risk_likelihood, risk_impact,
    risk_owner, mitigation_measures, residual_risk_score, monitoring_method,
    alert_threshold, next_review_date, uco_node_id
)
SELECT
    system_id,
    'algorithmic_bias',
    'Predictive model may disproportionately flag students from underrepresented groups as high-risk due to historical enrollment patterns. EEOC disparate impact risk.',
    3, 4,
    'Student Success Director',
    'Annual bias audits on race, gender, and socioeconomic status. Demographic parity monitoring quarterly. Advisor override always available. Model retraining with balanced datasets.',
    6,
    'Monthly demographic parity dashboard.',
    'Disparate impact ratio < 0.80 triggers alert. Advisor override rate tracked.',
    '2025-10-01',
    'UCO-MOD3-0001-R1'
FROM module3_ai_governance.ai_system_inventory
WHERE system_name = 'Predictive Persistence Model (UC-01)';

INSERT INTO module3_ai_governance.model_risk_register (
    system_id, risk_category, risk_description, risk_likelihood, risk_impact,
    risk_owner, mitigation_measures, residual_risk_score, monitoring_method,
    alert_threshold, next_review_date, uco_node_id
)
SELECT
    system_id,
    'overreliance',
    'Advisors may over-rely on Red-tier flags without considering individual student context. Risk of stereotyping or missing students who don't fit model patterns.',
    4, 3,
    'Student Success Director',
    'Mandatory advisor training on model limitations (annual). Student Success Center case review for all Red-tier students. Advisor must document individual context before intervention.',
    6,
    'Quarterly advisor feedback surveys. Intervention rate vs. model prediction rate.',
    'Advisor intervention rate < 50% of Red-tier flagged students triggers review.',
    '2025-10-01',
    'UCO-MOD3-0001-R2'
FROM module3_ai_governance.ai_system_inventory
WHERE system_name = 'Predictive Persistence Model (UC-01)';

INSERT INTO module3_ai_governance.model_risk_register (
    system_id, risk_category, risk_description, risk_likelihood, risk_impact,
    risk_owner, mitigation_measures, residual_risk_score, monitoring_method,
    alert_threshold, next_review_date, uco_node_id
)
SELECT
    system_id,
    'data_privacy',
    'Student activity data (BB logins, assignment submissions, payment status) used for persistence scoring. FERPA compliance required. Data breach risk if not properly secured.',
    2, 5,
    'Chief Information Security Officer',
    'Data encrypted at rest and in transit. Role-based access control. Annual security audit. Data retention limited to 7 years (FERPA). Student consent obtained at enrollment.',
    4,
    'Annual security audit. Quarterly access review.',
    'Any unauthorized access triggers immediate incident response.',
    '2025-10-01',
    'UCO-MOD3-0001-R3'
FROM module3_ai_governance.ai_system_inventory
WHERE system_name = 'Predictive Persistence Model (UC-01)';

INSERT INTO module3_ai_governance.model_risk_register (
    system_id, risk_category, risk_description, risk_likelihood, risk_impact,
    risk_owner, mitigation_measures, residual_risk_score, monitoring_method,
    alert_threshold, next_review_date, uco_node_id
)
SELECT
    system_id,
    'lack_of_explainability',
    'AI grading recommendations (AVA feedback) may not be explainable to students or faculty, leading to trust issues and appeals.',
    3, 4,
    'Academic Technology Director',
    'SHAP-based explainability for all AI-graded items. Student appeal process with mandatory human review. Professor must approve all feedback before release.',
    6,
    'Monthly explainability log review. Student appeal rate tracking.',
    'Student appeal rate > 10% triggers model review. Explainability coverage < 95% triggers alert.',
    '2025-10-01',
    'UCO-MOD3-0006-R1'
FROM module3_ai_governance.ai_system_inventory
WHERE system_name = 'AI-Grader Routing Engine (UC-06)';

INSERT INTO module3_ai_governance.model_risk_register (
    system_id, risk_category, risk_description, risk_likelihood, risk_impact,
    risk_owner, mitigation_measures, residual_risk_score, monitoring_method,
    alert_threshold, next_review_date, uco_node_id
)
SELECT
    system_id,
    'third_party_dependency',
    'Anthropic AVA API is a third-party dependency. Service outage, pricing changes, or contract termination could disrupt AI grading operations.',
    3, 4,
    'Academic Technology Director',
    'Fallback to human grading on AVA outage. Contract includes 99.9% SLA. Annual vendor assessment. Backup grading workflow documented. Multi-year contract with price caps.',
    6,
    'Monthly vendor uptime monitoring. Annual contract review.',
    'AVA uptime < 99.9% for 2 consecutive months triggers vendor review.',
    '2025-10-01',
    'UCO-MOD3-0006-R2'
FROM module3_ai_governance.ai_system_inventory
WHERE system_name = 'AI-Grader Routing Engine (UC-06)';

INSERT INTO module3_ai_governance.model_risk_register (
    system_id, risk_category, risk_description, risk_likelihood, risk_impact,
    risk_owner, mitigation_measures, residual_risk_score, monitoring_method,
    alert_threshold, next_review_date, uco_node_id
)
SELECT
    system_id,
    'regulatory_noncompliance',
    'Compliance monitoring agent may miss regulatory changes in non-English sources, state-level emergency orders, or agency guidance documents not published in Federal Register.',
    3, 5,
    'Compliance Officer',
    'Multi-source monitoring (Federal Register + state registers + agency RSS + listservs). Human review of all alerts. Quarterly coverage gap analysis. Manual backup checks for high-risk agencies.',
    6,
    'Monthly coverage gap analysis. Quarterly false negative review.',
    'Any missed regulatory change with institutional impact triggers process review.',
    '2025-10-01',
    'UCO-MOD3-0008-R1'
FROM module3_ai_governance.ai_system_inventory
WHERE system_name = 'Continuous Compliance Monitoring (UC-08)';

-- ============================================================
-- END OF MIGRATION V14
-- ============================================================
