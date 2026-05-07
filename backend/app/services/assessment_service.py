from typing import List, Dict
from fastapi import HTTPException
from app.models.schemas import AssessmentAnswer, DimensionScore
from app.data.dimensions import DIMENSIONS

def status_from_score(score: int) -> str:
    if score <= 4: return "atencao"
    if score <= 7: return "em_desenvolvimento"
    return "equilibrado"

def calculate_assessment(answers: List[AssessmentAnswer]) -> List[DimensionScore]:
    grouped: Dict[str, List[int]] = {}
    for a in answers:
        if a.dimension not in DIMENSIONS:
            raise HTTPException(status_code=400, detail=f"Dimensao invalida: {a.dimension}")
        grouped.setdefault(a.dimension, []).append(a.score)
    result = []
    for key, label in DIMENSIONS.items():
        vals = grouped.get(key, [])
        score = round(sum(vals) / len(vals)) if vals else 0
        result.append(DimensionScore(dimension=key, label=label, score=score, status=status_from_score(score)))
    return result
