from fastapi import APIRouter, HTTPException, Depends, status
from ..schemas.auth_schema import (
    UserCredentials,
    AuthTokenResponse,
    RegisterResponse,
    ForgotPasswordRequest,
    ConfirmResetCodeRequest,
    ConfirmPasswordRequest,
    UpdatePasswordRequest,
)
from ..core.dependencies import get_current_user, AuthUser

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED)
async def register(credentials: UserCredentials):
    """
    Register a new user with email and password.
    """
    try:
        # Implement user registration logic (e.g. Supabase sign_up or database insert)
        return RegisterResponse(
            message="User registered successfully",
            user_id="user_12345"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.post("/login", response_model=AuthTokenResponse)
async def login(credentials: UserCredentials):
    """
    Authenticate user and return JWT access token.
    """
    try:
        # Implement login verification logic
        return AuthTokenResponse(
            access_token="sample_jwt_access_token_xyz",
            token_type="bearer",
            user_id="user_12345"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )

@router.post("/forgot-password")
async def forgot_password(data: ForgotPasswordRequest):
    """
    Trigger password reset code/link to user email.
    """
    # Send email reset code logic
    return {"message": "Password reset code sent to email"}

@router.post("/reset-password")
async def reset_password(data: ConfirmResetCodeRequest):
    """
    Verify reset code and set new password.
    """
    # Validate code & update password logic
    return {"message": "Password has been successfully reset"}

@router.post("/confirm-password")
async def confirm_password(
    data: ConfirmPasswordRequest,
    user: AuthUser = Depends(get_current_user)
):
    """
    Verify current user's password before sensitive operations.
    """
    return {"message": "Password confirmed"}

@router.post("/update-password")
async def update_password(
    data: UpdatePasswordRequest,
    user: AuthUser = Depends(get_current_user)
):
    """
    Update logged-in user password.
    """
    return {"message": "Password updated successfully"}
