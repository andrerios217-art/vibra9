import uuid, hashlib, secrets
from datetime import datetime, timedelta, timezone
from typing import Any, Dict
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, EmailStr, Field
from app.core.database import get_connection
from app.core.security import hash_password, verify_password, create_access_token, create_refresh_token, decode_token
from app.models.schemas import RegisterRequest, LoginRequest, AuthResponse, RefreshRequest
from app.core.config import TRIAL_DAYS, REFRESH_TOKEN_EXPIRE_DAYS, ENVIRONMENT
from app.core.dependencies import get_current_user

router = APIRouter(prefix="/auth", tags=["auth"])
MAX_FAILED = 5
LOCKOUT_MIN = 15

class VerifyEmailRequest(BaseModel):
    code: str = Field(min_length=6, max_length=6)

class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str = Field(min_length=8, max_length=128)

def _check_rate_limit(email: str) -> None:
    cutoff = (datetime.now(timezone.utc) - timedelta(minutes=LOCKOUT_MIN)).isoformat()
    conn = get_connection()
    count = conn.execute(
        "SELECT COUNT(*) FROM login_attempts WHERE email=? AND success=0 AND attempted_at>?",
        (email, cutoff)).fetchone()[0]
    conn.close()
    if count >= MAX_FAILED:
        raise HTTPException(status_code=429, detail=f"Muitas tentativas. Tente em {LOCKOUT_MIN} minutos.")

def _record_attempt(email: str, success: bool) -> None:
    conn = get_connection()
    conn.execute("INSERT INTO login_attempts (email,success,attempted_at) VALUES (?,?,?)",
                 (email, 1 if success else 0, datetime.now(timezone.utc).isoformat()))
    conn.commit()
    conn.close()

def _store_refresh(user_id: str, token: str) -> None:
    token_hash = hashlib.sha256(token.encode()).hexdigest()
    expires_at = (datetime.now(timezone.utc) + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)).isoformat()
    conn = get_connection()
    conn.execute("INSERT INTO refresh_tokens (id,user_id,token_hash,expires_at,created_at) VALUES (?,?,?,?,?)",
                 (str(uuid.uuid4()), user_id, token_hash, expires_at, datetime.now(timezone.utc).isoformat()))
    conn.commit()
    conn.close()

def _create_verification_code(user_id: str, code_type: str = "email") -> str:
    code = str(secrets.randbelow(900000) + 100000)
    expires_at = (datetime.now(timezone.utc) + timedelta(minutes=15)).isoformat()
    conn = get_connection()
    conn.execute("UPDATE verification_codes SET used=1 WHERE user_id=? AND type=? AND used=0",
                 (user_id, code_type))
    conn.execute("INSERT INTO verification_codes (id,user_id,code,type,expires_at,created_at) VALUES (?,?,?,?,?,?)",
                 (str(uuid.uuid4()), user_id, code, code_type, expires_at, datetime.now(timezone.utc).isoformat()))
    conn.commit()
    conn.close()
    return code

@router.post("/register")
def register(payload: RegisterRequest):
    if not payload.privacy_policy_accepted or not payload.terms_accepted:
        raise HTTPException(status_code=400, detail="Aceite a politica de privacidade e os termos de uso.")
    email = payload.email.strip().lower()
    conn = get_connection()
    if conn.execute("SELECT id FROM users WHERE email=?", (email,)).fetchone():
        conn.close()
        raise HTTPException(status_code=409, detail="E-mail ja cadastrado.")
    uid = str(uuid.uuid4())
    now = datetime.now(timezone.utc)
    now_s = now.isoformat()
    trial_end = (now + timedelta(days=TRIAL_DAYS)).isoformat()
    conn.execute("""INSERT INTO users
        (id,name,email,password_hash,privacy_policy_accepted,privacy_policy_accepted_at,
         terms_accepted,terms_accepted_at,email_verified,subscription_status,trial_start,trial_end,created_at)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)""",
        (uid, payload.name.strip(), email, hash_password(payload.password),
         1, now_s, 1, now_s, 0, "trial", now_s, trial_end, now_s))
    conn.commit()
    conn.close()
    at = create_access_token(uid)
    rt = create_refresh_token(uid)
    _store_refresh(uid, rt)
    code = _create_verification_code(uid, "email")
    result = {"access_token": at, "refresh_token": rt, "token_type": "bearer",
              "user_id": uid, "name": payload.name.strip(), "email": email,
              "email_verified": False}
    if ENVIRONMENT == "development":
        result["dev_code"] = code
        print(f"\n[DEV] Codigo de verificacao para {email}: {code}\n")
    return result

@router.post("/login", response_model=AuthResponse)
def login(payload: LoginRequest):
    email = payload.email.strip().lower()
    _check_rate_limit(email)
    conn = get_connection()
    row = conn.execute("SELECT * FROM users WHERE email=?", (email,)).fetchone()
    conn.close()
    if not row or not verify_password(payload.password, dict(row)["password_hash"]):
        _record_attempt(email, False)
        raise HTTPException(status_code=401, detail="E-mail ou senha invalidos.")
    _record_attempt(email, True)
    u = dict(row)
    at = create_access_token(u["id"])
    rt = create_refresh_token(u["id"])
    _store_refresh(u["id"], rt)
    return AuthResponse(access_token=at, refresh_token=rt, user_id=u["id"], name=u["name"], email=u["email"])

