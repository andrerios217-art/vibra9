from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import APP_NAME, APP_VERSION, ALLOWED_ORIGINS
from app.core.database import init_db
from app.routers import auth, users, assessment, recommendations, history, patterns, lgpd

app = FastAPI(
    title=APP_NAME,
    version=APP_VERSION,
    description="Backend do Vibra9 - bem-estar emocional e autoconhecimento.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
def on_startup():
    init_db()

@app.get("/", tags=["health"])
def health_check():
    return {"app": APP_NAME, "version": APP_VERSION, "status": "online"}

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(assessment.router)
app.include_router(recommendations.router)
app.include_router(history.router)
app.include_router(patterns.router)
app.include_router(lgpd.router)
