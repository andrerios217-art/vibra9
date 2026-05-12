# -*- coding: utf-8 -*-
import json
from datetime import datetime, timezone
from typing import Any, Dict, Optional
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from app.core.dependencies import get_current_user
from app.core.database import get_connection
from app.core.security import verify_password
from app.models.schemas import MeResponse, DeleteAccountResponse

router = APIRouter(prefix="/me", tags=["users"])


class DeleteAccountRequest(BaseModel):
    password: str = Field(min_length=1)


@router.get("", response_model=MeResponse)
def get_me(user: Dict[str, Any] = Depends(get_current_user)):
    return MeResponse(
        id=user["id"],
        name=user["name"],
        email=user["email"],
        subscription_status=user.get("subscription_status", "trial"),
        trial_end=user.get("trial_end"),
        created_at=user["created_at"],
    )


@router.delete("", response_model=DeleteAccountResponse)
def delete_me(payload: DeleteAccountRequest, user: Dict[str, Any] = Depends(get_current_user)):
    """Exclusão de conta com confirmação por senha. Remove todos os dados do usuário."""
    if not verify_password(payload.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Senha incorreta.")

    conn = get_connection()
    user_id = user["id"]
    email = user["email"]

    # Ordem importa por causa de foreign keys
    conn.execute("DELETE FROM recommendations WHERE user_id=?", (user_id,))
    conn.execute("DELETE FROM assessments WHERE user_id=?", (user_id,))
    conn.execute("DELETE FROM refresh_tokens WHERE user_id=?", (user_id,))
    conn.execute("DELETE FROM verification_codes WHERE user_id=?", (user_id,))
    conn.execute("DELETE FROM password_reset_tokens WHERE user_id=?", (user_id,))
    conn.execute("DELETE FROM consent_log WHERE user_id=?", (user_id,))
    conn.execute("DELETE FROM login_attempts WHERE email=?", (email,))
    conn.execute("DELETE FROM users WHERE id=?", (user_id,))
    conn.commit()
    conn.close()
    return DeleteAccountResponse(deleted=True, message="Conta excluída. Todos os seus dados foram removidos.")


@router.get("/export")
def export_data(user: Dict[str, Any] = Depends(get_current_user)):
    """Exporta TODOS os dados do usuário conforme exigência da LGPD."""
    conn = get_connection()
    user_id = user["id"]

    assessments = []
    for row in conn.execute("SELECT * FROM assessments WHERE user_id=? ORDER BY created_at DESC", (user_id,)).fetchall():
        item = dict(row)
        item["dimensions"] = json.loads(item.pop("dimensions_json", "[]"))
        assessments.append(item)

    recommendations = []
    for row in conn.execute("SELECT * FROM recommendations WHERE user_id=? ORDER BY created_at DESC", (user_id,)).fetchall():
        item = dict(row)
        item["daily_actions"] = json.loads(item.pop("daily_actions_json", "[]"))
        recommendations.append(item)

    consent_history = [dict(row) for row in conn.execute(
        "SELECT id, privacy_policy_version, terms_version, accepted_at FROM consent_log WHERE user_id=? ORDER BY accepted_at DESC",
        (user_id,)).fetchall()]

    conn.close()

    safe_user = {k: v for k, v in user.items() if k != "password_hash"}

    return {
        "user": safe_user,
        "consent_history": consent_history,
        "assessments": assessments,
        "recommendations": recommendations,
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "lgpd_notice": "Este arquivo contém todos os seus dados pessoais armazenados pelo Vibra9, conforme a Lei Geral de Proteção de Dados (LGPD).",
    }
