"""
IOS+ Edu Reporter API — FastAPI
Simulates UC-01 through UC-05 with synthetic data
"""

from fastapi import FastAPI, HTTPException, Header, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict, Optional, Any
import os
import random
import datetime
import uuid

app = FastAPI(
    title="IOS+ Edu Reporter API",
    version="1.0.0-mvp",
    description="Simulates Edu Reporter objectives UC-01 through UC-05 with synthetic data"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory synthetic data stores (replaced by DB in production)
students_db = []
courses_db = []
transcripts_db = []
cl alignments_db = []

# ============================================================
# Health Endpoints
# ============================================================

@app.get("/v1/health/live")
def health_live():
    return {"status": "alive", "timestamp": datetime.datetime.utcnow().isoformat()}

@app.get("/v1/health/ready")
def health_ready():
    return {"status": "ready", "services": {"api": "up"}, "timestamp": datetime.datetime.utcnow().isoformat()}

@app.get("/")
def root():
    return {
        "service": "Edu Reporter API",
        "version": "1.0.0-mvp",
        "objectives": ["uc-01", "uc-02", "uc-03", "uc-04", "uc-05"],
        "endpoints": [
            "/v1/health/live",
            "/v1/health/ready",
            "/v1/uc-01",
            "/v1/uc-02",
            "/v1/uc-03",
            "/v1/uc-04",
            "/v1/uc-05"
        ]
    }

# ============================================================
# UC-01: Predictive Persistence — Student Risk Scoring
# ============================================================

class StudentRiskScore(BaseModel):
    syn_id: str
    student_id: str
    composite_score: int  # 0-100
    tier: str  # Green, Yellow, Red
    top_factors: List[str]
    last_updated: str
    advisor_notes: Optional[str] = None

class UC01Response(BaseModel):
    objective: str = "uc-01"
    description: str = "Predictive Persistence — weekly 0-100 composite, Green/Yellow/Red tiers"
    generated_at: str
    total_students: int
    green_count: int
    yellow_count: int
    red_count: int
    students: List[StudentRiskScore]
    major_concentrations: List[Dict[str, Any]]

@app.get("/v1/uc-01", response_model=UC01Response)
def get_uc01(
    x_user_role: str = Header("advisor"),
    x_user_syn_id: str = Header("demo")
):
    """Returns student persistence risk scores with tier breakdown."""
    random.seed(42)  # Deterministic for demo
    
    students = []
    green_count = yellow_count = red_count = 0
    
    factors_pool = [
        "Low attendance (last 14 days)",
        "Missing early-alert response",
        "Financial aid verification pending",
        "Academic probation status",
        "First-generation, no family support contact",
        "Course withdrawal pattern",
        "Low Blackboard engagement score",
        "Housing insecurity flag",
        "Part-time + full-time work conflict",
        "No advising appointment this term"
    ]
    
    for i in range(1, 201):
        score = random.randint(15, 98)
        if score >= 70:
            tier = "Green"
            green_count += 1
        elif score >= 40:
            tier = "Yellow"
            yellow_count += 1
        else:
            tier = "Red"
            red_count += 1
        
        top_factors = random.sample(factors_pool, k=random.randint(2, 4))
        
        students.append({
            "syn_id": f"SYN-{i:05d}",
            "student_id": f"LU-{2024 + random.randint(0, 3)}-{random.randint(10000, 99999)}",
            "composite_score": score,
            "tier": tier,
            "top_factors": top_factors,
            "last_updated": datetime.datetime.utcnow().isoformat(),
            "advisor_notes": None if tier == "Green" else f"Outreach attempted {random.randint(1, 3)} time(s)"
        })
    
    major_concentrations = [
        {"major": "MIS", "red_pct": 21, "yellow_pct": 18, "green_pct": 61},
        {"major": "Marketing", "red_pct": 20, "yellow_pct": 22, "green_pct": 58},
        {"major": "Accounting", "red_pct": 14, "yellow_pct": 19, "green_pct": 67},
        {"major": "Nursing", "red_pct": 8, "yellow_pct": 15, "green_pct": 77},
        {"major": "Engineering", "red_pct": 12, "yellow_pct": 20, "green_pct": 68}
    ]
    
    return {
        "objective": "uc-01",
        "description": "Predictive Persistence — weekly 0-100 composite, Green/Yellow/Red tiers",
        "generated_at": datetime.datetime.utcnow().isoformat(),
        "total_students": len(students),
        "green_count": green_count,
        "yellow_count": yellow_count,
        "red_count": red_count,
        "students": students,
        "major_concentrations": major_concentrations
    }

# ============================================================
# UC-02: Transcript Crosswalk — Equivalency Scoring
# ============================================================

class EquivalencyItem(BaseModel):
    transcript_id: str
    source_institution: str
    source_course: str
    source_credits: float
    lu_equivalent: Optional[str]
    confidence_score: float  # 0.0-1.0
    ecs_band: str  # High, Medium, Low
    status: str  # Approved, Modified, Pending, Rejected
    evaluator: Optional[str] = None
    notes: Optional[str] = None

class UC02Response(BaseModel):
    objective: str = "uc-02"
    description: str = "Transcript Crosswalk — confidence-scored equivalency"
    generated_at: str
    total_transcripts: int
    approved_count: int
    pending_count: int
    rejected_count: int
    modified_count: int
    items: List[EquivalencyItem]

@app.get("/v1/uc-02", response_model=UC02Response)
def get_uc02(
    x_user_role: str = Header("registrar"),
    x_user_syn_id: str = Header("demo")
):
    """Returns transcript equivalency queue with confidence scores."""
    random.seed(42)
    
    institutions = [
        "Lone Star College", "San Jacinto College", "Austin Community College",
        "Tarrant County College", "Houston Community College", "Tyler Junior College"
    ]
    
    lu_courses = ["ACCT 5301", "ECON 5300", "MIS 5300", "MKTG 5300", "FINA 5300", "MGMT 5300"]
    source_courses = ["ACCT 2311", "ECON 2301", "BCIS 1305", "MKTG 1311", "FINA 3301", "BUSI 1301"]
    
    items = []
    approved = pending = rejected = modified = 0
    
    for i in range(1, 26):
        confidence = round(random.uniform(0.35, 0.98), 2)
        if confidence >= 0.90:
            band = "High"
            status = random.choice(["Approved", "Approved"])
        elif confidence >= 0.65:
            band = "Medium"
            status = random.choice(["Modified", "Pending", "Approved"])
        else:
            band = "Low"
            status = random.choice(["Pending", "Rejected"])
        
        if status == "Approved": approved += 1
        elif status == "Pending": pending += 1
        elif status == "Rejected": rejected += 1
        elif status == "Modified": modified += 1
        
        items.append({
            "transcript_id": f"TRX-{i:04d}",
            "source_institution": random.choice(institutions),
            "source_course": random.choice(source_courses),
            "source_credits": round(random.uniform(2.0, 4.0), 1),
            "lu_equivalent": random.choice(lu_courses) if status in ["Approved", "Modified"] else None,
            "confidence_score": confidence,
            "ecs_band": band,
            "status": status,
            "evaluator": "Auto" if band == "High" else "Registrar Staff",
            "notes": "Auto-approved by equivalency engine" if band == "High" else "Requires manual review"
        })
    
    return {
        "objective": "uc-02",
        "description": "Transcript Crosswalk — confidence-scored equivalency",
        "generated_at": datetime.datetime.utcnow().isoformat(),
        "total_transcripts": len(items),
        "approved_count": approved,
        "pending_count": pending,
        "rejected_count": rejected,
        "modified_count": modified,
        "items": items
    }

# ============================================================
# UC-03: Accreditation Gap Analysis — Evidence Heat Map
# ============================================================

class StandardItem(BaseModel):
    standard_id: str
    standard_name: str
    compliance_score: int  # 0-100
    evidence_count: int
    gaps: List[str]
    status: str  # Compliant, Partial, Non-compliant

class UC03Response(BaseModel):
    objective: str = "uc-03"
    description: str = "Accreditation Gap Analysis — standards-matched evidence heat map"
    generated_at: str
    accrediting_body: str
    standards: List[StandardItem]
    overall_score: int
    critical_gaps: int

@app.get("/v1/uc-03", response_model=UC03Response)
def get_uc03(
    x_user_role: str = Header("accreditation_liaison"),
    x_user_syn_id: str = Header("demo")
):
    """Returns accreditation gap analysis for SACSCOC standards."""
    
    standards = [
        {
            "standard_id": "12.1",
            "standard_name": "Mission",
            "compliance_score": 95,
            "evidence_count": 12,
            "gaps": [],
            "status": "Compliant"
        },
        {
            "standard_id": "12.2",
            "standard_name": "Governance and Administration",
            "compliance_score": 88,
            "evidence_count": 8,
            "gaps": ["Board meeting minutes missing Q3 2025"],
            "status": "Partial"
        },
        {
            "standard_id": "12.3",
            "standard_name": "Institutional Effectiveness",
            "compliance_score": 92,
            "evidence_count": 15,
            "gaps": [],
            "status": "Compliant"
        },
        {
            "standard_id": "12.4",
            "standard_name": "Educational Programs",
            "compliance_score": 78,
            "evidence_count": 22,
            "gaps": ["Program review cycle overdue for 3 programs"],
            "status": "Partial"
        },
        {
            "standard_id": "12.5",
            "standard_name": "Faculty",
            "compliance_score": 85,
            "evidence_count": 18,
            "gaps": ["Credentials file incomplete for 4 adjuncts"],
            "status": "Partial"
        },
        {
            "standard_id": "12.6",
            "standard_name": "Student Achievement",
            "compliance_score": 90,
            "evidence_count": 14,
            "gaps": [],
            "status": "Compliant"
        },
        {
            "standard_id": "12.7",
            "standard_name": "Learning Resources and Services",
            "compliance_score": 82,
            "evidence_count": 10,
            "gaps": ["Library assessment data missing 2024-2025"],
            "status": "Partial"
        },
        {
            "standard_id": "12.8",
            "standard_name": "Student Support Services",
            "compliance_score": 91,
            "evidence_count": 16,
            "gaps": [],
            "status": "Compliant"
        },
        {
            "standard_id": "12.9",
            "standard_name": "Financial Resources",
            "compliance_score": 87,
            "evidence_count": 11,
            "gaps": ["Audit documentation needs update"],
            "status": "Partial"
        },
        {
            "standard_id": "12.10",
            "standard_name": "Physical Resources",
            "compliance_score": 93,
            "evidence_count": 9,
            "gaps": [],
            "status": "Compliant"
        }
    ]
    
    overall = round(sum(s["compliance_score"] for s in standards) / len(standards))
    critical = sum(1 for s in standards if s["status"] == "Non-compliant")
    
    return {
        "objective": "uc-03",
        "description": "Accreditation Gap Analysis — standards-matched evidence heat map",
        "generated_at": datetime.datetime.utcnow().isoformat(),
        "accrediting_body": "SACSCOC",
        "standards": standards,
        "overall_score": overall,
        "critical_gaps": critical
    }

# ============================================================
# UC-04: Outcome Alignment Auditor — CLO Syllabus Gradebook
# ============================================================

class AlignmentFlag(BaseModel):
    flag_id: str
    course_id: str
    course_name: str
    flag_type: str  # Missing CLO, Ghost Assessment, Weight Mismatch
    severity: str  # Critical, Warning, Info
    description: str
    suggested_action: str
    status: str  # Open, Resolved, In Progress

class UC04Response(BaseModel):
    objective: str = "uc-04"
    description: str = "Outcome Alignment Auditor — CLO ↔ syllabus ↔ gradebook three-way audit"
    generated_at: str
    total_courses: int
    flag_count: int
    critical_count: int
    warning_count: int
    flags: List[AlignmentFlag]

@app.get("/v1/uc-04", response_model=UC04Response)
def get_uc04(
    x_user_role: str = Header("department_chair"),
    x_user_syn_id: str = Header("demo")
):
    """Returns CLO alignment audit flags for courses."""
    
    flags = [
        {
            "flag_id": "UC04-001",
            "course_id": "ACCT 5301-01",
            "course_name": "Financial Accounting",
            "flag_type": "Missing CLO",
            "severity": "Critical",
            "description": "Catalog lists 5 CLOs; Concourse syllabus shows 3; gradebook maps 2",
            "suggested_action": "Update Concourse syllabus to match catalog CLOs; remap gradebook",
            "status": "Open"
        },
        {
            "flag_id": "UC04-002",
            "course_id": "ECON 5300-02",
            "course_name": "Managerial Economics",
            "flag_type": "Ghost Assessment",
            "severity": "Warning",
            "description": "Gradebook contains assignment 'Midterm 2' with 0% weight; no matching CLO",
            "suggested_action": "Remove or remap unused gradebook item to appropriate CLO",
            "status": "In Progress"
        },
        {
            "flag_id": "UC04-003",
            "course_id": "MIS 5300-01",
            "course_name": "Information Systems",
            "flag_type": "Weight Mismatch",
            "severity": "Warning",
            "description": "Syllabus states 'Final Project: 25%'; gradebook weight is 30% (+5% discrepancy)",
            "suggested_action": "Reconcile syllabus and gradebook weights; update whichever is incorrect",
            "status": "Open"
        },
        {
            "flag_id": "UC04-004",
            "course_id": "MKTG 5300-01",
            "course_name": "Marketing Management",
            "flag_type": "Missing CLO",
            "severity": "Critical",
            "description": "CLO 4.2 (Digital Analytics) has no mapped assessment in gradebook",
            "suggested_action": "Add assessment aligned to CLO 4.2 or update catalog to remove",
            "status": "Open"
        },
        {
            "flag_id": "UC04-005",
            "course_id": "FINA 5300-03",
            "course_name": "Corporate Finance",
            "flag_type": "Weight Mismatch",
            "severity": "Info",
            "description": "Discussion board weight: syllabus 10%, gradebook 12%",
            "suggested_action": "Minor discrepancy; update to match syllabus or gradebook",
            "status": "Resolved"
        }
    ]
    
    return {
        "objective": "uc-04",
        "description": "Outcome Alignment Auditor — CLO ↔ syllabus ↔ gradebook three-way audit",
        "generated_at": datetime.datetime.utcnow().isoformat(),
        "total_courses": 86,
        "flag_count": len(flags),
        "critical_count": sum(1 for f in flags if f["severity"] == "Critical"),
        "warning_count": sum(1 for f in flags if f["severity"] == "Warning"),
        "flags": flags
    }

# ============================================================
# UC-05: Grading Load Analyzer — GLI Computation
# ============================================================

class GLIItem(BaseModel):
    section_id: str
    course_id: str
    course_name: str
    enrollment: int
    weight: int  # percentage
    items: int  # number of assignments
    rubric_complexity: float  # 1.0-5.0
    gli: float  # Grading Load Index
    tier: str  # Critical, High, Moderate, Low
    ga_hours_recommended: float

class UC05Response(BaseModel):
    objective: str = "uc-05"
    description: str = "Grading Load Analyzer — GLI = Weight × Items × Rubric × Enrollment"
    generated_at: str
    total_sections: int
    critical_sections: int
    high_sections: int
    gli_data: List[GLIItem]
    college_summary: List[Dict[str, Any]]

@app.get("/v1/uc-05", response_model=UC05Response)
def get_uc05(
    x_user_role: str = Header("dean"),
    x_user_syn_id: str = Header("demo")
):
    """Returns Grading Load Index (GLI) analysis for course sections."""
    
    gli_data = [
        {
            "section_id": "ACCT-5301-01-FA26",
            "course_id": "ACCT 5301",
            "course_name": "Financial Accounting",
            "enrollment": 118,
            "weight": 40,
            "items": 12,
            "rubric_complexity": 3.5,
            "gli": 142.0,
            "tier": "Critical",
            "ga_hours_recommended": 14.2
        },
        {
            "section_id": "ECON-5300-01-FA26",
            "course_id": "ECON 5300",
            "course_name": "Managerial Economics",
            "enrollment": 120,
            "weight": 30,
            "items": 8,
            "rubric_complexity": 2.0,
            "gli": 24.0,
            "tier": "Low",
            "ga_hours_recommended": 2.4
        },
        {
            "section_id": "MIS-5300-01-FA26",
            "course_id": "MIS 5300",
            "course_name": "Information Systems",
            "enrollment": 95,
            "weight": 35,
            "items": 10,
            "rubric_complexity": 3.0,
            "gli": 71.2,
            "tier": "Moderate",
            "ga_hours_recommended": 7.1
        },
        {
            "section_id": "MKTG-5300-02-FA26",
            "course_id": "MKTG 5300",
            "course_name": "Marketing Management",
            "enrollment": 85,
            "weight": 25,
            "items": 15,
            "rubric_complexity": 2.5,
            "gli": 53.4,
            "tier": "Moderate",
            "ga_hours_recommended": 5.3
        },
        {
            "section_id": "FINA-5300-01-FA26",
            "course_id": "FINA 5300",
            "course_name": "Corporate Finance",
            "enrollment": 110,
            "weight": 45,
            "items": 14,
            "rubric_complexity": 4.0,
            "gli": 123.2,
            "tier": "High",
            "ga_hours_recommended": 12.3
        },
        {
            "section_id": "MGMT-5300-03-FA26",
            "course_id": "MGMT 5300",
            "course_name": "Strategic Management",
            "enrollment": 90,
            "weight": 50,
            "items": 18,
            "rubric_complexity": 3.5,
            "gli": 113.4,
            "tier": "High",
            "ga_hours_recommended": 11.3
        }
    ]
    
    college_summary = [
        {"college": "College of Business", "avg_gli": 58.2, "total_sections": 8, "total_ga_hours": 58.2},
        {"college": "College of Engineering", "avg_gli": 45.1, "total_sections": 6, "total_ga_hours": 45.1},
        {"college": "College of Arts & Sciences", "avg_gli": 32.8, "total_sections": 12, "total_ga_hours": 32.8}
    ]
    
    return {
        "objective": "uc-05",
        "description": "Grading Load Analyzer — GLI = Weight × Items × Rubric × Enrollment",
        "generated_at": datetime.datetime.utcnow().isoformat(),
        "total_sections": len(gli_data),
        "critical_sections": sum(1 for g in gli_data if g["tier"] == "Critical"),
        "high_sections": sum(1 for g in gli_data if g["tier"] == "High"),
        "gli_data": gli_data,
        "college_summary": college_summary
    }
