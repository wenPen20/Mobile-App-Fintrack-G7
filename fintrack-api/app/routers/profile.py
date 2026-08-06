# FastAPI router for user profile and onboarding endpoints.

from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
import httpx
from app.core.supabase_client import get_supabase, SUPABASE_URL, SUPABASE_KEY
from app.core.dependencies import get_current_user

router = APIRouter()
security = HTTPBearer()

# In-memory profile cache for local development/testing when Supabase table is absent
_user_profiles_cache: dict[str, dict] = {}

class UpdateNameRequest(BaseModel):
    name: str

class UpdateOnboardingRequest(BaseModel):
    name: str | None = None
    onboarding_completed: bool = True
    financial_goal: str | None = None
    monthly_income_target: float | None = None
    income_frequency: str | None = "monthly"
    fixed_expenses: float | None = None
    risk_appetite: str | None = "moderate"

@router.get("/", summary="Get Current User Profile")
async def get_profile(
    user = Depends(get_current_user),
    db = Depends(get_supabase)
):
    """
    Return the authenticated user's profile, merging JWT metadata, in-memory
    cache, and the Supabase profiles table. Supports both onboarding_done and
    onboarding_completed column names for schema flexibility.
    """
    user_id_str = str(user.id)
    cached = _user_profiles_cache.get(user_id_str, {})

    full_name = cached.get("name", "User")
    monthly_income = cached.get("monthly_income", 0.0)
    income_frequency = cached.get("income_frequency", "monthly")
    risk_appetite = cached.get("risk_appetite", "moderate")
    financial_goal = cached.get("financial_goal", "Track Expenses & Save")
    fixed_expenses = cached.get("fixed_expenses", 0.0)
    onboarding_done = cached.get("onboarding_done", False)

    # 1. Check user_metadata attached to JWT user payload
    metadata = getattr(user, "user_metadata", {}) or {}
    if isinstance(metadata, dict):
        if "onboarding_completed" in metadata:
            onboarding_done = bool(metadata["onboarding_completed"])
        elif "onboarding_done" in metadata:
            onboarding_done = bool(metadata["onboarding_done"])
        if metadata.get("full_name"):
            full_name = metadata.get("full_name")

    # 2. Query profiles table in Supabase DB (supports both onboarding_completed and onboarding_done columns)
    if db is not None:
        try:
            res = db.table("profiles").select("*").eq("id", user_id_str).execute()
            if res.data and len(res.data) > 0:
                p = res.data[0]
                if p.get("onboarding_completed") is not None:
                    onboarding_done = bool(p.get("onboarding_completed"))
                elif p.get("onboarding_done") is not None:
                    onboarding_done = bool(p.get("onboarding_done"))
                
                if p.get("full_name"):
                    full_name = p.get("full_name")
                if p.get("monthly_income") is not None:
                    raw_inc = p.get("monthly_income")
                    if isinstance(raw_inc, list):
                        monthly_income = sum(float(x) for x in raw_inc if x is not None)
                    else:
                        monthly_income = float(raw_inc)
                if p.get("fixed_expenses") is not None:
                    raw_exp = p.get("fixed_expenses")
                    if isinstance(raw_exp, list):
                        fixed_expenses = sum(float(x) for x in raw_exp if x is not None)
                    else:
                        fixed_expenses = float(raw_exp)
                if p.get("income_frequency"):
                    income_frequency = p.get("income_frequency")
                if p.get("risk_appetite"):
                    risk_appetite = p.get("risk_appetite")
        except Exception as e:
            # Graceful fallback: profile table may not exist in all environments.
            print(f"Supabase profiles query fallback: {e}")

    return {
        "email": user.email,
        "name": full_name,
        "onboarding_completed": onboarding_done,
        "onboarding_done": onboarding_done,
        "financial_goal": financial_goal,
        "monthly_income_target": monthly_income,
        "monthly_income": monthly_income,
        "fixed_expenses": fixed_expenses,
        "income_frequency": income_frequency.lower().replace("-", "").replace(" ", "") if income_frequency else "monthly",
        "risk_appetite": risk_appetite.lower() if risk_appetite else "moderate",
    }

@router.put("/update-name", summary="Update User Name")
async def update_name(
    data: UpdateNameRequest,
    user = Depends(get_current_user),
    db = Depends(get_supabase)
):
    """
    Update the authenticated user's display name.
    """
    user_id_str = str(user.id)
    cached = _user_profiles_cache.setdefault(user_id_str, {})
    cached["name"] = data.name

    if db is not None:
        try:
            db.table("profiles").upsert({
                "id": user_id_str,
                "full_name": data.name,
            }).execute()
        except Exception as e:
            print(f"Profiles upsert warning: {e}")

    return {
        "message": "Profile name updated successfully",
        "name": data.name
    }

@router.put("/update-onboarding", summary="Update User Onboarding Data")
async def update_onboarding(
    data: UpdateOnboardingRequest,
    user = Depends(get_current_user),
    db = Depends(get_supabase)
):
    """
    Save onboarding answers (name, income, expenses, risk appetite) to the
    user's profile and mark onboarding as completed.
    """
    user_id_str = str(user.id)
    cached = _user_profiles_cache.setdefault(user_id_str, {})
    cached["onboarding_done"] = data.onboarding_completed
    if data.name:
        cached["name"] = data.name
    if data.monthly_income_target is not None:
        cached["monthly_income"] = data.monthly_income_target

    if db is not None:
        try:
            db_payload = {
                "id": user_id_str,
                "onboarding_done": data.onboarding_completed,
            }
            if data.name:
                db_payload["full_name"] = data.name
            if data.monthly_income_target is not None:
                db_payload["monthly_income"] = data.monthly_income_target
            if data.income_frequency:
                db_payload["income_frequency"] = data.income_frequency.lower().replace("-", "").replace(" ", "")
            if data.fixed_expenses is not None:
                db_payload["fixed_expenses"] = data.fixed_expenses
            if data.risk_appetite:
                db_payload["risk_appetite"] = data.risk_appetite.lower()

            try:
                db.table("profiles").upsert(db_payload).execute()
            except Exception:
                # Fallback for schemas using onboarding_completed column name
                db_payload.pop("onboarding_done", None)
                db_payload["onboarding_completed"] = data.onboarding_completed
                db.table("profiles").upsert(db_payload).execute()
        except Exception as e:
            print(f"Supabase profiles table upsert warning: {e}")

    return {
        "message": "Onboarding data updated successfully",
        "profile": {
            "name": data.name,
            "onboarding_completed": data.onboarding_completed,
            "monthly_income_target": data.monthly_income_target,
        }
    }
