# FastAPI router for budget management endpoints.

from fastapi import APIRouter, Depends, Query, HTTPException
from typing import Optional, List
from app.core.supabase_client import get_supabase
from app.core.dependencies import get_current_user
from app.schemas.budget_schema import BudgetCreate, BudgetResponse

router = APIRouter()

@router.post("/", response_model=BudgetResponse, summary="Create or Update a Budget")
async def create_budget(
    budget_data: BudgetCreate,
    user = Depends(get_current_user),
    db = Depends(get_supabase)
):
    """
    Create or update (upsert) a budget for a specific category and month.
    """
    try:
        if db is None:
            raise HTTPException(status_code=503, detail="Database client unavailable")

        data = budget_data.model_dump()
        data["user_id"] = user.id

        result = db.table("budgets").upsert(data, on_conflict="user_id,category_id,month,year").execute()
        
        if not result.data:
            raise HTTPException(status_code=400, detail="Budget configuration failed")
            
        inserted_budget = result.data[0]
        
        cat_result = db.table("categories").select("name").eq("id", inserted_budget["category_id"]).execute()
        if cat_result.data:
            inserted_budget["category_name"] = cat_result.data[0]["name"]
            
        return inserted_budget
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/", response_model=List[BudgetResponse], summary="Get All Budgets with Filters")
async def get_budgets(
    month: Optional[int] = Query(None, description="Filter by month (1-12)"),
    year: Optional[int] = Query(None, description="Filter by year (e.g., 2026)"),
    user = Depends(get_current_user),
    db = Depends(get_supabase)
):
    """
    List budgets for the authenticated user, optionally filtered by month and year.
    """
    try:
        if db is None:
            return []

        query = db.table("budgets").select("*, categories(name, icon, color_hex)").eq("user_id", user.id)
        
        if month is not None:
            query = query.eq("month", month)
        if year is not None:
            query = query.eq("year", year)
            
        result = query.execute()
        
        budgets = []
        for b in (result.data or []):
            category_info = b.pop("categories", None)
            if category_info:
                b["category_name"] = category_info.get("name")
                b["category_icon"] = category_info.get("icon")
                b["category_color_hex"] = category_info.get("color_hex")
            else:
                b["category_name"] = "Unknown"
                b["category_icon"] = None
                b["category_color_hex"] = None
            budgets.append(b)
            
        return budgets
    except Exception as e:
        return []
