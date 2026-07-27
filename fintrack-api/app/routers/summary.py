from fastapi import APIRouter, Depends, Query, HTTPException
from datetime import datetime
from app.core.supabase_client import get_supabase
from app.core.dependencies import get_current_user
from supabase import Client

router = APIRouter()

@router.get("/", summary="Get Financial Summary")
async def get_summary(
    month: int = Query(..., description="Month for summary (1-12)"),
    year: int = Query(..., description="Year for summary (e.g., 2026)"),
    user = Depends(get_current_user),
    db: Client = Depends(get_supabase)
):
    try:
        # Fetch all transactions for this user, joining category name
        result = db.table("transactions").select("*, categories(name)").eq("user_id", user.id).execute()
        
        total_income = 0.0
        total_expenses = 0.0
        per_category_breakdown = {}
        
        for tx in (result.data or []):
            tx_date_str = tx["transaction_date"]
            if tx_date_str.endswith("Z"):
                tx_date_str = tx_date_str.replace("Z", "+00:00")
            tx_date = datetime.fromisoformat(tx_date_str)
            
            if tx_date.month == month and tx_date.year == year:
                amount = float(tx["amount"])
                category_info = tx.get("categories")
                category_name = category_info.get("name") if category_info else "Unknown"
                
                if tx["type"] == "income":
                    total_income += amount
                elif tx["type"] == "expense":
                    total_expenses += amount
                    per_category_breakdown[category_name] = per_category_breakdown.get(category_name, 0.0) + amount
                    
        return {
            "period": f"{month}/{year}",
            "total_income": total_income,
            "total_expenses": total_expenses,
            "net": total_income - total_expenses,
            "per_category_breakdown": per_category_breakdown
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
