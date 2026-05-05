import os
import uuid
import json
import hmac
import sqlite3
import hashlib
import secrets
import httpx

from datetime import datetime, timedelta, timezone
from typing import List, Optional, Dict, Any

from fastapi import FastAPI, HTTPException, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, EmailStr
from jose import jwt, JWTError


APP_NAME = "Vibra9 API"
DB_PATH = "vibra9.db"

JWT_SECRET = os.getenv("JWT_SECRET", "troque-esta-chave-em-producao")
JWT_ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "43200"))


app = FastAPI(
    title=APP_NAME,
    version="0.2.0",
    description="Backend do Vibra9 sem IA, com SQLite."
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:5173",
        "http://127.0.0.1",
        "*",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# DATABASE
# ============================================================

def get_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            created_at TEXT NOT NULL,
            privacy_policy_accepted_at TEXT NOT NULL,
            terms_accepted_at TEXT NOT NULL,
            subscription_active INTEGER NOT NULL DEFAULT 1,
            subscription_source TEXT NOT NULL DEFAULT 'mvp_manual'
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS assessments (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            general_score INTEGER NOT NULL,
            dimensions_json TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY(user_id) REFERENCES users(id)
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS recommendations (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            assessment_id TEXT NOT NULL,
            summary TEXT NOT NULL,
            main_focus TEXT NOT NULL,
            daily_actions_json TEXT NOT NULL,
            quote TEXT NOT NULL,
            quote_author TEXT NOT NULL,
            safety_note TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY(user_id) REFERENCES users(id),
            FOREIGN KEY(assessment_id) REFERENCES assessments(id)
        )
    """)

    conn.commit()
    conn.close()


@app.on_event("startup")
def on_startup():
    init_db()


# ============================================================
# SCHEMAS
# ============================================================

class RegisterRequest(BaseModel):
    name: str = Field(min_length=2, max_length=80)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    privacy_policy_accepted: bool
    terms_accepted: bool


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    name: str
    email: EmailStr


class AssessmentAnswer(BaseModel):
    question_id: str
    dimension: str
    score: int = Field(ge=0, le=10)


class AssessmentRequest(BaseModel):
    answers: List[AssessmentAnswer]


class DimensionScore(BaseModel):
    dimension: str
    label: str
    score: int
    status: str


class AssessmentResponse(BaseModel):
    assessment_id: str
    general_score: int
    dimensions: List[DimensionScore]
    created_at: str


class RecommendationRequest(BaseModel):
    assessment_id: str


class RecommendationResponse(BaseModel):
    recommendation_id: str
    assessment_id: str
    summary: str
    main_focus: str
    daily_actions: List[str]
    quote: str
    quote_author: str
    safety_note: str
    created_at: str


class DeleteAccountResponse(BaseModel):
    deleted: bool
    message: str


# ============================================================
# DIMENSIONS
# ============================================================

DIMENSIONS = {
    "clareza_mental": "Clareza mental",
    "estado_emocional": "Estado emocional",
    "proposito_pessoal": "Propósito pessoal",
    "energia_diaria": "Energia diária",
    "corpo_habitos": "Corpo e hábitos",
    "comunicacao": "Comunicação",
    "relacoes": "Relações",
    "rotina_foco": "Rotina e foco",
    "seguranca_financeira": "Segurança financeira",
}


RECOMMENDATION_LIBRARY = {
    "clareza_mental": {
        "low": [
            "Faça uma lista com apenas 3 prioridades para hoje.",
            "Reserve 5 minutos para respirar antes de começar uma tarefa importante.",
            "Evite alternar entre muitas tarefas ao mesmo tempo."
        ],
        "medium": [
            "Revise sua agenda e elimine uma tarefa que não seja essencial.",
            "Use um bloco de notas para descarregar pensamentos soltos.",
            "Defina um pequeno objetivo para concluir nas próximas 2 horas."
        ],
        "high": [
            "Aproveite sua clareza para planejar a semana com calma.",
            "Registre uma decisão importante que você conseguiu tomar hoje.",
            "Compartilhe uma ideia de forma simples com alguém de confiança."
        ],
    },
    "estado_emocional": {
        "low": [
            "Nomeie a emoção principal que você está sentindo agora.",
            "Faça uma pausa de 5 minutos sem tela.",
            "Escreva uma frase gentil para si mesmo."
        ],
        "medium": [
            "Observe o que mais influenciou seu humor hoje.",
            "Faça uma atividade pequena que traga sensação de cuidado.",
            "Evite tomar decisões importantes no pico da emoção."
        ],
        "high": [
            "Use seu equilíbrio emocional para apoiar uma conversa importante.",
            "Registre o que ajudou você a se sentir bem hoje.",
            "Mantenha uma rotina leve de autocuidado."
        ],
    },
    "proposito_pessoal": {
        "low": [
            "Escolha uma ação pequena que tenha sentido para você hoje.",
            "Relembre algo que você valoriza na sua vida.",
            "Evite comparar seu caminho com o de outras pessoas."
        ],
        "medium": [
            "Conecte uma tarefa comum a um objetivo maior.",
            "Faça algo simples que represente avanço pessoal.",
            "Anote uma área da vida que merece mais atenção."
        ],
        "high": [
            "Aproveite sua motivação para fortalecer um projeto importante.",
            "Compartilhe seu entusiasmo com alguém próximo.",
            "Transforme sua clareza de propósito em uma ação concreta."
        ],
    },
    "energia_diaria": {
        "low": [
            "Reduza o ritmo e escolha apenas o essencial para hoje.",
            "Beba água e faça uma pausa curta.",
            "Evite se cobrar produtividade máxima se o corpo pede descanso."
        ],
        "medium": [
            "Organize sua energia alternando foco e pausa.",
            "Faça uma caminhada curta se for possível.",
            "Priorize tarefas que exigem menos desgaste emocional."
        ],
        "high": [
            "Use sua energia para concluir uma tarefa pendente.",
            "Movimente o corpo de forma leve.",
            "Evite gastar energia com excesso de estímulos."
        ],
    },
    "corpo_habitos": {
        "low": [
            "Beba um copo de água agora.",
            "Faça alongamento leve por 3 minutos.",
            "Tente dormir um pouco mais cedo hoje."
        ],
        "medium": [
            "Inclua uma refeição simples e mais equilibrada.",
            "Faça uma pausa para perceber sua postura.",
            "Escolha um hábito saudável pequeno para repetir amanhã."
        ],
        "high": [
            "Mantenha o cuidado com sono, água e movimento.",
            "Registre qual hábito está funcionando melhor.",
            "Use sua boa disposição para consolidar uma rotina saudável."
        ],
    },
    "comunicacao": {
        "low": [
            "Antes de responder alguém, respire e organize sua ideia.",
            "Evite conversas difíceis quando estiver muito reativo.",
            "Escreva o que gostaria de dizer antes de falar."
        ],
        "medium": [
            "Pratique uma comunicação mais direta e gentil.",
            "Faça uma pergunta antes de presumir a intenção do outro.",
            "Revise uma mensagem importante antes de enviar."
        ],
        "high": [
            "Use sua clareza para resolver um mal-entendido.",
            "Demonstre reconhecimento a alguém.",
            "Compartilhe uma ideia importante com segurança."
        ],
    },
    "relacoes": {
        "low": [
            "Evite se isolar totalmente; envie uma mensagem simples a alguém confiável.",
            "Observe quais relações drenam sua energia hoje.",
            "Defina um limite saudável em uma interação."
        ],
        "medium": [
            "Fortaleça uma relação com uma atitude pequena.",
            "Escute alguém com atenção por alguns minutos.",
            "Evite assumir responsabilidades emocionais que não são suas."
        ],
        "high": [
            "Aproveite seu equilíbrio relacional para cultivar presença.",
            "Agradeça alguém que fez diferença recentemente.",
            "Mantenha vínculos que respeitam sua individualidade."
        ],
    },
    "rotina_foco": {
        "low": [
            "Escolha uma única tarefa para concluir agora.",
            "Use um temporizador de 20 minutos para foco.",
            "Remova uma distração do ambiente."
        ],
        "medium": [
            "Agrupe tarefas parecidas para reduzir troca de contexto.",
            "Defina horário para começar e terminar uma atividade.",
            "Celebre uma pequena conclusão do dia."
        ],
        "high": [
            "Use seu bom foco para avançar em uma prioridade real.",
            "Planeje o próximo dia em 5 minutos.",
            "Proteja blocos de tempo sem interrupção."
        ],
    },
    "seguranca_financeira": {
        "low": [
            "Anote um gasto pequeno de hoje.",
            "Evite compras por impulso nas próximas 24 horas.",
            "Olhe sua situação financeira com calma, sem culpa."
        ],
        "medium": [
            "Revise uma assinatura ou gasto recorrente.",
            "Defina um pequeno limite de gasto para a semana.",
            "Organize uma pendência financeira simples."
        ],
        "high": [
            "Aproveite sua organização para planejar uma meta financeira.",
            "Registre algo que melhorou sua segurança prática.",
            "Mantenha consistência em vez de perfeição."
        ],
    },
}


FALLBACK_QUOTES = [
    {
        "quote": "Pequenos passos consistentes constroem mudanças reais.",
        "author": "Vibra9"
    },
    {
        "quote": "Cuidar de si também é uma forma de responsabilidade.",
        "author": "Vibra9"
    },
    {
        "quote": "Clareza começa quando você reduz o ruído.",
        "author": "Vibra9"
    },
    {
        "quote": "Você não precisa resolver tudo hoje. Precisa apenas dar o próximo passo.",
        "author": "Vibra9"
    },
]


# ============================================================
# SECURITY
# ============================================================

def normalize_email(email: str) -> str:
    return email.strip().lower()


def hash_password(password: str) -> str:
    salt = secrets.token_hex(16)

    password_hash = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt.encode("utf-8"),
        120000,
    ).hex()

    return f"{salt}:{password_hash}"


def verify_password(password: str, password_hash: str) -> bool:
    try:
        salt, stored_hash = password_hash.split(":", 1)
    except ValueError:
        return False

    calculated_hash = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt.encode("utf-8"),
        120000,
    ).hex()

    return hmac.compare_digest(calculated_hash, stored_hash)


def create_access_token(user_id: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)

    payload = {
        "sub": user_id,
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "type": "access",
    }

    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


async def get_current_user(authorization: Optional[str] = Header(default=None)) -> Dict[str, Any]:
    if not authorization:
        raise HTTPException(status_code=401, detail="Token ausente.")

    parts = authorization.split()

    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(status_code=401, detail="Formato de token inválido.")

    token = parts[1]

    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        user_id = payload.get("sub")
    except JWTError:
        raise HTTPException(status_code=401, detail="Token inválido ou expirado.")

    conn = get_connection()
    user = conn.execute(
        "SELECT * FROM users WHERE id = ?",
        (user_id,)
    ).fetchone()
    conn.close()

    if not user:
        raise HTTPException(status_code=401, detail="Usuário não encontrado.")

    return dict(user)


def require_active_subscription(user: Dict[str, Any]) -> None:
    if int(user.get("subscription_active", 0)) != 1:
        raise HTTPException(
            status_code=402,
            detail="Assinatura inativa. Ative o plano mensal para continuar."
        )


# ============================================================
# BUSINESS RULES
# ============================================================

def status_from_score(score: int) -> str:
    if score <= 4:
        return "atenção"
    if score <= 7:
        return "em_desenvolvimento"
    return "equilibrado"


def category_from_score(score: int) -> str:
    if score <= 4:
        return "low"
    if score <= 7:
        return "medium"
    return "high"


def calculate_assessment(answers: List[AssessmentAnswer]) -> List[DimensionScore]:
    grouped: Dict[str, List[int]] = {}

    for answer in answers:
        if answer.dimension not in DIMENSIONS:
            raise HTTPException(
                status_code=400,
                detail=f"Dimensão inválida: {answer.dimension}"
            )

        grouped.setdefault(answer.dimension, []).append(answer.score)

    result: List[DimensionScore] = []

    for key, label in DIMENSIONS.items():
        values = grouped.get(key, [])

        if not values:
            score = 0
        else:
            score = round(sum(values) / len(values))

        result.append(
            DimensionScore(
                dimension=key,
                label=label,
                score=score,
                status=status_from_score(score),
            )
        )

    return result


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
    dimensions = [
        DimensionScore(**item)
        for item in assessment["dimensions"]
    ]

    weakest = min(dimensions, key=lambda item: item.score)
    strongest = max(dimensions, key=lambda item: item.score)

    category = category_from_score(weakest.score)

    actions = RECOMMENDATION_LIBRARY[weakest.dimension][category]

    summary = build_summary(
        general_score=assessment["general_score"],
        weakest=weakest,
        strongest=strongest,
    )

    return {
        "summary": summary,
        "main_focus": weakest.label,
        "daily_actions": actions,
    }


async def get_external_quote() -> Dict[str, str]:
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            response = await client.get("https://zenquotes.io/api/random")
            response.raise_for_status()

            data = response.json()

            if isinstance(data, list) and len(data) > 0:
                quote = data[0].get("q")
                author = data[0].get("a")

                if quote and author:
                    return {
                        "quote": quote,
                        "author": author,
                    }

    except Exception:
        pass

    index = datetime.now(timezone.utc).timetuple().tm_yday % len(FALLBACK_QUOTES)

    return FALLBACK_QUOTES[index]


# ============================================================
# ROUTES
# ============================================================

@app.get("/")
def health_check():
    return {
        "app": APP_NAME,
        "status": "online",
        "version": "0.2.0",
        "database": DB_PATH,
    }


@app.post("/auth/register", response_model=AuthResponse)
def register(payload: RegisterRequest):
    if not payload.privacy_policy_accepted:
        raise HTTPException(
            status_code=400,
            detail="É necessário aceitar a Política de Privacidade."
        )

    if not payload.terms_accepted:
        raise HTTPException(
            status_code=400,
            detail="É necessário aceitar os Termos de Uso."
        )

    email = normalize_email(payload.email)

    conn = get_connection()

    existing = conn.execute(
        "SELECT id FROM users WHERE email = ?",
        (email,)
    ).fetchone()

    if existing:
        conn.close()
        raise HTTPException(status_code=409, detail="E-mail já cadastrado.")

    user_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()

    conn.execute(
        """
        INSERT INTO users (
            id,
            name,
            email,
            password_hash,
            created_at,
            privacy_policy_accepted_at,
            terms_accepted_at,
            subscription_active,
            subscription_source
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            user_id,
            payload.name.strip(),
            email,
            hash_password(payload.password),
            now,
            now,
            now,
            1,
            "mvp_manual",
        )
    )

    conn.commit()
    conn.close()

    token = create_access_token(user_id)

    return AuthResponse(
        access_token=token,
        user_id=user_id,
        name=payload.name.strip(),
        email=email,
    )


@app.post("/auth/login", response_model=AuthResponse)
def login(payload: LoginRequest):
    email = normalize_email(payload.email)

    conn = get_connection()
    user = conn.execute(
        "SELECT * FROM users WHERE email = ?",
        (email,)
    ).fetchone()
    conn.close()

    if not user:
        raise HTTPException(status_code=401, detail="E-mail ou senha inválidos.")

    user_dict = dict(user)

    if not verify_password(payload.password, user_dict["password_hash"]):
        raise HTTPException(status_code=401, detail="E-mail ou senha inválidos.")

    token = create_access_token(user_dict["id"])

    return AuthResponse(
        access_token=token,
        user_id=user_dict["id"],
        name=user_dict["name"],
        email=user_dict["email"],
    )


@app.get("/me")
def get_me(user: Dict[str, Any] = Depends(get_current_user)):
    return {
        "id": user["id"],
        "name": user["name"],
        "email": user["email"],
        "subscription_active": bool(user["subscription_active"]),
        "created_at": user["created_at"],
    }


@app.get("/assessment/questions")
def get_questions(user: Dict[str, Any] = Depends(get_current_user)):
    require_active_subscription(user)

    return {
        "questions": [
            {
                "question_id": "mental_1",
                "dimension": "clareza_mental",
                "text": "Hoje, consigo organizar meus pensamentos com clareza?",
                "scale_min": 0,
                "scale_max": 10,
            },
            {
                "question_id": "emocional_1",
                "dimension": "estado_emocional",
                "text": "Hoje, consigo reconhecer meu estado emocional sem me julgar?",
                "scale_min": 0,
                "scale_max": 10,
            },
            {
                "question_id": "proposito_1",
                "dimension": "proposito_pessoal",
                "text": "Hoje, sinto que minhas ações têm algum sentido para mim?",
                "scale_min": 0,
                "scale_max": 10,
            },
            {
                "question_id": "energia_1",
                "dimension": "energia_diaria",
                "text": "Hoje, tenho energia suficiente para lidar com minha rotina?",
                "scale_min": 0,
                "scale_max": 10,
            },
            {
                "question_id": "corpo_1",
                "dimension": "corpo_habitos",
                "text": "Hoje, cuidei minimamente do meu corpo, sono, água ou movimento?",
                "scale_min": 0,
                "scale_max": 10,
            },
            {
                "question_id": "comunicacao_1",
                "dimension": "comunicacao",
                "text": "Hoje, consigo me expressar com clareza e respeito?",
                "scale_min": 0,
                "scale_max": 10,
            },
            {
                "question_id": "relacoes_1",
                "dimension": "relacoes",
                "text": "Hoje, minhas relações contribuem para meu equilíbrio?",
                "scale_min": 0,
                "scale_max": 10,
            },
            {
                "question_id": "rotina_1",
                "dimension": "rotina_foco",
                "text": "Hoje, consigo manter foco em pelo menos uma prioridade?",
                "scale_min": 0,
                "scale_max": 10,
            },
            {
                "question_id": "financeiro_1",
                "dimension": "seguranca_financeira",
                "text": "Hoje, sinto que minha vida prática e financeira está minimamente organizada?",
                "scale_min": 0,
                "scale_max": 10,
            },
        ]
    }


@app.post("/assessment", response_model=AssessmentResponse)
def create_assessment(
    payload: AssessmentRequest,
    user: Dict[str, Any] = Depends(get_current_user),
):
    require_active_subscription(user)

    if len(payload.answers) < 9:
        raise HTTPException(
            status_code=400,
            detail="Envie pelo menos uma resposta para cada uma das 9 dimensões."
        )

    dimensions = calculate_assessment(payload.answers)
    general_score = round(sum(item.score for item in dimensions) / len(dimensions) * 10)

    assessment_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()

    dimensions_payload = [item.model_dump() for item in dimensions]

    conn = get_connection()
    conn.execute(
        """
        INSERT INTO assessments (
            id,
            user_id,
            general_score,
            dimensions_json,
            created_at
        ) VALUES (?, ?, ?, ?, ?)
        """,
        (
            assessment_id,
            user["id"],
            general_score,
            json.dumps(dimensions_payload, ensure_ascii=False),
            now,
        )
    )
    conn.commit()
    conn.close()

    return AssessmentResponse(
        assessment_id=assessment_id,
        general_score=general_score,
        dimensions=dimensions,
        created_at=now,
    )


@app.post("/recommendations", response_model=RecommendationResponse)
async def create_recommendation(
    payload: RecommendationRequest,
    user: Dict[str, Any] = Depends(get_current_user),
):
    require_active_subscription(user)

    conn = get_connection()
    row = conn.execute(
        "SELECT * FROM assessments WHERE id = ? AND user_id = ?",
        (payload.assessment_id, user["id"])
    ).fetchone()

    if not row:
        conn.close()
        raise HTTPException(status_code=404, detail="Avaliação não encontrada.")

    assessment = dict(row)
    assessment["dimensions"] = json.loads(assessment["dimensions_json"])

    generated = generate_recommendations(assessment)
    quote = await get_external_quote()

    recommendation_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()

    safety_note = (
        "Este app oferece orientações gerais de bem-estar e autoconhecimento. "
        "Ele não substitui acompanhamento médico, psicológico, financeiro ou terapêutico."
    )

    conn.execute(
        """
        INSERT INTO recommendations (
            id,
            user_id,
            assessment_id,
            summary,
            main_focus,
            daily_actions_json,
            quote,
            quote_author,
            safety_note,
            created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            recommendation_id,
            user["id"],
            assessment["id"],
            generated["summary"],
            generated["main_focus"],
            json.dumps(generated["daily_actions"], ensure_ascii=False),
            quote["quote"],
            quote["author"],
            safety_note,
            now,
        )
    )

    conn.commit()
    conn.close()

    return RecommendationResponse(
        recommendation_id=recommendation_id,
        assessment_id=assessment["id"],
        summary=generated["summary"],
        main_focus=generated["main_focus"],
        daily_actions=generated["daily_actions"],
        quote=quote["quote"],
        quote_author=quote["author"],
        safety_note=safety_note,
        created_at=now,
    )


@app.get("/history")
def get_history(user: Dict[str, Any] = Depends(get_current_user)):
    require_active_subscription(user)

    conn = get_connection()
    rows = conn.execute(
        """
        SELECT *
        FROM assessments
        WHERE user_id = ?
        ORDER BY created_at DESC
        """,
        (user["id"],)
    ).fetchall()
    conn.close()

    items = []

    for row in rows:
        item = dict(row)
        item["dimensions"] = json.loads(item["dimensions_json"])
        del item["dimensions_json"]
        items.append(item)

    return {
        "items": items
    }


@app.delete("/me", response_model=DeleteAccountResponse)
def delete_me(user: Dict[str, Any] = Depends(get_current_user)):
    conn = get_connection()

    conn.execute(
        "DELETE FROM recommendations WHERE user_id = ?",
        (user["id"],)
    )

    conn.execute(
        "DELETE FROM assessments WHERE user_id = ?",
        (user["id"],)
    )

    conn.execute(
        "DELETE FROM users WHERE id = ?",
        (user["id"],)
    )

    conn.commit()
    conn.close()

    return DeleteAccountResponse(
        deleted=True,
        message="Conta e dados associados removidos."
    )

@app.get("/me/export")
def export_my_data(user: Dict[str, Any] = Depends(get_current_user)):
    conn = get_connection()

    assessment_rows = conn.execute(
        """
        SELECT *
        FROM assessments
        WHERE user_id = ?
        ORDER BY created_at DESC
        """,
        (user["id"],)
    ).fetchall()

    recommendation_rows = conn.execute(
        """
        SELECT *
        FROM recommendations
        WHERE user_id = ?
        ORDER BY created_at DESC
        """,
        (user["id"],)
    ).fetchall()

    conn.close()

    assessments = []

    for row in assessment_rows:
        item = dict(row)
        item["dimensions"] = json.loads(item["dimensions_json"])
        del item["dimensions_json"]
        assessments.append(item)

    recommendations = []

    for row in recommendation_rows:
        item = dict(row)
        item["daily_actions"] = json.loads(item["daily_actions_json"])
        del item["daily_actions_json"]
        recommendations.append(item)

    return {
        "user": {
            "id": user["id"],
            "name": user["name"],
            "email": user["email"],
            "created_at": user["created_at"],
            "subscription_active": bool(user["subscription_active"]),
            "subscription_source": user["subscription_source"],
        },
        "assessments": assessments,
        "recommendations": recommendations,
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "note": "Exportação de dados do usuário para transparência e portabilidade."
    }

def normalize_deep_dimension_key(label: str) -> str:
    value = label.strip().lower()
    replacements = {
        "ç": "c",
        "ã": "a",
        "á": "a",
        "à": "a",
        "â": "a",
        "é": "e",
        "ê": "e",
        "í": "i",
        "ó": "o",
        "ô": "o",
        "õ": "o",
        "ú": "u",
        " ": "_",
        "-": "_",
    }

    for old, new in replacements.items():
        value = value.replace(old, new)

    return f"checkup_{value}"


@app.post("/deep-checkin")
def create_deep_checkin(
    payload: Dict[str, Any],
    user: Dict[str, Any] = Depends(get_current_user),
):
    require_active_subscription(user)

    general_score = int(payload.get("general_score", 0))
    overload_score = int(payload.get("overload_score", 0))
    raw_dimensions = payload.get("dimensions", [])

    if general_score < 0 or general_score > 100:
        raise HTTPException(
            status_code=400,
            detail="Pontuação geral inválida."
        )

    if not isinstance(raw_dimensions, list) or len(raw_dimensions) == 0:
        raise HTTPException(
            status_code=400,
            detail="Dimensões do check-up ausentes."
        )

    dimensions_payload = []

    for item in raw_dimensions:
        label = str(item.get("label", "Dimensão"))
        raw_score = int(item.get("score", 0))

        if raw_score < 0:
            raw_score = 0

        if raw_score > 100:
            raw_score = 100

        score_0_10 = round(raw_score / 10)

        dimensions_payload.append({
            "dimension": normalize_deep_dimension_key(label),
            "label": label,
            "score": score_0_10,
            "status": status_from_score(score_0_10),
            "source": "checkup_ampliado",
            "raw_score": raw_score,
            "overload_score": overload_score,
        })

    assessment_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()

    conn = get_connection()
    conn.execute(
        """
        INSERT INTO assessments (
            id,
            user_id,
            general_score,
            dimensions_json,
            created_at
        ) VALUES (?, ?, ?, ?, ?)
        """,
        (
            assessment_id,
            user["id"],
            general_score,
            json.dumps(dimensions_payload, ensure_ascii=False),
            now,
        )
    )

    conn.commit()
    conn.close()

    return {
        "assessment_id": assessment_id,
        "general_score": general_score,
        "dimensions": dimensions_payload,
        "created_at": now,
        "source": "checkup_ampliado",
        "message": "Check-up ampliado salvo no histórico."
    }

def normalize_deep_dimension_key(label: str) -> str:
    value = label.strip().lower()
    replacements = {
        "ç": "c",
        "ã": "a",
        "á": "a",
        "à": "a",
        "â": "a",
        "é": "e",
        "ê": "e",
        "í": "i",
        "ó": "o",
        "ô": "o",
        "õ": "o",
        "ú": "u",
        " ": "_",
        "-": "_",
    }

    for old, new in replacements.items():
        value = value.replace(old, new)

    return f"checkup_{value}"


@app.post("/deep-checkin")
def create_deep_checkin(
    payload: Dict[str, Any],
    user: Dict[str, Any] = Depends(get_current_user),
):
    require_active_subscription(user)

    general_score = int(payload.get("general_score", 0))
    overload_score = int(payload.get("overload_score", 0))
    raw_dimensions = payload.get("dimensions", [])

    if general_score < 0 or general_score > 100:
        raise HTTPException(
            status_code=400,
            detail="Pontuação geral inválida."
        )

    if not isinstance(raw_dimensions, list) or len(raw_dimensions) == 0:
        raise HTTPException(
            status_code=400,
            detail="Dimensões do check-up ausentes."
        )

    dimensions_payload = []

    for item in raw_dimensions:
        label = str(item.get("label", "Dimensão"))
        raw_score = int(item.get("score", 0))

        if raw_score < 0:
            raw_score = 0

        if raw_score > 100:
            raw_score = 100

        score_0_10 = round(raw_score / 10)

        dimensions_payload.append({
            "dimension": normalize_deep_dimension_key(label),
            "label": label,
            "score": score_0_10,
            "status": status_from_score(score_0_10),
            "source": "checkup_ampliado",
            "raw_score": raw_score,
            "overload_score": overload_score,
        })

    assessment_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()

    conn = get_connection()
    conn.execute(
        """
        INSERT INTO assessments (
            id,
            user_id,
            general_score,
            dimensions_json,
            created_at
        ) VALUES (?, ?, ?, ?, ?)
        """,
        (
            assessment_id,
            user["id"],
            general_score,
            json.dumps(dimensions_payload, ensure_ascii=False),
            now,
        )
    )

    conn.commit()
    conn.close()

    return {
        "assessment_id": assessment_id,
        "general_score": general_score,
        "dimensions": dimensions_payload,
        "created_at": now,
        "source": "checkup_ampliado",
        "message": "Check-up ampliado salvo no histórico."
    }

def normalize_deep_dimension_key(label: str) -> str:
    value = label.strip().lower()
    replacements = {
        "ç": "c",
        "ã": "a",
        "á": "a",
        "à": "a",
        "â": "a",
        "é": "e",
        "ê": "e",
        "í": "i",
        "ó": "o",
        "ô": "o",
        "õ": "o",
        "ú": "u",
        " ": "_",
        "-": "_",
    }

    for old, new in replacements.items():
        value = value.replace(old, new)

    return f"checkup_{value}"


@app.post("/deep-checkin")
def create_deep_checkin(
    payload: Dict[str, Any],
    user: Dict[str, Any] = Depends(get_current_user),
):
    require_active_subscription(user)

    general_score = int(payload.get("general_score", 0))
    overload_score = int(payload.get("overload_score", 0))
    raw_dimensions = payload.get("dimensions", [])

    if general_score < 0 or general_score > 100:
        raise HTTPException(
            status_code=400,
            detail="Pontuação geral inválida."
        )

    if not isinstance(raw_dimensions, list) or len(raw_dimensions) == 0:
        raise HTTPException(
            status_code=400,
            detail="Dimensões do check-up ausentes."
        )

    dimensions_payload = []

    for item in raw_dimensions:
        label = str(item.get("label", "Dimensão"))
        raw_score = int(item.get("score", 0))

        if raw_score < 0:
            raw_score = 0

        if raw_score > 100:
            raw_score = 100

        score_0_10 = round(raw_score / 10)

        dimensions_payload.append({
            "dimension": normalize_deep_dimension_key(label),
            "label": label,
            "score": score_0_10,
            "status": status_from_score(score_0_10),
            "source": "checkup_ampliado",
            "raw_score": raw_score,
            "overload_score": overload_score,
        })

    assessment_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()

    conn = get_connection()
    conn.execute(
        """
        INSERT INTO assessments (
            id,
            user_id,
            general_score,
            dimensions_json,
            created_at
        ) VALUES (?, ?, ?, ?, ?)
        """,
        (
            assessment_id,
            user["id"],
            general_score,
            json.dumps(dimensions_payload, ensure_ascii=False),
            now,
        )
    )

    conn.commit()
    conn.close()

    return {
        "assessment_id": assessment_id,
        "general_score": general_score,
        "dimensions": dimensions_payload,
        "created_at": now,
        "source": "checkup_ampliado",
        "message": "Check-up ampliado salvo no histórico."
    }
import os
import uuid
import json
import hmac
import sqlite3
import hashlib
import secrets
import httpx

from datetime import datetime, timedelta, timezone
from typing import List, Optional, Dict, Any

from fastapi import FastAPI, HTTPException, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, EmailStr
from jose import jwt, JWTError


APP_NAME = "Vibra9 API"
DB_PATH = "vibra9.db"

JWT_SECRET = os.getenv("JWT_SECRET", "troque-esta-chave-em-producao")
JWT_ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "43200"))


app = FastAPI(
    title=APP_NAME,
    version="0.2.0",
    description="Backend do Vibra9 sem IA, com SQLite."
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:5173",
        "http://127.0.0.1",
        "*",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# DATABASE
# ============================================================

def get_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            created_at TEXT NOT NULL,
            privacy_policy_accepted_at TEXT NOT NULL,
            terms_accepted_at TEXT NOT NULL,
            subscription_active INTEGER NOT NULL DEFAULT 1,
            subscription_source TEXT NOT NULL DEFAULT 'mvp_manual'
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS assessments (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            general_score INTEGER NOT NULL,
            dimensions_json TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY(user_id) REFERENCES users(id)
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS recommendations (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            assessment_id TEXT NOT NULL,
            summary TEXT NOT NULL,
            main_focus TEXT NOT NULL,
            daily_actions_json TEXT NOT NULL,
            quote TEXT NOT NULL,
            quote_author TEXT NOT NULL,
            safety_note TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY(user_id) REFERENCES users(id),
            FOREIGN KEY(assessment_id) REFERENCES assessments(id)
        )
    """)

    conn.commit()
    conn.close()


@app.on_event("startup")
def on_startup():
    init_db()


# ============================================================
# SCHEMAS
# ============================================================

class RegisterRequest(BaseModel):
    name: str = Field(min_length=2, max_length=80)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    privacy_policy_accepted: bool
    terms_accepted: bool


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    name: str
    email: EmailStr


class AssessmentAnswer(BaseModel):
    question_id: str
    dimension: str
    score: int = Field(ge=0, le=10)


class AssessmentRequest(BaseModel):
    answers: List[AssessmentAnswer]


class DimensionScore(BaseModel):
    dimension: str
    label: str
    score: int
    status: str


class AssessmentResponse(BaseModel):
    assessment_id: str
    general_score: int
    dimensions: List[DimensionScore]
    created_at: str


class RecommendationRequest(BaseModel):
    assessment_id: str


class RecommendationResponse(BaseModel):
    recommendation_id: str
    assessment_id: str
    summary: str
    main_focus: str
    daily_actions: List[str]
    quote: str
    quote_author: str
    safety_note: str
    created_at: str


class DeleteAccountResponse(BaseModel):
    deleted: bool
    message: str


# ============================================================
# DIMENSIONS
# ============================================================

DIMENSIONS = {
    "clareza_mental": "Clareza mental",
    "estado_emocional": "Estado emocional",
    "proposito_pessoal": "Propósito pessoal",
    "energia_diaria": "Energia diária",
    "corpo_habitos": "Corpo e hábitos",
    "comunicacao": "Comunicação",
    "relacoes": "Relações",
    "rotina_foco": "Rotina e foco",
    "seguranca_financeira": "Segurança financeira",
}


RECOMMENDATION_LIBRARY = {
    "clareza_mental": {
        "low": [
            "Faça uma lista com apenas 3 prioridades para hoje.",
            "Reserve 5 minutos para respirar antes de começar uma tarefa importante.",
            "Evite alternar entre muitas tarefas ao mesmo tempo."
        ],
        "medium": [
            "Revise sua agenda e elimine uma tarefa que não seja essencial.",
            "Use um bloco de notas para descarregar pensamentos soltos.",
            "Defina um pequeno objetivo para concluir nas próximas 2 horas."
        ],
        "high": [
            "Aproveite sua clareza para planejar a semana com calma.",
            "Registre uma decisão importante que você conseguiu tomar hoje.",
            "Compartilhe uma ideia de forma simples com alguém de confiança."
        ],
    },
    "estado_emocional": {
        "low": [
            "Nomeie a emoção principal que você está sentindo agora.",
            "Faça uma pausa de 5 minutos sem tela.",
            "Escreva uma frase gentil para si mesmo."
        ],
        "medium": [
            "Observe o que mais influenciou seu humor hoje.",
            "Faça uma atividade pequena que traga sensação de cuidado.",
            "Evite tomar decisões importantes no pico da emoção."
        ],
        "high": [
            "Use seu equilíbrio emocional para apoiar uma conversa importante.",
            "Registre o que ajudou você a se sentir bem hoje.",
            "Mantenha uma rotina leve de autocuidado."
        ],
    },
    "proposito_pessoal": {
        "low": [
            "Escolha uma ação pequena que tenha sentido para você hoje.",
            "Relembre algo que você valoriza na sua vida.",
            "Evite comparar seu caminho com o de outras pessoas."
        ],
        "medium": [
            "Conecte uma tarefa comum a um objetivo maior.",
            "Faça algo simples que represente avanço pessoal.",
            "Anote uma área da vida que merece mais atenção."
        ],
        "high": [
            "Aproveite sua motivação para fortalecer um projeto importante.",
            "Compartilhe seu entusiasmo com alguém próximo.",
            "Transforme sua clareza de propósito em uma ação concreta."
        ],
    },
    "energia_diaria": {
        "low": [
            "Reduza o ritmo e escolha apenas o essencial para hoje.",
            "Beba água e faça uma pausa curta.",
            "Evite se cobrar produtividade máxima se o corpo pede descanso."
        ],
        "medium": [
            "Organize sua energia alternando foco e pausa.",
            "Faça uma caminhada curta se for possível.",
            "Priorize tarefas que exigem menos desgaste emocional."
        ],
        "high": [
            "Use sua energia para concluir uma tarefa pendente.",
            "Movimente o corpo de forma leve.",
            "Evite gastar energia com excesso de estímulos."
        ],
    },
    "corpo_habitos": {
        "low": [
            "Beba um copo de água agora.",
            "Faça alongamento leve por 3 minutos.",
            "Tente dormir um pouco mais cedo hoje."
        ],
        "medium": [
            "Inclua uma refeição simples e mais equilibrada.",
            "Faça uma pausa para perceber sua postura.",
            "Escolha um hábito saudável pequeno para repetir amanhã."
        ],
        "high": [
            "Mantenha o cuidado com sono, água e movimento.",
            "Registre qual hábito está funcionando melhor.",
            "Use sua boa disposição para consolidar uma rotina saudável."
        ],
    },
    "comunicacao": {
        "low": [
            "Antes de responder alguém, respire e organize sua ideia.",
            "Evite conversas difíceis quando estiver muito reativo.",
            "Escreva o que gostaria de dizer antes de falar."
        ],
        "medium": [
            "Pratique uma comunicação mais direta e gentil.",
            "Faça uma pergunta antes de presumir a intenção do outro.",
            "Revise uma mensagem importante antes de enviar."
        ],
        "high": [
            "Use sua clareza para resolver um mal-entendido.",
            "Demonstre reconhecimento a alguém.",
            "Compartilhe uma ideia importante com segurança."
        ],
    },
    "relacoes": {
        "low": [
            "Evite se isolar totalmente; envie uma mensagem simples a alguém confiável.",
            "Observe quais relações drenam sua energia hoje.",
            "Defina um limite saudável em uma interação."
        ],
        "medium": [
            "Fortaleça uma relação com uma atitude pequena.",
            "Escute alguém com atenção por alguns minutos.",
            "Evite assumir responsabilidades emocionais que não são suas."
        ],
        "high": [
            "Aproveite seu equilíbrio relacional para cultivar presença.",
            "Agradeça alguém que fez diferença recentemente.",
            "Mantenha vínculos que respeitam sua individualidade."
        ],
    },
    "rotina_foco": {
        "low": [
            "Escolha uma única tarefa para concluir agora.",
            "Use um temporizador de 20 minutos para foco.",
            "Remova uma distração do ambiente."
        ],
        "medium": [
            "Agrupe tarefas parecidas para reduzir troca de contexto.",
            "Defina horário para começar e terminar uma atividade.",
            "Celebre uma pequena conclusão do dia."
        ],
        "high": [
            "Use seu bom foco para avançar em uma prioridade real.",
            "Planeje o próximo dia em 5 minutos.",
            "Proteja blocos de tempo sem interrupção."
        ],
    },
    "seguranca_financeira": {
        "low": [
            "Anote um gasto pequeno de hoje.",
            "Evite compras por impulso nas próximas 24 horas.",
            "Olhe sua situação financeira com calma, sem culpa."
        ],
        "medium": [
            "Revise uma assinatura ou gasto recorrente.",
            "Defina um pequeno limite de gasto para a semana.",
            "Organize uma pendência financeira simples."
        ],
        "high": [
            "Aproveite sua organização para planejar uma meta financeira.",
            "Registre algo que melhorou sua segurança prática.",
            "Mantenha consistência em vez de perfeição."
        ],
    },
}


FALLBACK_QUOTES = [
    {
        "quote": "Pequenos passos consistentes constroem mudanças reais.",
        "author": "Vibra9"
    },
    {
        "quote": "Cuidar de si também é uma forma de responsabilidade.",
        "author": "Vibra9"
    },
    {
        "quote": "Clareza começa quando você reduz o ruído.",
        "author": "Vibra9"
    },
    {
        "quote": "Você não precisa resolver tudo hoje. Precisa apenas dar o próximo passo.",
        "author": "Vibra9"
    },
]


# ============================================================
# SECURITY
# ============================================================

def normalize_email(email: str) -> str:
    return email.strip().lower()


def hash_password(password: str) -> str:
    salt = secrets.token_hex(16)

    password_hash = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt.encode("utf-8"),
        120000,
    ).hex()

    return f"{salt}:{password_hash}"


