# -*- coding: utf-8 -*-
from typing import Any, Dict, Optional
from datetime import datetime, timezone
from fastapi import HTTPException, Header
from app.core.database import get_connection
from app.core.security import decode_token


async def get_current_user(authorization: Optional[str] = Header(default=None)) -> Dict[str, Any]:
    if not authorization:
        raise HTTPException(status_code=401, detail="Token ausente.")
    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(status_code=401, detail="Formato de token inválido.")
    user_id = decode_token(parts[1], expected_type="access")
    if not user_id:
        raise HTTPException(status_code=401, detail="Token inválido ou expirado.")
    conn = get_connection()
    user = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    conn.close()
    if not user:
        raise HTTPException(status_code=401, detail="Usuário não encontrado.")
    return dict(user)


def check_email_verified(user: Dict[str, Any]) -> None:
    """Bloqueia acesso se o e-mail não foi verificado."""
    if not user.get("email_verified"):
        raise HTTPException(
            status_code=403,
            detail="EMAIL_NOT_VERIFIED",
        )


def check_subscription(user: Dict[str, Any]) -> None:
    """Verifica e-mail + status de assinatura/trial.

    Códigos de erro distintos para o Flutter tratar cada caso:
    - 403 EMAIL_NOT_VERIFIED  → e-mail não verificado
    - 402 TRIAL_EXPIRED        → trial acabou, precisa assinar
    - 402 SUBSCRIPTION_INACTIVE → status diferente de active/trial
    """
    check_email_verified(user)

    status = user.get("subscription_status", "trial")
    if status == "active":
        return

    if status == "trial":
        trial_end_str = user.get("trial_end")
        if trial_end_str:
            try:
                trial_end = datetime.fromisoformat(trial_end_str)
                if trial_end.tzinfo is None:
                    trial_end = trial_end.replace(tzinfo=timezone.utc)
                if datetime.now(timezone.utc) <= trial_end:
                    return
            except (ValueError, TypeError):
                pass
        raise HTTPException(
            status_code=402,
            detail="TRIAL_EXPIRED",
        )

    raise HTTPException(
        status_code=402,
        detail="SUBSCRIPTION_INACTIVE",
    )
