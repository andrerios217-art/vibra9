# -*- coding: utf-8 -*-
import json, uuid
from datetime import datetime, timedelta, timezone
from typing import Any, Dict
from fastapi import APIRouter, Depends, HTTPException
from app.core.dependencies import get_current_user, check_subscription
from app.core.database import get_connection
from app.models.schemas import AssessmentRequest, AssessmentResponse
from app.services.assessment_service import calculate_assessment
from app.data.dimensions import DIMENSIONS

router = APIRouter(prefix="/assessment", tags=["assessment"])

ASSESSMENT_COOLDOWN_MINUTES = 30

QUESTIONS = [
    {"question_id": "mental_1", "dimension": "clareza_mental",
     "text": "Hoje, consigo organizar meus pensamentos com clareza?",
     "scale_min": 0, "scale_max": 10},
    {"question_id": "emocional_1", "dimension": "estado_emocional",
     "text": "Hoje, consigo reconhecer meu estado emocional sem me julgar?",
     "scale_min": 0, "scale_max": 10},
    {"question_id": "proposito_1", "dimension": "proposito_pessoal",
     "text": "Hoje, sinto que minhas ações têm algum sentido para mim?",
     "scale_min": 0, "scale_max": 10},
    {"question_id": "energia_1", "dimension": "energia_diaria",
     "text": "Hoje, tenho energia suficiente para lidar com minha rotina?",
     "scale_min": 0, "scale_max": 10},
    {"question_id": "corpo_1", "dimension": "corpo_habitos",
     "text": "Hoje, cuidei minimamente do meu corpo — sono, água ou movimento?",
     "scale_min": 0, "scale_max": 10},
    {"question_id": "comunicacao_1", "dimension": "comunicacao",
     "text": "Hoje, consigo me expressar com tranquilidade e respeito?",
     "scale_min": 0, "scale_max": 10},
    {"question_id": "relacoes_1", "dimension": "relacoes",
     "text": "Hoje, minhas relações contribuem para o meu equilíbrio?",
     "scale_min": 0, "scale_max": 10},
    {"question_id": "rotina_1", "dimension": "rotina_foco",
     "text": "Hoje, consigo manter foco em pelo menos uma prioridade?",
     "scale_min": 0, "scale_max": 10},
    {"question_id": "financeiro_1", "dimension": "seguranca_financeira",
     "text": "Hoje, sinto que minha vida prática e financeira está minimamente organizada?",
     "scale_min": 0, "scale_max": 10},
]


@router.get("/questions")
def get_questions(user: Dict[str, Any] = Depends(get_current_user)):
    check_subscription(user)
    return {"questions": QUESTIONS}


@router.post("", response_model=AssessmentResponse)
def create_assessment(payload: AssessmentRequest, user: Dict[str, Any] = Depends(get_current_user)):
    check_subscription(user)

    # Rate limit: 1 avaliação a cada 30 minutos por usuário
    cutoff = (datetime.now(timezone.utc) - timedelta(minutes=ASSESSMENT_COOLDOWN_MINUTES)).isoformat()
    conn = get_connection()
    recent = conn.execute(
        "SELECT created_at FROM assessments WHERE user_id=? AND created_at > ? ORDER BY created_at DESC LIMIT 1",
        (user["id"], cutoff)).fetchone()
    if recent:
        conn.close()
        raise HTTPException(
            status_code=429,
            detail=f"Você já fez uma avaliação recentemente. Aguarde {ASSESSMENT_COOLDOWN_MINUTES} minutos entre avaliações."
        )

    if len(payload.answers) != 9:
        conn.close()
        raise HTTPException(status_code=400, detail="Envie exatamente uma resposta para cada uma das 9 dimensões.")

    # Valida que cada dimensão é válida e não há duplicatas
    submitted_dimensions = set()
    for answer in payload.answers:
        if answer.dimension not in DIMENSIONS:
            conn.close()
            raise HTTPException(status_code=400, detail=f"Dimensão inválida: {answer.dimension}")
        if answer.dimension in submitted_dimensions:
            conn.close()
            raise HTTPException(status_code=400, detail=f"Dimensão duplicada: {answer.dimension}")
        submitted_dimensions.add(answer.dimension)

    if submitted_dimensions != set(DIMENSIONS.keys()):
        missing = set(DIMENSIONS.keys()) - submitted_dimensions
        conn.close()
        raise HTTPException(status_code=400, detail=f"Dimensões faltando: {', '.join(missing)}")

    dims = calculate_assessment(payload.answers)
    general_score = round(sum(d.score for d in dims) / len(dims) * 10)
    aid = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()
    conn.execute(
        "INSERT INTO assessments (id,user_id,general_score,dimensions_json,created_at) VALUES (?,?,?,?,?)",
        (aid, user["id"], general_score, json.dumps([d.model_dump() for d in dims], ensure_ascii=False), now))
    conn.commit()
    conn.close()
    return AssessmentResponse(assessment_id=aid, general_score=general_score, dimensions=dims, created_at=now)
