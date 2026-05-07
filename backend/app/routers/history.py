import json
from typing import Any, Dict
from fastapi import APIRouter, Depends, HTTPException
from app.core.dependencies import get_current_user, check_subscription
from app.core.database import get_connection

router = APIRouter(prefix="/history", tags=["history"])

@router.get("")
def get_history(user: Dict[str, Any] = Depends(get_current_user)):
    check_subscription(user)
    conn = get_connection()
    rows = conn.execute(
        "SELECT * FROM assessments WHERE user_id=? ORDER BY created_at DESC",
        (user["id"],)).fetchall()
    conn.close()
    items = []
    for row in rows:
        item = dict(row)
        item["dimensions"] = json.loads(item.pop("dimensions_json"))
        low_dims = [d for d in item["dimensions"] if d["score"] <= 4]
        item["patterns"] = [{"dimension": d["dimension"], "label": d["label"], "score": d["score"]} for d in low_dims]
        items.append(item)
    return {"items": items}

@router.get("/with-patterns")
def get_history_with_patterns(user: Dict[str, Any] = Depends(get_current_user)):
    check_subscription(user)
    conn = get_connection()
    rows = conn.execute(
        "SELECT * FROM assessments WHERE user_id=? ORDER BY created_at DESC",
        (user["id"],)).fetchall()
    conn.close()
    items = []
    for row in rows:
        item = dict(row)
        item["dimensions"] = json.loads(item.pop("dimensions_json"))
        low_dims = [d for d in item["dimensions"] if d["score"] <= 4]
        item["patterns"] = [{"dimension": d["dimension"], "label": d["label"], "score": d["score"]} for d in low_dims]
        items.append(item)
    return {"items": items}

@router.get("/{assessment_id}")
def get_history_detail(
    assessment_id: str,
    user: Dict[str, Any] = Depends(get_current_user)
):
    check_subscription(user)
    conn = get_connection()

    assessment_row = conn.execute(
        "SELECT * FROM assessments WHERE id=? AND user_id=?",
        (assessment_id, user["id"])).fetchone()

    if not assessment_row:
        conn.close()
        raise HTTPException(status_code=404, detail="Avaliacao nao encontrada.")

    assessment = dict(assessment_row)
    assessment["dimensions"] = json.loads(assessment.pop("dimensions_json"))
    low_dims = [d for d in assessment["dimensions"] if d["score"] <= 4]
    assessment["patterns"] = [{"dimension": d["dimension"], "label": d["label"], "score": d["score"]} for d in low_dims]

    rec_row = conn.execute(
        "SELECT * FROM recommendations WHERE assessment_id=? AND user_id=? ORDER BY created_at DESC LIMIT 1",
        (assessment_id, user["id"])).fetchone()
    conn.close()

    recommendation = None
    if rec_row:
        rec = dict(rec_row)
        rec["daily_actions"] = json.loads(rec.pop("daily_actions_json"))
        recommendation = rec

    return {
        "assessment": assessment,
        "recommendation": recommendation,
    }