def verify_password(password: str, password_hash: str) -> bool:
    try:
        salt, stored_hash = password_hash.split(":", 1)
    except ValueError:
        return False

    calculated_hash = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt.encode("utf-8"),
        120000,
    ).hex()

    return hmac.compare_digest(calculated_hash, stored_hash)


def create_access_token(user_id: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)

    payload = {
        "sub": user_id,
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "type": "access",
    }

    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


async def get_current_user(authorization: Optional[str] = Header(default=None)) -> Dict[str, Any]:
    if not authorization:
        raise HTTPException(status_code=401, detail="Token ausente.")

    parts = authorization.split()

    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(status_code=401, detail="Formato de token inválido.")

    token = parts[1]

    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        user_id = payload.get("sub")
    except JWTError:
        raise HTTPException(status_code=401, detail="Token inválido ou expirado.")

    conn = get_connection()
    user = conn.execute(
        "SELECT * FROM users WHERE id = ?",
        (user_id,)
    ).fetchone()
    conn.close()

    if not user:
        raise HTTPException(status_code=401, detail="Usuário não encontrado.")

    return dict(user)


def require_active_subscription(user: Dict[str, Any]) -> None:
    if int(user.get("subscription_active", 0)) != 1:
        raise HTTPException(
            status_code=402,
            detail="Assinatura inativa. Ative o plano mensal para continuar."
        )


