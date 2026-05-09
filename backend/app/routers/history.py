# -*- coding: utf-8 -*-
import json
from typing import Any, Dict
from fastapi import APIRouter, Depends, HTTPException
from app.core.dependencies import get_current_user, check_subscription
from app.core.database import get_connection

router = APIRouter(prefix="/history", tags=["history"])

def _parse_assessment(row) -> Dict:
    item = dict(row)
    item["dimensions"] = json.loads(item.pop("dimensions_json"))
    low_dims = [d for d in item["dimensions"] if d["score"] <= 4]
    item["patterns"] = [
        {"dimension": d["dimension"], "label": d["label"], "score": d["score"]}
        for d in low_dims
    ]
    return item

# IMPORTANTE: rotas estáticas ANTES do wildcard /{assessment_id}
@router.get("")
def get_history(user: Dict[str, Any] = Depends(get_current_user)):
    check_subscription(user)
    conn = get_connection()
    rows = conn.execute(
        "SELECT * FROM assessments WHERE user_id=? ORDER BY created_at DESC",
        (user["id"],)).fetchall()
    conn.close()
    return {"items": [_parse_assessment(row) for row in rows]}

@router.get("/with-patterns")
def get_history_with_patterns(user: Dict[str, Any] = Depends(get_current_user)):
    check_subscription(user)
    conn = get_connection()
    rows = conn.execute(
        "SELECT * FROM assessments WHERE user_id=? ORDER BY created_at DESC",
        (user["id"],)).fetchall()
    conn.close()
    return {"items": [_parse_assessment(row) for row in rows]}

@router.get("/{assessment_id}")
def get_history_detail(assessment_id: str, user: Dict[str, Any] = Depends(get_current_user)):
    check_subscription(user)
    conn = get_connection()
    assessment_row = conn.execute(
        "SELECT * FROM assessments WHERE id=? AND user_id=?",
        (assessment_id, user["id"])).fetchone()
    if not assessment_row:
        conn.close()
        raise HTTPException(status_code=404, detail="Avaliação não encontrada.")
    assessment = _parse_assessment(assessment_row)
    rec_row = conn.execute(
        "SELECT * FROM recommendations WHERE assessment_id=? AND user_id=? ORDER BY created_at DESC LIMIT 1",
        (assessment_id, user["id"])).fetchone()
    conn.close()
    recommendation = None
    if rec_row:
        rec = dict(rec_row)
        rec["daily_actions"] = json.loads(rec.pop("daily_actions_json"))
        recommendation = rec
    return {"assessment": assessment, "recommendation": recommendation}
