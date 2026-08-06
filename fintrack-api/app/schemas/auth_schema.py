from pydantic import BaseModel, EmailStr
from typing import Optional

class UserCredentials(BaseModel):
    """Email and password payload for login and registration."""
    email: EmailStr
    password: str

class AuthTokenResponse(BaseModel):
    """JWT access token returned after successful authentication."""
    access_token: str
    token_type: str = "bearer"
    user_id: Optional[str] = None

class RegisterResponse(BaseModel):
    """Confirmation response after successful user registration."""
    message: str
    user_id: str

class ForgotPasswordRequest(BaseModel):
    """Payload for requesting a password reset email."""
    email: EmailStr

class ConfirmResetCodeRequest(BaseModel):
    """Payload for verifying a reset code and setting a new password."""
    email: EmailStr
    code: str
    new_password: str

class ConfirmPasswordRequest(BaseModel):
    """Payload for re-confirming the current password before sensitive operations."""
    password: str

class UpdatePasswordRequest(BaseModel):
    """Payload for setting a new password."""
    password: str
