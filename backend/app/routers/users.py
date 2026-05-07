import json
from datetime import datetime, timezone
from typing import Any, Dict
from fastapi import APIRouter, Depends
from app.core.dependencies import get_current_user
from app.core.database import get_connection
from app.models.schemas import MeResponse, DeleteAccountResponse

router = APIRouter(prefix="/me", tags=["users"])

@router.get("", response_model=MeResponse)
def get_me(user: Dict[str, Any] = Depends(get_current_user)):
    return MeResponse(
        id=user["id"], name=user["name"], email=user["email"],
        subscription_status=user.get("subscription_status", "trial"),
        trial_end=user.get("trial_end"), created_at=user["created_at"])

@router.delete("", response_model=DeleteAccountResponse)
def delete_me(user: Dict[str, Any] = Depends(get_current_user)):
    conn = get_connection()
    for tbl, col in [("recommendations","user_id"),("assessments","user_id"),
                     ("refresh_tokens","user_id"),("login_attempts","email"),("users","id")]:
        val = user["email"] if col == "email" else user["id"]
        conn.execute(f"DELETE FROM {tbl} WHERE {col}=?", (val,))
    conn.commit()
    conn.close()
    return DeleteAccountResponse(deleted=True, message="Conta excluida. Seus dados foram removidos.")

@router.get("/export")
def export_data(user: Dict[str, Any] = Depends(get_current_user)):
    conn = get_connection()
    assessments = []
    for row in conn.execute("SELECT * FROM assessments WHERE user_id=?", (user["id"],)).fetchall():
        item = dict(row)
        item["dimensions"] = json.loads(item.pop("dimensions_json", "[]"))
        assessments.append(item)
    recommendations = []
    for row in conn.execute("SELECT * FROM recommendations WHERE user_id=?", (user["id"],)).fetchall():
        item = dict(row)
        item["daily_actions"] = json.loads(item.pop("daily_actions_json", "[]"))
        recommendations.append(item)
    conn.close()
    safe_user = {k: v for k, v in user.items() if k != "password_hash"}
    return {"user": safe_user, "assessments": assessments, "recommendations": recommendations,
            "exported_at": datetime.now(timezone.utc).isoformat()}