@router.post("/refresh", response_model=AuthResponse)
def refresh_token(payload: RefreshRequest):
    user_id = decode_token(payload.refresh_token, expected_type="refresh")
    if not user_id:
        raise HTTPException(status_code=401, detail="Refresh token invalido ou expirado.")
    th = hashlib.sha256(payload.refresh_token.encode()).hexdigest()
    conn = get_connection()
    stored = conn.execute(
        "SELECT * FROM refresh_tokens WHERE token_hash=? AND user_id=? AND revoked=0",
        (th, user_id)).fetchone()
    if not stored:
        conn.close()
        raise HTTPException(status_code=401, detail="Refresh token invalido ou revogado.")
    conn.execute("UPDATE refresh_tokens SET revoked=1 WHERE token_hash=?", (th,))
    user = conn.execute("SELECT * FROM users WHERE id=?", (user_id,)).fetchone()
    conn.commit()
    conn.close()
    if not user:
        raise HTTPException(status_code=401, detail="Usuario nao encontrado.")
    u = dict(user)
    at = create_access_token(user_id)
    rt = create_refresh_token(user_id)
    _store_refresh(user_id, rt)
    return AuthResponse(access_token=at, refresh_token=rt, user_id=u["id"], name=u["name"], email=u["email"])

@router.post("/logout")
def logout(payload: RefreshRequest):
    th = hashlib.sha256(payload.refresh_token.encode()).hexdigest()
    conn = get_connection()
    conn.execute("UPDATE refresh_tokens SET revoked=1 WHERE token_hash=?", (th,))
    conn.commit()
    conn.close()
    return {"message": "Logout realizado com sucesso."}

@router.post("/verify-email")
def verify_email(payload: VerifyEmailRequest, user: Dict[str, Any] = Depends(get_current_user)):
    if user.get("email_verified", 0):
        return {"verified": True, "message": "E-mail ja verificado."}
    conn = get_connection()
    row = conn.execute(
        "SELECT * FROM verification_codes WHERE user_id=? AND type='email' AND used=0 ORDER BY created_at DESC LIMIT 1",
        (user["id"],)).fetchone()
    if not row:
        conn.close()
        raise HTTPException(status_code=400, detail="Nenhum codigo ativo. Solicite um novo.")
    code_row = dict(row)
    expires_at = datetime.fromisoformat(code_row["expires_at"])
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    if datetime.now(timezone.utc) > expires_at:
        conn.close()
        raise HTTPException(status_code=400, detail="Codigo expirado. Solicite um novo.")
    if not secrets.compare_digest(code_row["code"], payload.code):
        conn.close()
        raise HTTPException(status_code=400, detail="Codigo incorreto.")
    conn.execute("UPDATE verification_codes SET used=1 WHERE id=?", (code_row["id"],))
    conn.execute("UPDATE users SET email_verified=1 WHERE id=?", (user["id"],))
    conn.commit()
    conn.close()
    return {"verified": True, "message": "E-mail verificado com sucesso."}

@router.post("/resend-verification")
def resend_verification(user: Dict[str, Any] = Depends(get_current_user)):
    if user.get("email_verified", 0):
        raise HTTPException(status_code=400, detail="E-mail ja verificado.")
    code = _create_verification_code(user["id"], "email")
    result = {"message": "Novo codigo enviado."}
    if ENVIRONMENT == "development":
        result["dev_code"] = code
        print(f"\n[DEV] Novo codigo para {user['email']}: {code}\n")
    return result

@router.post("/forgot-password")
def forgot_password(payload: ForgotPasswordRequest):
    email = payload.email.strip().lower()
    conn = get_connection()
    user = conn.execute("SELECT * FROM users WHERE email=?", (email,)).fetchone()
    conn.close()
    if not user:
        return {"message": "Se o e-mail existir, voce recebera instrucoes de redefinicao."}
    u = dict(user)
    raw_token = secrets.token_hex(32)
    token_hash = hashlib.sha256(raw_token.encode()).hexdigest()
    expires_at = (datetime.now(timezone.utc) + timedelta(hours=1)).isoformat()
    conn = get_connection()
    conn.execute("UPDATE password_reset_tokens SET used=1 WHERE user_id=? AND used=0", (u["id"],))
    conn.execute("INSERT INTO password_reset_tokens (id,user_id,token_hash,expires_at,created_at) VALUES (?,?,?,?,?)",
                 (str(uuid.uuid4()), u["id"], token_hash, expires_at, datetime.now(timezone.utc).isoformat()))
    conn.commit()
    conn.close()
    result = {"message": "Se o e-mail existir, voce recebera instrucoes de redefinicao."}
    if ENVIRONMENT == "development":
        result["dev_token"] = raw_token
        print(f"\n[DEV] Reset token para {email}: {raw_token}\n")
    return result

@router.post("/reset-password")
def reset_password(payload: ResetPasswordRequest):
    token_hash = hashlib.sha256(payload.token.encode()).hexdigest()
    conn = get_connection()
    row = conn.execute(
        "SELECT * FROM password_reset_tokens WHERE token_hash=? AND used=0",
        (token_hash,)).fetchone()
    if not row:
        conn.close()
        raise HTTPException(status_code=400, detail="Token invalido ou ja utilizado.")
    r = dict(row)
    expires_at = datetime.fromisoformat(r["expires_at"])
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    if datetime.now(timezone.utc) > expires_at:
        conn.close()
        raise HTTPException(status_code=400, detail="Token expirado. Solicite um novo.")
    conn.execute("UPDATE users SET password_hash=? WHERE id=?",
                 (hash_password(payload.new_password), r["user_id"]))
    conn.execute("UPDATE password_reset_tokens SET used=1 WHERE token_hash=?", (token_hash,))
    conn.execute("UPDATE refresh_tokens SET revoked=1 WHERE user_id=?", (r["user_id"],))
    conn.commit()
    conn.close()
    return {"message": "Senha redefinida com sucesso. Faca login novamente."}