# ============================================================
# BUSINESS RULES
# ============================================================

def status_from_score(score: int) -> str:
    if score <= 4:
        return "atenção"
    if score <= 7:
        return "em_desenvolvimento"
    return "equilibrado"


def category_from_score(score: int) -> str:
    if score <= 4:
        return "low"
    if score <= 7:
        return "medium"
    return "high"


def calculate_assessment(answers: List[AssessmentAnswer]) -> List[DimensionScore]:
    grouped: Dict[str, List[int]] = {}

    for answer in answers:
        if answer.dimension not in DIMENSIONS:
            raise HTTPException(
                status_code=400,
                detail=f"Dimensão inválida: {answer.dimension}"
            )

        grouped.setdefault(answer.dimension, []).append(answer.score)

    result: List[DimensionScore] = []

    for key, label in DIMENSIONS.items():
        values = grouped.get(key, [])

        if not values:
            score = 0
        else:
            score = round(sum(values) / len(values))

        result.append(
            DimensionScore(
                dimension=key,
                label=label,
                score=score,
                status=status_from_score(score),
            )
        )

    return result


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
    dimensions = [
        DimensionScore(**item)
        for item in assessment["dimensions"]
    ]

    weakest = min(dimensions, key=lambda item: item.score)
    strongest = max(dimensions, key=lambda item: item.score)

    category = category_from_score(weakest.score)

    actions = RECOMMENDATION_LIBRARY[weakest.dimension][category]

    summary = build_summary(
        general_score=assessment["general_score"],
        weakest=weakest,
        strongest=strongest,
    )

    return {
        "summary": summary,
        "main_focus": weakest.label,
        "daily_actions": actions,
    }


