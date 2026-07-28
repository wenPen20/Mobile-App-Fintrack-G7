import os
import httpx
from fastapi import APIRouter, HTTPException, Depends, status
from dotenv import load_dotenv

from app.schemas.auth_schema import (
    UserCredentials,
    AuthTokenResponse,
    RegisterResponse,
    ForgotPasswordRequest,
    ConfirmResetCodeRequest,
    ConfirmPasswordRequest,
    UpdatePasswordRequest,
)
from app.core.dependencies import get_current_user, AuthUser

# Load env variables from fintrack-api/.env
load_dotenv(".env")
SUPABASE_URL = os.getenv("SUPABASE_URL", "").rstrip('/')
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY", "")

router = APIRouter(prefix="/auth", tags=["Authentication"])

def get_supabase_headers(auth: bool = False):
    headers = {
        "apikey": SUPABASE_SERVICE_KEY,
        "Content-Type": "application/json"
    }
    if auth:
        headers["Authorization"] = f"Bearer {SUPABASE_SERVICE_KEY}"
    return headers

@router.post("/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED)
async def register(credentials: UserCredentials):
    """
    Register a new user with email and password in Supabase.
    """
    try:
        url = f"{SUPABASE_URL}/auth/v1/admin/users"
        headers = get_supabase_headers(auth=True)
        data = {
            "email": credentials.email,
            "password": credentials.password,
            "email_confirm": True  # Auto-confirm user so they can sign in immediately
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.post(url, json=data, headers=headers)
            
        if response.status_code == 200 or response.status_code == 201:
            res_json = response.json()
            return RegisterResponse(
                message="User registered successfully",
                user_id=res_json["id"]
            )
        else:
            res_json = response.json()
            error_msg = res_json.get("msg") or res_json.get("error_description") or "Registration failed"
            raise HTTPException(
                status_code=response.status_code,
                detail=error_msg
            )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.post("/login", response_model=AuthTokenResponse)
async def login(credentials: UserCredentials):
    """
    Authenticate user with Supabase and return JWT access token.
    """
    try:
        url = f"{SUPABASE_URL}/auth/v1/token?grant_type=password"
        headers = get_supabase_headers(auth=False)
        data = {
            "email": credentials.email,
            "password": credentials.password
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.post(url, json=data, headers=headers)
            
        if response.status_code == 200:
            res_json = response.json()
            return AuthTokenResponse(
                access_token=res_json["access_token"],
                token_type="bearer",
                user_id=res_json["user"]["id"]
            )
        else:
            res_json = response.json()
            error_msg = res_json.get("error_description") or res_json.get("msg") or "Invalid email or password"
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=error_msg
            )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )

@router.post("/forgot-password")
async def forgot_password(data: ForgotPasswordRequest):
    """
    Trigger password reset code/link to user email.
    """
    try:
        url = f"{SUPABASE_URL}/auth/v1/recover"
        headers = get_supabase_headers(auth=False)
        payload = {"email": data.email}
        
        async with httpx.AsyncClient() as client:
            response = await client.post(url, json=payload, headers=headers)
            
        if response.status_code == 200:
            return {"message": "Password reset code sent to email"}
        else:
            res_json = response.json()
            error_msg = res_json.get("msg") or "Failed to send reset code"
            raise HTTPException(status_code=response.status_code, detail=error_msg)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.post("/reset-password")
async def reset_password(data: ConfirmResetCodeRequest):
    """
    Verify reset code (OTP) and set new password.
    """
    try:
        # Step 1: Verify OTP code
        verify_url = f"{SUPABASE_URL}/auth/v1/verify"
        headers = get_supabase_headers(auth=False)
        verify_payload = {
            "email": data.email,
            "token": data.code,
            "type": "recovery"
        }
        
        async with httpx.AsyncClient() as client:
            verify_response = await client.post(verify_url, json=verify_payload, headers=headers)
            
        if verify_response.status_code != 200:
            res_json = verify_response.json()
            error_msg = res_json.get("msg") or "Invalid or expired reset code"
            raise HTTPException(status_code=verify_response.status_code, detail=error_msg)
            
        session_json = verify_response.json()
        user_access_token = session_json["access_token"]
        
        # Step 2: Update password using user's access token
        update_url = f"{SUPABASE_URL}/auth/v1/user"
        update_headers = {
            "apikey": SUPABASE_SERVICE_KEY,
            "Authorization": f"Bearer {user_access_token}",
            "Content-Type": "application/json"
        }
        update_payload = {"password": data.new_password}
        
        async with httpx.AsyncClient() as client:
            update_response = await client.put(update_url, json=update_payload, headers=update_headers)
            
        if update_response.status_code == 200:
            return {"message": "Password has been successfully reset"}
        else:
            res_json = update_response.json()
            error_msg = res_json.get("msg") or "Failed to update password"
            raise HTTPException(status_code=update_response.status_code, detail=error_msg)
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.post("/confirm-password")
async def confirm_password(
    data: ConfirmPasswordRequest,
    user: AuthUser = Depends(get_current_user)
):
    """
    Verify current user's password before sensitive operations.
    """
    try:
        url = f"{SUPABASE_URL}/auth/v1/token?grant_type=password"
        headers = get_supabase_headers(auth=False)
        payload = {
            "email": user.email,
            "password": data.password
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.post(url, json=payload, headers=headers)
            
        if response.status_code == 200:
            return {"message": "Password confirmed"}
        else:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect password")
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect password")

@router.post("/update-password")
async def update_password(
    data: UpdatePasswordRequest,
    user: AuthUser = Depends(get_current_user)
):
    """
    Update logged-in user password.
    """
    try:
        url = f"{SUPABASE_URL}/auth/v1/admin/users/{user.id}"
        headers = get_supabase_headers(auth=True)
        payload = {"password": data.password}
        
        async with httpx.AsyncClient() as client:
            response = await client.put(url, json=payload, headers=headers)
            
        if response.status_code == 200:
            return {"message": "Password updated successfully"}
        else:
            res_json = response.json()
            error_msg = res_json.get("msg") or "Failed to update password"
            raise HTTPException(status_code=response.status_code, detail=error_msg)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
