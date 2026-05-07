from datetime import datetime, timezone
from typing import Dict, Any
from app.models.schemas import DimensionScore
from app.data.dimensions import RECOMMENDATION_LIBRARY
from app.data.quotes import PT_BR_QUOTES

def category_from_score(score: int) -> str:
    if score <= 4: return "low"
    if score <= 7: return "medium"
    return "high"

def build_summary(general_score: int, weakest: DimensionScore, strongest: DimensionScore) -> str:
    if general_score <= 40:
        return (f"Seu resultado indica um momento que pede mais cuidado e simplificacao. "
                f"O campo que mais merece atencao agora e {weakest.label}. "
                f"A ideia nao e buscar perfeicao, mas reduzir sobrecarga e criar pequenas acoes possiveis.")
    if general_score <= 70:
        return (f"Seu resultado mostra um estado em desenvolvimento. "
                f"Voce ja tem recursos importantes, especialmente em {strongest.label}, "
                f"mas pode ganhar mais equilibrio ao cuidar de {weakest.label} com acoes simples.")
    return (f"Seu resultado indica um bom nivel geral de equilibrio. "
            f"Seu ponto mais forte hoje e {strongest.label}. "
            f"Para manter consistencia, observe {weakest.label} sem cobranca excessiva.")

def generate_recommendations(assessment: Dict[str, Any]) -> Dict[str, Any]:
    dims = [DimensionScore(**d) for d in assessment["dimensions"]]
    weakest = min(dims, key=lambda d: d.score)
    strongest = max(dims, key=lambda d: d.score)
    actions = RECOMMENDATION_LIBRARY[weakest.dimension][category_from_score(weakest.score)]
    return {"summary": build_summary(assessment["general_score"], weakest, strongest),
            "main_focus": weakest.label, "daily_actions": actions}

def get_daily_quote() -> Dict[str, str]:
    idx = datetime.now(timezone.utc).timetuple().tm_yday % len(PT_BR_QUOTES)
    return PT_BR_QUOTES[idx]
