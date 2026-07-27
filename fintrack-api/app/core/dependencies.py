import os
from jose import jwt, JWTError
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
from dotenv import load_dotenv

# Load env variables from fintrack-api/.env
load_dotenv(".env")
JWT_SECRET = os.getenv("JWT_SECRET")

security = HTTPBearer()

class AuthUser(BaseModel):
    id: str
    email: str
    user_metadata: dict = {}

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> AuthUser:
    """
    Extract and validate the JWT Bearer token against Supabase's signature using JWT_SECRET.
    """
    token = credentials.credentials
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authentication token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    try:
        # Supabase JWTs are signed with HS256 and the project JWT secret
        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"], options={"verify_aud": False})
        user_id = payload.get("sub")
        email = payload.get("email") or payload.get("preferred_username") or "user@example.com"
        user_meta = payload.get("user_metadata") or payload.get("raw_user_meta_data") or {}
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token claims",
            )
        return AuthUser(id=user_id, email=email, user_metadata=user_meta)
    except JWTError as e:
        print(f"JWT Verification Warning: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {str(e)}",
        )