async def get_external_quote() -> Dict[str, str]:
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            response = await client.get("https://zenquotes.io/api/random")
            response.raise_for_status()

            data = response.json()

            if isinstance(data, list) and len(data) > 0:
                quote = data[0].get("q")
                author = data[0].get("a")

                if quote and author:
                    return {
                        "quote": quote,
                        "author": author,
                    }

    except Exception:
        pass

    index = datetime.now(timezone.utc).timetuple().tm_yday % len(FALLBACK_QUOTES)

    return FALLBACK_QUOTES[index]


# ============================================================
# ROUTES
# ============================================================

@app.get("/")
def health_check():
    return {
        "app": APP_NAME,
        "status": "online",
        "version": "0.2.0",
        "database": DB_PATH,
    }


@app.post("/auth/register", response_model=AuthResponse)
def register(payload: RegisterRequest):
    if not payload.privacy_policy_accepted:
        raise HTTPException(
            status_code=400,
            detail="É necessário aceitar a Política de Privacidade."
        )

    if not payload.terms_accepted:
        raise HTTPException(
            status_code=400,
            detail="É necessário aceitar os Termos de Uso."
        )

    email = normalize_email(payload.email)

    conn = get_connection()

    existing = conn.execute(
        "SELECT id FROM users WHERE email = ?",
        (email,)
    ).fetchone()

    if existing:
        conn.close()
        raise HTTPException(status_code=409, detail="E-mail já cadastrado.")

    user_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()

    conn.execute(
        """
        INSERT INTO users (
            id,
            name,
            email,
            password_hash,
            created_at,
            privacy_policy_accepted_at,
            terms_accepted_at,
            subscription_active,
            subscription_source
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            user_id,
            payload.name.strip(),
            email,
            hash_password(payload.password),
            now,
            now,
            now,
            1,
            "mvp_manual",
        )
    )

    conn.commit()
    conn.close()

    token = create_access_token(user_id)

    return AuthResponse(
        access_token=token,
        user_id=user_id,
        name=payload.name.strip(),
        email=email,
    )


@app.post("/auth/login", response_model=AuthResponse)
def login(payload: LoginRequest):
    email = normalize_email(payload.email)

    conn = get_connection()
    user = conn.execute(
        "SELECT * FROM users WHERE email = ?",
        (email,)
    ).fetchone()
    conn.close()

    if not user:
        raise HTTPException(status_code=401, detail="E-mail ou senha inválidos.")

    user_dict = dict(user)

    if not verify_password(payload.password, user_dict["password_hash"]):
        raise HTTPException(status_code=401, detail="E-mail ou senha inválidos.")

    token = create_access_token(user_dict["id"])

    return AuthResponse(
        access_token=token,
        user_id=user_dict["id"],
        name=user_dict["name"],
        email=user_dict["email"],
    )


@app.get("/me")
def get_me(user: Dict[str, Any] = Depends(get_current_user)):
    return {
        "id": user["id"],
        "name": user["name"],
        "email": user["email"],
        "subscription_active": bool(user["subscription_active"]),
        "created_at": user["created_at"],
    }


@app.get("/assessment/questions")
def get_questions(user: Dict[str, Any] = Depends(get_current_user)):
    require_active_subscription(user)

    return {
        "questions": [
            {
                "question_id": "mental_1",
                "dimension": "clareza_mental",
                "text": "Hoje, consigo organizar meus pensamentos com clareza?",
                "scale_min": 0,
                "scale_max": 10,
            },
            {
                "question_id": "emocional_1",
                "dimension": "estado_emocional",
                "text": "Hoje, consigo reconhecer meu estado emocional sem me julgar?",
                "scale_min": 0,
                "scale_max": 10,
            },
            {
                "question_id": "proposito_1",
                "dimension": "proposito_pessoal",
                "text": "Hoje, sinto que minhas ações têm algum sentido para mim?",
                "scale_min": 0,
                "scale_max": 10,
            },
            {
                "question_id": "energia_1",
                "dimension": "energia_diaria",
                "text": "Hoje, tenho energia suficiente para lidar com minha rotina?",
                "scale_min": 0,
                "scale_max": 10,
            },
            {
                "question_id": "corpo_1",
                "dimension": "corpo_habitos",
                "text": "Hoje, cuidei minimamente do meu corpo, sono, água ou movimento?",
                "scale_min": 0,
                "scale_max": 10,
            },
            {
                "question_id": "comunicacao_1",
                "dimension": "comunicacao",
                "text": "Hoje, consigo me expressar com clareza e respeito?",
                "scale_min": 0,
                "scale_max": 10,
            },
            {
                "question_id": "relacoes_1",
                "dimension": "relacoes",
                "text": "Hoje, minhas relações contribuem para meu equilíbrio?",
                "scale_min": 0,
                "scale_max": 10,
            },
            {
                "question_id": "rotina_1",
                "dimension": "rotina_foco",
                "text": "Hoje, consigo manter foco em pelo menos uma prioridade?",
                "scale_min": 0,
                "scale_max": 10,
            },
            {
                "question_id": "financeiro_1",
                "dimension": "seguranca_financeira",
                "text": "Hoje, sinto que minha vida prática e financeira está minimamente organizada?",
                "scale_min": 0,
                "scale_max": 10,
            },
        ]
    }


@app.post("/assessment", response_model=AssessmentResponse)
def create_assessment(
    payload: AssessmentRequest,
    user: Dict[str, Any] = Depends(get_current_user),
):
    require_active_subscription(user)

    if len(payload.answers) < 9:
        raise HTTPException(
            status_code=400,
            detail="Envie pelo menos uma resposta para cada uma das 9 dimensões."
        )

    dimensions = calculate_assessment(payload.answers)
    general_score = round(sum(item.score for item in dimensions) / len(dimensions) * 10)

    assessment_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()

    dimensions_payload = [item.model_dump() for item in dimensions]

    conn = get_connection()
    conn.execute(
        """
        INSERT INTO assessments (
            id,
            user_id,
            general_score,
            dimensions_json,
            created_at
        ) VALUES (?, ?, ?, ?, ?)
        """,
        (
            assessment_id,
            user["id"],
            general_score,
            json.dumps(dimensions_payload, ensure_ascii=False),
            now,
        )
    )
    conn.commit()
    conn.close()

    return AssessmentResponse(
        assessment_id=assessment_id,
        general_score=general_score,
        dimensions=dimensions,
        created_at=now,
    )


@app.post("/recommendations", response_model=RecommendationResponse)
async def create_recommendation(
    payload: RecommendationRequest,
    user: Dict[str, Any] = Depends(get_current_user),
):
    require_active_subscription(user)

    conn = get_connection()
    row = conn.execute(
        "SELECT * FROM assessments WHERE id = ? AND user_id = ?",
        (payload.assessment_id, user["id"])
    ).fetchone()

    if not row:
        conn.close()
        raise HTTPException(status_code=404, detail="Avaliação não encontrada.")

    assessment = dict(row)
    assessment["dimensions"] = json.loads(assessment["dimensions_json"])

    generated = generate_recommendations(assessment)
    quote = await get_external_quote()

    recommendation_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()

    safety_note = (
        "Este app oferece orientações gerais de bem-estar e autoconhecimento. "
        "Ele não substitui acompanhamento médico, psicológico, financeiro ou terapêutico."
    )

    conn.execute(
        """
        INSERT INTO recommendations (
            id,
            user_id,
            assessment_id,
            summary,
            main_focus,
            daily_actions_json,
            quote,
            quote_author,
            safety_note,
            created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            recommendation_id,
            user["id"],
            assessment["id"],
            generated["summary"],
            generated["main_focus"],
            json.dumps(generated["daily_actions"], ensure_ascii=False),
            quote["quote"],
            quote["author"],
            safety_note,
            now,
        )
    )

    conn.commit()
    conn.close()

    return RecommendationResponse(
        recommendation_id=recommendation_id,
        assessment_id=assessment["id"],
        summary=generated["summary"],
        main_focus=generated["main_focus"],
        daily_actions=generated["daily_actions"],
        quote=quote["quote"],
        quote_author=quote["author"],
        safety_note=safety_note,
        created_at=now,
    )


