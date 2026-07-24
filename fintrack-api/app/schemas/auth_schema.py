from pydantic import BaseModel, EmailStr
from typing import Optional

class UserCredentials(BaseModel):
    email: EmailStr
    password: str

class AuthTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: Optional[str] = None

class RegisterResponse(BaseModel):
    message: str
    user_id: str

class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class ConfirmResetCodeRequest(BaseModel):
    email: EmailStr
    code: str
    new_password: str

class ConfirmPasswordRequest(BaseModel):
    password: str

class UpdatePasswordRequest(BaseModel):
    password: str
