import json, uuid
from datetime import datetime, timezone
from typing import Any, Dict
from fastapi import APIRouter, Depends, HTTPException
from app.core.dependencies import get_current_user, check_subscription
from app.core.database import get_connection
from app.models.schemas import RecommendationRequest, RecommendationResponse
from app.services.recommendation_service import generate_recommendations, get_daily_quote

router = APIRouter(prefix="/recommendations", tags=["recommendations"])
SAFETY = ("O Vibra9 oferece orientacoes gerais de bem-estar e autoconhecimento. "
          "Nao substitui acompanhamento medico, psicologico ou profissional.")

@router.post("", response_model=RecommendationResponse)
def create_recommendation(payload: RecommendationRequest, user: Dict[str, Any] = Depends(get_current_user)):
    check_subscription(user)
    conn = get_connection()
    row = conn.execute("SELECT * FROM assessments WHERE id=? AND user_id=?",
                       (payload.assessment_id, user["id"])).fetchone()
    conn.close()
    if not row:
        raise HTTPException(status_code=404, detail="Avaliacao nao encontrada.")
    assessment = dict(row)
    assessment["dimensions"] = json.loads(assessment["dimensions_json"])
    gen = generate_recommendations(assessment)
    quote = get_daily_quote()
    rid = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()
    conn = get_connection()
    conn.execute("""INSERT INTO recommendations
        (id,user_id,assessment_id,summary,main_focus,daily_actions_json,quote,quote_author,safety_note,created_at)
        VALUES (?,?,?,?,?,?,?,?,?,?)""",
        (rid, user["id"], payload.assessment_id, gen["summary"], gen["main_focus"],
         json.dumps(gen["daily_actions"], ensure_ascii=False), quote["quote"], quote["author"], SAFETY, now))
    conn.commit()
    conn.close()
    return RecommendationResponse(recommendation_id=rid, assessment_id=payload.assessment_id,
        summary=gen["summary"], main_focus=gen["main_focus"], daily_actions=gen["daily_actions"],
        quote=quote["quote"], quote_author=quote["author"], safety_note=SAFETY, created_at=now)
