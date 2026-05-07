import uuid
from datetime import datetime, timezone
from typing import Any, Dict
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from app.core.dependencies import get_current_user
from app.core.database import get_connection

router = APIRouter(prefix="/lgpd", tags=["lgpd"])

PRIVACY_POLICY_VERSION = "1.0"
TERMS_VERSION = "1.0"

class ConsentRequest(BaseModel):
    privacy_policy_version: str
    terms_version: str
    privacy_policy_accepted: bool
    terms_accepted: bool

@router.get("/privacy-policy")
def get_privacy_policy():
    return {
        "version": PRIVACY_POLICY_VERSION,
        "updated_at": "2026-05-07",
        "title": "Politica de Privacidade — Vibra9",
        "sections": [
            {
                "title": "1. Quem somos",
                "content": "O Vibra9 e um aplicativo de bem-estar emocional e autoconhecimento. Desenvolvido por Andre Rios, o app ajuda voce a entender seu estado emocional, identificar padroes e acompanhar sua evolucao ao longo do tempo."
            },
            {
                "title": "2. Quais dados coletamos",
                "content": "Coletamos: nome e e-mail para criacao de conta; respostas das avaliacoes emocionais (scores de 0 a 10 por dimensao); historico de avaliacoes e recomendacoes geradas; data e hora de acesso; dados de consentimento (versao e data de aceite dos termos)."
            },
            {
                "title": "3. Como usamos seus dados",
                "content": "Seus dados sao usados exclusivamente para: gerar avaliacoes e recomendacoes personalizadas; permitir que voce acompanhe sua evolucao; melhorar os algoritmos do app. Nao vendemos, compartilhamos nem usamos seus dados para publicidade."
            },
            {
                "title": "4. Base legal (LGPD)",
                "content": "O tratamento dos seus dados e fundamentado no seu consentimento explicito (Art. 7, I da LGPD). Voce pode revogar esse consentimento a qualquer momento excluindo sua conta."
            },
            {
                "title": "5. Seus direitos",
                "content": "Voce tem direito a: acessar seus dados (exportacao disponivel no app); corrigir dados incorretos; excluir sua conta e todos os dados associados; revogar o consentimento a qualquer momento; obter informacoes sobre o uso dos seus dados."
            },
            {
                "title": "6. Seguranca",
                "content": "Seus dados sao protegidos com: autenticacao JWT com tokens de curta duracao; senhas armazenadas com hash PBKDF2 + salt; comunicacao criptografada em producao (HTTPS); sem armazenamento de dados sensiveis desnecessarios."
            },
            {
                "title": "7. Retencao de dados",
                "content": "Seus dados sao mantidos enquanto sua conta estiver ativa. Ao excluir a conta, todos os dados sao removidos permanentemente do banco de dados em ate 30 dias."
            },
            {
                "title": "8. Aviso importante",
                "content": "O Vibra9 oferece orientacoes gerais de bem-estar e autoconhecimento. Nao substitui acompanhamento medico, psicologico ou terapeutico profissional."
            },
            {
                "title": "9. Contato",
                "content": "Duvidas sobre privacidade? Entre em contato: contato@vibra9.app"
            }
        ]
    }

@router.get("/terms")
def get_terms():
    return {
        "version": TERMS_VERSION,
        "updated_at": "2026-05-07",
        "title": "Termos de Uso — Vibra9",
        "sections": [
            {
                "title": "1. Aceitacao",
                "content": "Ao criar uma conta no Vibra9, voce concorda com estes Termos de Uso. Se nao concordar, nao utilize o app."
            },
            {
                "title": "2. O que e o Vibra9",
                "content": "O Vibra9 e uma ferramenta de autoconhecimento e bem-estar emocional. As avaliacoes e recomendacoes sao orientacoes gerais baseadas nas suas respostas e nao constituem diagnostico ou tratamento medico ou psicologico."
            },
            {
                "title": "3. Uso adequado",
                "content": "Voce se compromete a: fornecer informacoes verdadeiras no cadastro; nao compartilhar sua conta com terceiros; nao usar o app para fins ilegais; nao tentar acessar dados de outros usuarios."
            },
            {
                "title": "4. Trial e assinatura",
                "content": "O Vibra9 oferece trial gratuito de 15 dias com acesso completo. Apos o periodo de trial, e necessaria assinatura mensal para continuar utilizando as funcionalidades de avaliacao e historico."
            },
            {
                "title": "5. Cancelamento",
                "content": "Voce pode cancelar sua assinatura a qualquer momento. Ao excluir sua conta, todos os dados sao removidos e o acesso e encerrado imediatamente."
            },
            {
                "title": "6. Limitacao de responsabilidade",
                "content": "O Vibra9 nao se responsabiliza por decisoes tomadas com base nas orientacoes do app. Em situacoes de crise emocional ou saude mental, procure ajuda profissional especializada."
            },
            {
                "title": "7. Alteracoes",
                "content": "Podemos atualizar estes termos. Voce sera notificado sobre mudancas significativas e precisara aceitar os novos termos para continuar usando o app."
            },
            {
                "title": "8. Contato",
                "content": "Duvidas sobre os termos? Entre em contato: contato@vibra9.app"
            }
        ]
    }

@router.post("/consent")
def record_consent(payload: ConsentRequest, user: Dict[str, Any] = Depends(get_current_user)):
    if not payload.privacy_policy_accepted or not payload.terms_accepted:
        raise HTTPException(status_code=400, detail="Ambos os consentimentos sao obrigatorios.")
    now = datetime.now(timezone.utc).isoformat()
    conn = get_connection()
    existing = {row[1] for row in conn.execute("PRAGMA table_info(users)")}
    if "consent_log" not in existing:
        conn.execute("""CREATE TABLE IF NOT EXISTS consent_log (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            privacy_policy_version TEXT NOT NULL,
            terms_version TEXT NOT NULL,
            accepted_at TEXT NOT NULL,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        )""")
    conn.execute("""INSERT INTO consent_log
        (id, user_id, privacy_policy_version, terms_version, accepted_at)
        VALUES (?,?,?,?,?)""",
        (str(uuid.uuid4()), user["id"],
         payload.privacy_policy_version, payload.terms_version, now))
    conn.execute("""UPDATE users SET
        privacy_policy_accepted=1,
        privacy_policy_accepted_at=?,
        terms_accepted=1,
        terms_accepted_at=?
        WHERE id=?""", (now, now, user["id"]))
    conn.commit()
    conn.close()
    return {"recorded": True, "accepted_at": now,
            "privacy_policy_version": payload.privacy_policy_version,
            "terms_version": payload.terms_version}

@router.get("/consent/status")
def get_consent_status(user: Dict[str, Any] = Depends(get_current_user)):
    return {
        "privacy_policy_accepted": bool(user.get("privacy_policy_accepted")),
        "privacy_policy_accepted_at": user.get("privacy_policy_accepted_at"),
        "terms_accepted": bool(user.get("terms_accepted")),
        "terms_accepted_at": user.get("terms_accepted_at"),
        "current_privacy_policy_version": PRIVACY_POLICY_VERSION,
        "current_terms_version": TERMS_VERSION,
    }