@app.get("/history")
def get_history(user: Dict[str, Any] = Depends(get_current_user)):
    require_active_subscription(user)

    conn = get_connection()
    rows = conn.execute(
        """
        SELECT *
        FROM assessments
        WHERE user_id = ?
        ORDER BY created_at DESC
        """,
        (user["id"],)
    ).fetchall()
    conn.close()

    items = []

    for row in rows:
        item = dict(row)
        item["dimensions"] = json.loads(item["dimensions_json"])
        del item["dimensions_json"]
        items.append(item)

    return {
        "items": items
    }


@app.delete("/me", response_model=DeleteAccountResponse)
def delete_me(user: Dict[str, Any] = Depends(get_current_user)):
    conn = get_connection()

    conn.execute(
        "DELETE FROM recommendations WHERE user_id = ?",
        (user["id"],)
    )

    conn.execute(
        "DELETE FROM assessments WHERE user_id = ?",
        (user["id"],)
    )

    conn.execute(
        "DELETE FROM users WHERE id = ?",
        (user["id"],)
    )

    conn.commit()
    conn.close()

    return DeleteAccountResponse(
        deleted=True,
        message="Conta e dados associados removidos."
    )

@app.get("/me/export")
def export_my_data(user: Dict[str, Any] = Depends(get_current_user)):
    conn = get_connection()

    assessment_rows = conn.execute(
        """
        SELECT *
        FROM assessments
        WHERE user_id = ?
        ORDER BY created_at DESC
        """,
        (user["id"],)
    ).fetchall()

    recommendation_rows = conn.execute(
        """
        SELECT *
        FROM recommendations
        WHERE user_id = ?
        ORDER BY created_at DESC
        """,
        (user["id"],)
    ).fetchall()

    conn.close()

    assessments = []

    for row in assessment_rows:
        item = dict(row)
        item["dimensions"] = json.loads(item["dimensions_json"])
        del item["dimensions_json"]
        assessments.append(item)

    recommendations = []

    for row in recommendation_rows:
        item = dict(row)
        item["daily_actions"] = json.loads(item["daily_actions_json"])
        del item["daily_actions_json"]
        recommendations.append(item)

    return {
        "user": {
            "id": user["id"],
            "name": user["name"],
            "email": user["email"],
            "created_at": user["created_at"],
            "subscription_active": bool(user["subscription_active"]),
            "subscription_source": user["subscription_source"],
        },
        "assessments": assessments,
        "recommendations": recommendations,
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "note": "Exportação de dados do usuário para transparência e portabilidade."
    }
