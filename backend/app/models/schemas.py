from pydantic import BaseModel, EmailStr, Field
from typing import List, Optional

class RegisterRequest(BaseModel):
    name: str = Field(min_length=2, max_length=80)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    privacy_policy_accepted: bool
    terms_accepted: bool

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class RefreshRequest(BaseModel):
    refresh_token: str

class AuthResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user_id: str
    name: str
    email: str

class MeResponse(BaseModel):
    id: str
    name: str
    email: str
    subscription_status: str
    trial_end: Optional[str] = None
    created_at: str

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
