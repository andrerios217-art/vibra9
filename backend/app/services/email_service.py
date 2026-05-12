import os
import resend
from app.core.config import APP_NAME

RESEND_API_KEY = os.getenv("RESEND_API_KEY", "")
EMAIL_FROM = os.getenv("EMAIL_FROM", "onboarding@resend.dev")
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")

if RESEND_API_KEY:
    resend.api_key = RESEND_API_KEY


def is_email_configured() -> bool:
    """Retorna True se o serviço de e-mail está pronto para envio."""
    return bool(RESEND_API_KEY)


def send_verification_email(to_email: str, code: str, name: str = "") -> bool:
    """
    Envia o código de verificação por e-mail.
    Retorna True se foi enviado com sucesso, False caso contrário.
    """
    if not is_email_configured():
        print(f"[email] RESEND_API_KEY ausente — código para {to_email}: {code}")
        return False

    greeting = f"Olá, {name}!" if name else "Olá!"

    html = f"""
    <div style="font-family: -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px; color: #1F2544;">
      <div style="text-align: center; margin-bottom: 32px;">
        <h1 style="color: #6B4FD8; font-size: 28px; margin: 0; font-weight: 700;">Vibra9</h1>
      </div>

      <h2 style="font-size: 20px; color: #1F2544; margin-bottom: 16px;">{greeting}</h2>

      <p style="font-size: 15px; line-height: 1.6; color: #4A4A6A;">
        Para verificar seu e-mail no {APP_NAME}, use o código abaixo:
      </p>

      <div style="background: linear-gradient(135deg, #6B4FD8 0%, #42B8B0 100%); border-radius: 16px; padding: 24px; margin: 24px 0; text-align: center;">
        <div style="color: white; font-size: 36px; font-weight: 700; letter-spacing: 8px; font-family: 'Courier New', monospace;">
          {code}
        </div>
      </div>

      <p style="font-size: 14px; line-height: 1.6; color: #6B6F8A;">
        Este código expira em 10 minutos. Se você não solicitou esta verificação, pode ignorar este e-mail.
      </p>

      <hr style="border: none; border-top: 1px solid #E5E5EC; margin: 32px 0;">

      <p style="font-size: 12px; line-height: 1.5; color: #6B6F8A; text-align: center;">
        Vibra9 — Bem-estar e autoconhecimento em 9 dimensões.<br>
        Este é um e-mail automático, não responda.
      </p>
    </div>
    """

    text = f"""{greeting}

Para verificar seu e-mail no {APP_NAME}, use o código abaixo:

{code}

Este código expira em 10 minutos. Se você não solicitou esta verificação, pode ignorar este e-mail.

—
Vibra9 — Bem-estar e autoconhecimento em 9 dimensões.
"""

    try:
        params = {
            "from": f"Vibra9 <{EMAIL_FROM}>",
            "to": [to_email],
            "subject": "Seu código de verificação Vibra9",
            "html": html,
            "text": text,
        }
        result = resend.Emails.send(params)
        print(f"[email] Verificação enviada para {to_email}: {result.get('id', 'no-id')}")
        return True
    except Exception as e:
        print(f"[email] Erro ao enviar verificação para {to_email}: {e}")
        return False


def send_password_reset_email(to_email: str, token: str, name: str = "") -> bool:
    """Envia link/token de recuperação de senha."""
    if not is_email_configured():
        print(f"[email] RESEND_API_KEY ausente — token para {to_email}: {token}")
        return False

    greeting = f"Olá, {name}!" if name else "Olá!"

    html = f"""
    <div style="font-family: -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px; color: #1F2544;">
      <div style="text-align: center; margin-bottom: 32px;">
        <h1 style="color: #6B4FD8; font-size: 28px; margin: 0; font-weight: 700;">Vibra9</h1>
      </div>

      <h2 style="font-size: 20px; color: #1F2544; margin-bottom: 16px;">{greeting}</h2>

      <p style="font-size: 15px; line-height: 1.6; color: #4A4A6A;">
        Recebemos uma solicitação para redefinir a senha da sua conta no {APP_NAME}.
        Use o token abaixo para criar uma nova senha:
      </p>

      <div style="background: #F8F5FF; border: 1px solid #6B4FD8; border-radius: 14px; padding: 20px; margin: 20px 0; text-align: center;">
        <div style="color: #6B4FD8; font-size: 16px; font-weight: 700; word-break: break-all; font-family: 'Courier New', monospace;">
          {token}
        </div>
      </div>

      <p style="font-size: 14px; line-height: 1.6; color: #6B6F8A;">
        Este token expira em 1 hora. Se você não solicitou a recuperação, ignore este e-mail.
        Sua senha continua segura.
      </p>

      <hr style="border: none; border-top: 1px solid #E5E5EC; margin: 32px 0;">

      <p style="font-size: 12px; line-height: 1.5; color: #6B6F8A; text-align: center;">
        Vibra9 — Bem-estar e autoconhecimento em 9 dimensões.<br>
        Este é um e-mail automático, não responda.
      </p>
    </div>
    """

    text = f"""{greeting}

Recebemos uma solicitação para redefinir a senha da sua conta no {APP_NAME}.
Use o token abaixo para criar uma nova senha:

{token}

Este token expira em 1 hora. Se você não solicitou a recuperação, ignore este e-mail.
Sua senha continua segura.

—
Vibra9 — Bem-estar e autoconhecimento em 9 dimensões.
"""

    try:
        params = {
            "from": f"Vibra9 <{EMAIL_FROM}>",
            "to": [to_email],
            "subject": "Recuperação de senha Vibra9",
            "html": html,
            "text": text,
        }
        result = resend.Emails.send(params)
        print(f"[email] Recuperação enviada para {to_email}: {result.get('id', 'no-id')}")
        return True
    except Exception as e:
        print(f"[email] Erro ao enviar recuperação para {to_email}: {e}")
        return False
