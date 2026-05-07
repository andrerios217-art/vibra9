import json, uuid
from typing import Any, Dict, List
from fastapi import APIRouter, Depends
from app.core.dependencies import get_current_user, check_subscription
from app.core.database import get_connection
from app.data.dimensions import DIMENSIONS

router = APIRouter(prefix="/patterns", tags=["patterns"])

def _generate_patterns(assessments: List[Dict]) -> List[Dict]:
    if not assessments:
        return []
    dim_scores: Dict[str, List[int]] = {k: [] for k in DIMENSIONS}
    for assessment in assessments:
        for d in assessment.get("dimensions", []):
            key = d.get("dimension")
            if key in dim_scores:
                dim_scores[key].append(d.get("score", 0))
    patterns = []
    for dim_key, scores in dim_scores.items():
        if len(scores) < 2:
            continue
        avg = sum(scores) / len(scores)
        low_count = sum(1 for s in scores if s <= 5)
        if low_count >= 2 or avg <= 5:
            trend = "declining" if scores[-1] < scores[0] else "improving" if scores[-1] > scores[0] else "stable"
            label = DIMENSIONS[dim_key]
            patterns.append({
                "id": str(uuid.uuid4()),
                "dimension": dim_key,
                "label": label,
                "occurrences": low_count,
                "avg_score": round(avg, 1),
                "trend": trend,
                "message": f"{label} apareceu com atencao em {low_count} das suas avaliacoes recentes."
            })
    patterns.sort(key=lambda x: x["avg_score"])
    return patterns[:5]

def _get_assessments(user_id: str, limit: int = 10) -> List[Dict]:
    conn = get_connection()
    rows = conn.execute(
        "SELECT * FROM assessments WHERE user_id=? ORDER BY created_at DESC LIMIT ?",
        (user_id, limit)).fetchall()
    conn.close()
    result = []
    for row in rows:
        item = dict(row)
        item["dimensions"] = json.loads(item["dimensions_json"])
        result.append(item)
    return result

@router.post("/backfill")
def backfill_patterns(user: Dict[str, Any] = Depends(get_current_user)):
    check_subscription(user)
    assessments = _get_assessments(user["id"], limit=10)
    patterns = _generate_patterns(assessments)
    return {"patterns": patterns, "generated": len(patterns)}

@router.get("/latest")
def get_latest_patterns(user: Dict[str, Any] = Depends(get_current_user)):
    check_subscription(user)
    assessments = _get_assessments(user["id"], limit=10)
    patterns = _generate_patterns(assessments)
    return {"patterns": patterns}

@router.get("/recurring")
def get_recurring_patterns(user: Dict[str, Any] = Depends(get_current_user)):
    check_subscription(user)
    assessments = _get_assessments(user["id"], limit=20)
    if not assessments:
        return {"patterns": []}
    dim_scores: Dict[str, List[int]] = {k: [] for k in DIMENSIONS}
    for assessment in assessments:
        for d in assessment.get("dimensions", []):
            key = d.get("dimension")
            if key in dim_scores:
                dim_scores[key].append(d.get("score", 0))
    recurring = []
    for dim_key, scores in dim_scores.items():
        if len(scores) < 3:
            continue
        low_pct = sum(1 for s in scores if s <= 5) / len(scores)
        if low_pct >= 0.6:
            label = DIMENSIONS[dim_key]
            recurring.append({
                "id": str(uuid.uuid4()),
                "dimension": dim_key,
                "label": label,
                "occurrences": len(scores),
                "low_percentage": round(low_pct * 100),
                "avg_score": round(sum(scores) / len(scores), 1),
                "message": f"{label} aparece com atencao em {round(low_pct*100)}% das suas avaliacoes."
            })
    recurring.sort(key=lambda x: x["avg_score"])
    return {"patterns": recurring}
