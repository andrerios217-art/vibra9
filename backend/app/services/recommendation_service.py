# -*- coding: utf-8 -*-
import random
from datetime import datetime, timezone
from typing import Dict, Any
from app.models.schemas import DimensionScore
from app.data.dimensions import RECOMMENDATION_LIBRARY, DIMENSIONS
from app.data.quotes import PT_BR_QUOTES


GENERIC_ACTIONS = [
    "Faça uma pausa de 5 minutos sem tela.",
    "Beba um copo de água agora.",
    "Anote uma coisa pela qual você é grato hoje.",
]


def category_from_score(score: int) -> str:
    if score <= 4:
        return "low"
    if score <= 7:
        return "medium"
    return "high"


def build_summary(general_score: int, weakest: DimensionScore, strongest: DimensionScore) -> str:
    if general_score <= 40:
        return (
            f"Seu resultado indica um momento que pede mais cuidado e simplificação. "
            f"O campo que mais merece atenção agora é {weakest.label}. "
            f"A ideia não é buscar perfeição, mas reduzir sobrecarga e criar pequenas ações possíveis."
        )
    if general_score <= 70:
        return (
            f"Seu resultado mostra um estado em desenvolvimento. "
            f"Você já tem recursos importantes, especialmente em {strongest.label}, "
            f"mas pode ganhar mais equilíbrio ao cuidar de {weakest.label} com ações simples."
        )
    return (
        f"Seu resultado indica um bom nível geral de equilíbrio. "
        f"Seu ponto mais forte hoje é {strongest.label}. "
        f"Para manter consistência, observe {weakest.label} sem cobrança excessiva."
    )


def generate_recommendations(assessment: Dict[str, Any]) -> Dict[str, Any]:
    dims = [DimensionScore(**d) for d in assessment["dimensions"]]

    # Em caso de empate, min/max retornam o primeiro — ok funcional
    weakest = min(dims, key=lambda d: d.score)
    strongest = max(dims, key=lambda d: d.score)

    # Fallback defensivo caso a dimensão não esteja na biblioteca
    library_for_dim = RECOMMENDATION_LIBRARY.get(weakest.dimension)
    if library_for_dim:
        category = category_from_score(weakest.score)
        actions = library_for_dim.get(category, GENERIC_ACTIONS)
    else:
        actions = GENERIC_ACTIONS

    return {
        "summary": build_summary(assessment["general_score"], weakest, strongest),
        "main_focus": weakest.label,
        "daily_actions": actions,
    }


def get_daily_quote() -> Dict[str, str]:
    """Retorna uma frase do dia, baseada no dia do ano (mesmo para todos no mesmo dia)."""
    if not PT_BR_QUOTES:
        return {"quote": "Cuide de você hoje.", "author": "Vibra9"}
    idx = datetime.now(timezone.utc).timetuple().tm_yday % len(PT_BR_QUOTES)
    return PT_BR_QUOTES[idx]
