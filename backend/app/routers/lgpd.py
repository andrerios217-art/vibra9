# -*- coding: utf-8 -*-
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
DOCUMENTS_UPDATED_AT = "2026-05-07"


class ConsentRequest(BaseModel):
    privacy_policy_version: str
    terms_version: str
    privacy_policy_accepted: bool
    terms_accepted: bool


def _record_consent_internal(user_id: str, privacy_version: str, terms_version: str) -> str:
    """Helper interno usado também pelo registro inicial."""
    now = datetime.now(timezone.utc).isoformat()
    conn = get_connection()
    conn.execute("""INSERT INTO consent_log
        (id, user_id, privacy_policy_version, terms_version, accepted_at)
        VALUES (?,?,?,?,?)""",
        (str(uuid.uuid4()), user_id, privacy_version, terms_version, now))
    conn.execute("""UPDATE users SET
        privacy_policy_accepted=1,
        privacy_policy_accepted_at=?,
        privacy_policy_version=?,
        terms_accepted=1,
        terms_accepted_at=?,
        terms_version=?
        WHERE id=?""",
        (now, privacy_version, now, terms_version, user_id))
    conn.commit()
    conn.close()
    return now


@router.get("/privacy-policy")
def get_privacy_policy():
    return {
        "version": PRIVACY_POLICY_VERSION,
        "updated_at": DOCUMENTS_UPDATED_AT,
        "title": "Política de Privacidade — Vibra9",
        "sections": [
            {"title": "1. Quem somos", "content": "O Vibra9 é um aplicativo de bem-estar emocional e autoconhecimento. Desenvolvido por André Rios, o app ajuda você a entender seu estado emocional, identificar padrões e acompanhar sua evolução ao longo do tempo."},
            {"title": "2. Quais dados coletamos", "content": "Coletamos: nome e e-mail para criação de conta; respostas das avaliações emocionais (scores de 0 a 10 por dimensão); histórico de avaliações e recomendações geradas; data e hora de acesso; dados de consentimento (versão e data de aceite dos termos)."},
            {"title": "3. Como usamos seus dados", "content": "Seus dados são usados exclusivamente para: gerar avaliações e recomendações personalizadas; permitir que você acompanhe sua evolução; melhorar os algoritmos do app. Não vendemos, compartilhamos nem usamos seus dados para publicidade."},
            {"title": "4. Base legal (LGPD)", "content": "O tratamento dos seus dados é fundamentado no seu consentimento explícito (Art. 7º, I da LGPD). Você pode revogar esse consentimento a qualquer momento excluindo sua conta."},
            {"title": "5. Seus direitos", "content": "Você tem direito a: acessar seus dados (exportação disponível no app); corrigir dados incorretos; excluir sua conta e todos os dados associados; revogar o consentimento a qualquer momento; obter informações sobre o uso dos seus dados."},
            {"title": "6. Segurança", "content": "Seus dados são protegidos com: autenticação JWT com tokens de curta duração; senhas armazenadas com hash PBKDF2 + salt; comunicação criptografada em produção (HTTPS); sem armazenamento de dados sensíveis desnecessários."},
            {"title": "7. Retenção de dados", "content": "Seus dados são mantidos enquanto sua conta estiver ativa. Ao excluir a conta, todos os dados são removidos permanentemente do banco de dados em até 30 dias."},
            {"title": "8. Aviso importante", "content": "O Vibra9 oferece orientações gerais de bem-estar e autoconhecimento. Não substitui acompanhamento médico, psicológico ou terapêutico profissional."},
            {"title": "9. Contato", "content": "Dúvidas sobre privacidade? Entre em contato: contato@vibra9.app"},
        ],
    }


@router.get("/terms")
def get_terms():
    return {
        "version": TERMS_VERSION,
        "updated_at": DOCUMENTS_UPDATED_AT,
        "title": "Termos de Uso — Vibra9",
        "sections": [
            {"title": "1. Aceitação", "content": "Ao criar uma conta no Vibra9, você concorda com estes Termos de Uso. Se não concordar, não utilize o app."},
            {"title": "2. O que é o Vibra9", "content": "O Vibra9 é uma ferramenta de autoconhecimento e bem-estar emocional. As avaliações e recomendações são orientações gerais baseadas nas suas respostas e não constituem diagnóstico ou tratamento médico ou psicológico."},
            {"title": "3. Uso adequado", "content": "Você se compromete a: fornecer informações verdadeiras no cadastro; não compartilhar sua conta com terceiros; não usar o app para fins ilegais; não tentar acessar dados de outros usuários."},
            {"title": "4. Trial e assinatura", "content": "O Vibra9 oferece trial gratuito de 7 dias com acesso completo. Após o período de trial, é necessária assinatura mensal para continuar utilizando as funcionalidades de avaliação e histórico."},
            {"title": "5. Cancelamento", "content": "Você pode cancelar sua assinatura a qualquer momento. Ao excluir sua conta, todos os dados são removidos e o acesso é encerrado imediatamente."},
            {"title": "6. Limitação de responsabilidade", "content": "O Vibra9 não se responsabiliza por decisões tomadas com base nas orientações do app. Em situações de crise emocional ou saúde mental, procure ajuda profissional especializada."},
            {"title": "7. Alterações", "content": "Podemos atualizar estes termos. Você será notificado sobre mudanças significativas e precisará aceitar os novos termos para continuar usando o app."},
            {"title": "8. Contato", "content": "Dúvidas sobre os termos? Entre em contato: contato@vibra9.app"},
        ],
    }


@router.post("/consent")
def record_consent(payload: ConsentRequest, user: Dict[str, Any] = Depends(get_current_user)):
    if not payload.privacy_policy_accepted or not payload.terms_accepted:
        raise HTTPException(status_code=400, detail="Ambos os consentimentos são obrigatórios.")
    accepted_at = _record_consent_internal(
        user["id"], payload.privacy_policy_version, payload.terms_version)
    return {
        "recorded": True,
        "accepted_at": accepted_at,
        "privacy_policy_version": payload.privacy_policy_version,
        "terms_version": payload.terms_version,
    }


@router.get("/consent/status")
def get_consent_status(user: Dict[str, Any] = Depends(get_current_user)):
    user_privacy_version = user.get("privacy_policy_version")
    user_terms_version = user.get("terms_version")
    needs_update = (
        user_privacy_version != PRIVACY_POLICY_VERSION
        or user_terms_version != TERMS_VERSION
    )
    return {
        "privacy_policy_accepted": bool(user.get("privacy_policy_accepted")),
        "privacy_policy_accepted_at": user.get("privacy_policy_accepted_at"),
        "privacy_policy_version": user_privacy_version,
        "terms_accepted": bool(user.get("terms_accepted")),
        "terms_accepted_at": user.get("terms_accepted_at"),
        "terms_version": user_terms_version,
        "current_privacy_policy_version": PRIVACY_POLICY_VERSION,
        "current_terms_version": TERMS_VERSION,
        "needs_reacceptance": needs_update,
    }