def normalize_deep_dimension_key(label: str) -> str:
    value = label.strip().lower()
    replacements = {
        "ç": "c",
        "ã": "a",
        "á": "a",
        "à": "a",
        "â": "a",
        "é": "e",
        "ê": "e",
        "í": "i",
        "ó": "o",
        "ô": "o",
        "õ": "o",
        "ú": "u",
        " ": "_",
        "-": "_",
    }

    for old, new in replacements.items():
        value = value.replace(old, new)

    return f"checkup_{value}"


@app.post("/deep-checkin")
def create_deep_checkin(
    payload: Dict[str, Any],
    user: Dict[str, Any] = Depends(get_current_user),
):
    require_active_subscription(user)

    general_score = int(payload.get("general_score", 0))
    overload_score = int(payload.get("overload_score", 0))
    raw_dimensions = payload.get("dimensions", [])

    if general_score < 0 or general_score > 100:
        raise HTTPException(
            status_code=400,
            detail="Pontuação geral inválida."
        )

    if not isinstance(raw_dimensions, list) or len(raw_dimensions) == 0:
        raise HTTPException(
            status_code=400,
            detail="Dimensões do check-up ausentes."
        )

    dimensions_payload = []

    for item in raw_dimensions:
        label = str(item.get("label", "Dimensão"))
        raw_score = int(item.get("score", 0))

        if raw_score < 0:
            raw_score = 0

        if raw_score > 100:
            raw_score = 100

        score_0_10 = round(raw_score / 10)

        dimensions_payload.append({
            "dimension": normalize_deep_dimension_key(label),
            "label": label,
            "score": score_0_10,
            "status": status_from_score(score_0_10),
            "source": "checkup_ampliado",
            "raw_score": raw_score,
            "overload_score": overload_score,
        })

    assessment_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()

    conn = get_connection()
    conn.execute(
        """
        INSERT INTO assessments (
            id,
            user_id,
            general_score,
            dimensions_json,
            created_at
        ) VALUES (?, ?, ?, ?, ?)
        """,
        (
            assessment_id,
            user["id"],
            general_score,
            json.dumps(dimensions_payload, ensure_ascii=False),
            now,
        )
    )

    conn.commit()
    conn.close()

    return {
        "assessment_id": assessment_id,
        "general_score": general_score,
        "dimensions": dimensions_payload,
        "created_at": now,
        "source": "checkup_ampliado",
        "message": "Check-up ampliado salvo no histórico."
    }


