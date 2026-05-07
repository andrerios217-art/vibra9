from fastapi import APIRouter
from typing import Dict

router = APIRouter()

from main import AuthResponse
from main import create_user, authenticate_user


@router.post("/auth/register", response_model=AuthResponse)
async def register(payload: Dict):
    return await create_user(payload)


@router.post("/auth/login", response_model=AuthResponse)
async def login(payload: Dict):
    return await authenticate_user(payload)