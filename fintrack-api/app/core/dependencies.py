from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel

security = HTTPBearer()

class AuthUser(BaseModel):
    id: str
    email: str

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> AuthUser:
    """
    Dependency to extract and validate the JWT Bearer token.
    Replace/wire with your JWT verification library or Supabase auth decoder.
    """
    token = credentials.credentials
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authentication token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Example decoding logic:
    # payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    # return AuthUser(id=payload.get("sub"), email=payload.get("email"))

    return AuthUser(id="demo-user-id", email="user@example.com")