PATTERN_BANK = [
    {
        "id": "sobrecarga_mental",
        "label": "Sobrecarga mental",
        "area": "Eu interno",
        "group": "Mental e emocional",
        "keywords": ["mental", "clareza", "foco", "sobrecarga", "organização", "rotina"],
        "safe_text": "Suas respostas podem indicar excesso de pensamentos, dificuldade de foco ou necessidade de reduzir estímulos.",
        "reflection": "Hoje, tente escolher menos prioridades e criar uma pausa antes de iniciar tarefas importantes.",
    },
    {
        "id": "baixa_energia",
        "label": "Baixa energia",
        "area": "Eu interno",
        "group": "Corpo e hábitos",
        "keywords": ["energia", "corpo", "hábitos", "sono", "cansaço", "saúde"],
        "safe_text": "Pode haver sinais de desgaste físico, cansaço acumulado ou necessidade de recuperação.",
        "reflection": "Observe sono, hidratação, pausas e ritmo. Pequenas recuperações podem ser mais úteis que cobranças grandes.",
    },
    {
        "id": "desmotivacao",
        "label": "Desmotivação ou estagnação",
        "area": "Eu interno",
        "group": "Propósito e direção",
        "keywords": ["propósito", "sentido", "evolução", "direção", "estagnação"],
        "safe_text": "Pode existir uma percepção de pouca direção, falta de sentido ou dificuldade de perceber avanço.",
        "reflection": "Escolha uma ação pequena que tenha significado real para você hoje.",
    },
    {
        "id": "dificuldade_com_emocoes",
        "label": "Dificuldade de lidar com emoções",
        "area": "Eu interno",
        "group": "Emocional",
        "keywords": ["emocional", "emoções", "tristeza", "frustração", "controle"],
        "safe_text": "Suas respostas podem sugerir emoções mais intensas, oscilação interna ou dificuldade de reorganização emocional.",
        "reflection": "Nomear o que você sente já pode ajudar a reduzir confusão interna.",
    },
    {
        "id": "limites_familiares",
        "label": "Dificuldade de limites",
        "area": "Familiar",
        "group": "Padrões e vínculos",
        "keywords": ["limites", "família", "familiar", "relações", "culpa", "aprovação"],
        "safe_text": "Pode haver sinais de dificuldade para se posicionar, dizer não ou separar suas necessidades das expectativas externas.",
        "reflection": "Observe onde você aceita mais do que gostaria para evitar desconforto ou desaprovação.",
    },
    {
        "id": "necessidade_de_aprovacao",
        "label": "Necessidade de aprovação",
        "area": "Familiar e relações",
        "group": "Pertencimento",
        "keywords": ["aprovação", "rejeição", "pertencimento", "relações", "insegurança"],
        "safe_text": "Pode existir uma tendência a buscar segurança emocional pela validação de outras pessoas.",
        "reflection": "Pergunte-se: estou escolhendo isso por vontade própria ou por medo de desapontar alguém?",
    },
    {
        "id": "isolamento_social",
        "label": "Isolamento ou não pertencimento",
        "area": "Relações",
        "group": "Social",
        "keywords": ["pertencimento", "social", "relações", "conexão", "interações"],
        "safe_text": "Suas respostas podem indicar sensação de distanciamento, isolamento ou dificuldade de conexão.",
        "reflection": "Uma interação simples e segura pode ser suficiente hoje. Não precisa forçar exposição.",
    },
    {
        "id": "interacoes_cansativas",
        "label": "Interações cansativas",
        "area": "Relações",
        "group": "Social",
        "keywords": ["interações", "relações", "comunicação", "cansaço", "vínculos"],
        "safe_text": "Pode haver sinais de desgaste em algumas trocas, conversas ou vínculos.",
        "reflection": "Observe quais interações te deixam mais leve e quais exigem mais limite.",
    },
    {
        "id": "ansiedade_financeira",
        "label": "Ansiedade financeira",
        "area": "Relações externas",
        "group": "Financeiro",
        "keywords": ["financeira", "dinheiro", "segurança", "escassez", "organização"],
        "safe_text": "Pode haver preocupação com dinheiro, sensação de escassez ou dificuldade de organização financeira.",
        "reflection": "Hoje, escolha apenas uma ação prática: anotar um gasto, revisar uma pendência ou evitar uma compra impulsiva.",
    },
    {
        "id": "dificuldade_profissional",
        "label": "Dificuldade de progresso",
        "area": "Relações externas",
        "group": "Profissional",
        "keywords": ["profissional", "trabalho", "progresso", "execução", "foco", "rotina"],
        "safe_text": "Suas respostas podem sugerir falta de direção, procrastinação, excesso de cobrança ou dificuldade de execução.",
        "reflection": "Proteja um bloco curto de foco e escolha uma entrega pequena, clara e possível.",
    },
    {
        "id": "medo_de_errar",
        "label": "Medo de errar",
        "area": "Profissional e interno",
        "group": "Execução",
        "keywords": ["erro", "execução", "cobrança", "foco", "progresso"],
        "safe_text": "Pode existir autocobrança elevada, receio de falhar ou dificuldade de agir sem garantia.",
        "reflection": "Troque perfeição por teste pequeno. O objetivo é avançar, não acertar tudo de primeira.",
    },
    {
        "id": "dependencia_emocional",
        "label": "Dependência emocional",
        "area": "Amoroso e relações",
        "group": "Vínculos afetivos",
        "keywords": ["amoroso", "relações", "abandono", "rejeição", "insegurança", "limites"],
        "safe_text": "Pode haver sinais de busca intensa por segurança no vínculo com outra pessoa.",
        "reflection": "Observe se suas escolhas estão vindo de afeto, medo de perda ou necessidade de confirmação.",
    },
    {
        "id": "medo_de_abandono",
        "label": "Medo de abandono",
        "area": "Amoroso e familiar",
        "group": "Vínculos afetivos",
        "keywords": ["abandono", "rejeição", "amoroso", "familiar", "insegurança", "pertencimento"],
        "safe_text": "Pode existir sensibilidade maior a afastamentos, silêncio ou sinais de rejeição.",
        "reflection": "Antes de reagir, tente separar fato, interpretação e medo.",
    },
    {
        "id": "dificuldade_de_confiar",
        "label": "Dificuldade de confiar",
        "area": "Amoroso e relações",
        "group": "Vínculos afetivos",
        "keywords": ["confiar", "relações", "amoroso", "insegurança", "instáveis"],
        "safe_text": "Suas respostas podem indicar insegurança em vínculos ou dificuldade de se sentir seguro nas relações.",
        "reflection": "Observe se a desconfiança vem de fatos atuais ou de experiências anteriores.",
    },
]


def score_pattern_from_dimensions(pattern: Dict[str, Any], dimensions: list) -> int:
    total = 0

    for dimension in dimensions:
        label = str(dimension.get("label", "")).lower()
        key = str(dimension.get("dimension", "")).lower()
        score = int(dimension.get("score", 0))

        text = f"{label} {key}"

        matched = any(keyword.lower() in text for keyword in pattern["keywords"])

        if matched:
            if score <= 3:
                total += 4
            elif score <= 5:
                total += 3
            elif score <= 7:
                total += 1

        source = str(dimension.get("source", "")).lower()
        raw_score = int(dimension.get("raw_score", score * 10))

        if source == "checkup_ampliado" and matched:
            if raw_score <= 40:
                total += 3
            elif raw_score <= 60:
                total += 1

    return total


