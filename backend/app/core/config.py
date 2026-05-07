import os, sys, warnings
from dotenv import load_dotenv
from pathlib import Path

_env_path = Path(__file__).parent.parent.parent / ".env"
load_dotenv(dotenv_path=_env_path, override=True)

APP_NAME = "Vibra9 API"
APP_VERSION = "1.0.0"
DB_PATH = os.getenv("DB_PATH", "vibra9.db")
JWT_ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))
REFRESH_TOKEN_EXPIRE_DAYS = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "30"))
TRIAL_DAYS = int(os.getenv("TRIAL_DAYS", "15"))
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")

ALLOWED_ORIGINS = [
    o.strip() for o in
    os.getenv(
        "ALLOWED_ORIGINS",
        "http://localhost,http://localhost:4200,http://127.0.0.1,http://127.0.0.1:4200"
    ).split(",")
    if o.strip()
]

_raw = os.getenv("JWT_SECRET", "")
if not _raw:
    if ENVIRONMENT == "production":
        sys.exit("FATAL: JWT_SECRET nao definido. Obrigatorio em producao.")
    _raw = "dev-inseguro-trocar-antes-de-qualquer-deploy-32chars!!"
    warnings.warn("JWT_SECRET nao definido. Usando chave DEV. NAO use em producao.")
if len(_raw) < 32:
    raise ValueError("JWT_SECRET deve ter pelo menos 32 caracteres.")

JWT_SECRET: str = _raw