@app.get("/patterns/latest")
def get_latest_patterns(user: Dict[str, Any] = Depends(get_current_user)):
    require_active_subscription(user)

    conn = get_connection()
    row = conn.execute(
        """
        SELECT *
        FROM assessments
        WHERE user_id = ?
        ORDER BY created_at DESC
        LIMIT 1
        """,
        (user["id"],)
    ).fetchone()
    conn.close()

    if row is None:
        return {
            "has_data": False,
            "patterns": [],
            "message": "Faça uma avaliação para visualizar padrões percebidos."
        }

    assessment = dict(row)
    dimensions = json.loads(assessment["dimensions_json"])

    scored_patterns = []

    for pattern in PATTERN_BANK:
        score = score_pattern_from_dimensions(pattern, dimensions)

        if score > 0:
            scored_patterns.append({
                "id": pattern["id"],
                "label": pattern["label"],
                "area": pattern["area"],
                "group": pattern["group"],
                "score": score,
                "safe_text": pattern["safe_text"],
                "reflection": pattern["reflection"],
            })

    scored_patterns.sort(key=lambda item: item["score"], reverse=True)

    return {
        "has_data": True,
        "assessment_id": assessment["id"],
        "general_score": assessment["general_score"],
        "created_at": assessment["created_at"],
        "patterns": scored_patterns[:3],
        "disclaimer": "Esses padrões são hipóteses de reflexão baseadas nas suas respostas. Não representam diagnóstico."
    }

@app.get("/patterns/recurring")
def get_recurring_patterns(user: Dict[str, Any] = Depends(get_current_user)):
    require_active_subscription(user)

    conn = get_connection()
    rows = conn.execute(
        """
        SELECT *
        FROM assessments
        WHERE user_id = ?
        ORDER BY created_at DESC
        LIMIT 20
        """,
        (user["id"],)
    ).fetchall()
    conn.close()

    if len(rows) == 0:
        return {
            "has_data": False,
            "patterns": [],
            "message": "Faça algumas avaliações para visualizar padrões recorrentes."
        }

    pattern_map = {}

    for row in rows:
        assessment = dict(row)
        dimensions = json.loads(assessment["dimensions_json"])

        for pattern in PATTERN_BANK:
            score = score_pattern_from_dimensions(pattern, dimensions)

            if score <= 0:
                continue

            pattern_id = pattern["id"]

            if pattern_id not in pattern_map:
                pattern_map[pattern_id] = {
                    "id": pattern_id,
                    "label": pattern["label"],
                    "area": pattern["area"],
                    "group": pattern["group"],
                    "safe_text": pattern["safe_text"],
                    "reflection": pattern["reflection"],
                    "count": 0,
                    "total_score": 0,
                    "max_score": 0,
                }

            pattern_map[pattern_id]["count"] += 1
            pattern_map[pattern_id]["total_score"] += score
            pattern_map[pattern_id]["max_score"] = max(
                pattern_map[pattern_id]["max_score"],
                score
            )

    recurring = list(pattern_map.values())

    for item in recurring:
        item["average_score"] = round(item["total_score"] / item["count"], 1)

    recurring.sort(
        key=lambda item: (item["count"], item["average_score"], item["max_score"]),
        reverse=True
    )

    return {
        "has_data": True,
        "total_assessments": len(rows),
        "patterns": recurring[:5],
        "disclaimer": "Padrões recorrentes são sinais de reflexão baseados nos seus registros. Não representam diagnóstico."
    }

def ensure_assessment_patterns_table():
    conn = get_connection()

    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS assessment_patterns (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            assessment_id TEXT NOT NULL,
            pattern_id TEXT NOT NULL,
            label TEXT NOT NULL,
            area TEXT NOT NULL,
            pattern_group TEXT NOT NULL,
            pattern_score INTEGER NOT NULL,
            safe_text TEXT NOT NULL,
            reflection TEXT NOT NULL,
            created_at TEXT NOT NULL
        )
        """
    )

    conn.commit()
    conn.close()


def detect_patterns_from_dimensions(dimensions: list) -> list:
    detected = []

    for pattern in PATTERN_BANK:
        score = score_pattern_from_dimensions(pattern, dimensions)

        if score <= 0:
            continue

        detected.append({
            "id": pattern["id"],
            "label": pattern["label"],
            "area": pattern["area"],
            "group": pattern["group"],
            "score": score,
            "safe_text": pattern["safe_text"],
            "reflection": pattern["reflection"],
        })

    detected.sort(key=lambda item: item["score"], reverse=True)

    return detected[:5]


def save_patterns_for_assessment(
    user_id: str,
    assessment_id: str,
    dimensions: list,
    created_at: str,
):
    ensure_assessment_patterns_table()

    detected = detect_patterns_from_dimensions(dimensions)

    conn = get_connection()

    conn.execute(
        """
        DELETE FROM assessment_patterns
        WHERE user_id = ? AND assessment_id = ?
        """,
        (user_id, assessment_id)
    )

    for pattern in detected:
        conn.execute(
            """
            INSERT INTO assessment_patterns (
                id,
                user_id,
                assessment_id,
                pattern_id,
                label,
                area,
                pattern_group,
                pattern_score,
                safe_text,
                reflection,
                created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                str(uuid.uuid4()),
                user_id,
                assessment_id,
                pattern["id"],
                pattern["label"],
                pattern["area"],
                pattern["group"],
                pattern["score"],
                pattern["safe_text"],
                pattern["reflection"],
                created_at,
            )
        )

    conn.commit()
    conn.close()

    return detected


@app.post("/patterns/backfill")
def backfill_assessment_patterns(user: Dict[str, Any] = Depends(get_current_user)):
    require_active_subscription(user)
    ensure_assessment_patterns_table()

    conn = get_connection()
    rows = conn.execute(
        """
        SELECT *
        FROM assessments
        WHERE user_id = ?
        ORDER BY created_at DESC
        """,
        (user["id"],)
    ).fetchall()
    conn.close()

    total_assessments = 0
    total_patterns = 0

    for row in rows:
        assessment = dict(row)
        dimensions = json.loads(assessment["dimensions_json"])

        detected = save_patterns_for_assessment(
            user_id=user["id"],
            assessment_id=assessment["id"],
            dimensions=dimensions,
            created_at=assessment["created_at"],
        )

        total_assessments += 1
        total_patterns += len(detected)

    return {
        "message": "Padrões recalculados e salvos com sucesso.",
        "assessments_processed": total_assessments,
        "patterns_saved": total_patterns,
    }


@app.get("/patterns/stored/latest")
def get_latest_stored_patterns(user: Dict[str, Any] = Depends(get_current_user)):
    require_active_subscription(user)
    ensure_assessment_patterns_table()

    conn = get_connection()

    latest = conn.execute(
        """
        SELECT id
        FROM assessments
        WHERE user_id = ?
        ORDER BY created_at DESC
        LIMIT 1
        """,
        (user["id"],)
    ).fetchone()

    if latest is None:
        conn.close()

        return {
            "has_data": False,
            "patterns": [],
            "message": "Faça uma avaliação para visualizar padrões salvos."
        }

    rows = conn.execute(
        """
        SELECT *
        FROM assessment_patterns
        WHERE user_id = ? AND assessment_id = ?
        ORDER BY pattern_score DESC
        """,
        (user["id"], latest["id"])
    ).fetchall()

    conn.close()

    patterns = []

    for row in rows:
        item = dict(row)

        patterns.append({
            "id": item["pattern_id"],
            "label": item["label"],
            "area": item["area"],
            "group": item["pattern_group"],
            "score": item["pattern_score"],
            "safe_text": item["safe_text"],
            "reflection": item["reflection"],
        })

    return {
        "has_data": True,
        "assessment_id": latest["id"],
        "patterns": patterns,
        "disclaimer": "Esses padrões são hipóteses de reflexão baseadas nas suas respostas. Não representam diagnóstico."
    }

@app.get("/history/with-patterns")
def get_history_with_patterns(user: Dict[str, Any] = Depends(get_current_user)):
    require_active_subscription(user)
    ensure_assessment_patterns_table()

    conn = get_connection()

    assessment_rows = conn.execute(
        """
        SELECT *
        FROM assessments
        WHERE user_id = ?
        ORDER BY created_at DESC
        LIMIT 30
        """,
        (user["id"],)
    ).fetchall()

    pattern_rows = conn.execute(
        """
        SELECT *
        FROM assessment_patterns
        WHERE user_id = ?
        ORDER BY pattern_score DESC
        """,
        (user["id"],)
    ).fetchall()

    conn.close()

    patterns_by_assessment = {}

    for row in pattern_rows:
        item = dict(row)
        assessment_id = item["assessment_id"]

        if assessment_id not in patterns_by_assessment:
            patterns_by_assessment[assessment_id] = []

        patterns_by_assessment[assessment_id].append({
            "id": item["pattern_id"],
            "label": item["label"],
            "area": item["area"],
            "group": item["pattern_group"],
            "score": item["pattern_score"],
            "safe_text": item["safe_text"],
            "reflection": item["reflection"],
        })

    items = []

    for row in assessment_rows:
        assessment = dict(row)
        dimensions = json.loads(assessment["dimensions_json"])

        items.append({
            "id": assessment["id"],
            "general_score": assessment["general_score"],
            "dimensions": dimensions,
            "created_at": assessment["created_at"],
            "patterns": patterns_by_assessment.get(assessment["id"], [])[:3],
        })

    return {
        "items": items,
        "disclaimer": "Padrões são hipóteses de reflexão baseadas nas respostas. Não representam diagnóstico."
    }
