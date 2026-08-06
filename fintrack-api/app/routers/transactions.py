# FastAPI router for transaction CRUD endpoints.

from fastapi import APIRouter, Depends, Query, HTTPException
from typing import Optional, List
from datetime import datetime
from app.core.dependencies import get_current_user
from app.core.supabase_client import get_supabase
from app.schemas.transaction_schema import TransactionCreate, TransactionResponse, TransactionUpdate

router = APIRouter()

@router.post("/", response_model=TransactionResponse, summary="Create a Transaction")
async def create_transaction(
    transaction_data: TransactionCreate,
    user = Depends(get_current_user),
    db = Depends(get_supabase)
):
    """
    Create a new transaction record for the authenticated user.
    """
    try:
        if db is None:
            raise HTTPException(status_code=503, detail="Database client unavailable")

        data = transaction_data.model_dump()
        data["transaction_date"] = data["transaction_date"].isoformat()
        data["user_id"] = user.id

        result = db.table("transactions").insert(data).execute()
        
        if not result.data:
            raise HTTPException(status_code=400, detail="Transaction insertion failed")
            
        inserted_tx = result.data[0]
        
        cat_result = db.table("categories").select("name").eq("id", inserted_tx["category_id"]).execute()
        if cat_result.data:
            inserted_tx["category_name"] = cat_result.data[0]["name"]
            
        return inserted_tx
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/", response_model=List[TransactionResponse], summary="Get Transactions with Filters")
async def get_transactions(
    month: Optional[int] = Query(None, description="Filter by month (1-12)"),
    year: Optional[int] = Query(None, description="Filter by year (e.g., 2026)"),
    transaction_type: Optional[str] = Query(None, description="Filter by type ('income' or 'expense')"),
    user = Depends(get_current_user),
    db = Depends(get_supabase)
):
    """
    List transactions for the authenticated user, optionally filtered by month, year, and type.
    """
    try:
        if db is None:
            return []

        result = db.table("transactions").select("*, categories(name, icon, color_hex)").eq("user_id", user.id).execute()
        
        transactions = []
        for tx in (result.data or []):
            category_info = tx.pop("categories", None)
            if category_info:
                tx["category_name"] = category_info.get("name")
                tx["category_icon"] = category_info.get("icon")
                tx["category_color_hex"] = category_info.get("color_hex")
            else:
                tx["category_name"] = "Unknown"
                tx["category_icon"] = None
                tx["category_color_hex"] = None
            transactions.append(tx)
            
        if month is not None or year is not None or transaction_type is not None:
            filtered = []
            for tx in transactions:
                tx_date_str = tx["transaction_date"]
                if tx_date_str.endswith("Z"):
                    tx_date_str = tx_date_str.replace("Z", "+00:00")
                tx_date = datetime.fromisoformat(tx_date_str)
                
                if month is not None and tx_date.month != month:
                    continue
                if year is not None and tx_date.year != year:
                    continue
                if transaction_type is not None and tx["type"] != transaction_type:
                    continue
                filtered.append(tx)
            return filtered
            
        return transactions
    except Exception as e:
        return []

@router.put("/{transaction_id}", response_model=TransactionResponse, summary="Update a Transaction")
async def update_transaction(
    transaction_id: str,
    transaction_data: TransactionUpdate,
    user = Depends(get_current_user),
    db = Depends(get_supabase)
):
    """
    Update an existing transaction owned by the authenticated user.
    """
    try:
        if db is None:
            raise HTTPException(status_code=503, detail="Database client unavailable")

        check = db.table("transactions").select("*").eq("id", transaction_id).eq("user_id", user.id).execute()
        if not check.data:
            raise HTTPException(status_code=404, detail="Transaction not found or unauthorized")

        update_data = transaction_data.model_dump(exclude_unset=True)
        if "transaction_date" in update_data:
            update_data["transaction_date"] = update_data["transaction_date"].isoformat()

        if not update_data:
            return check.data[0]

        result = db.table("transactions").update(update_data).eq("id", transaction_id).execute()
        
        if not result.data:
            raise HTTPException(status_code=400, detail="Transaction update failed")
            
        updated_tx = result.data[0]
        
        cat_result = db.table("categories").select("name").eq("id", updated_tx["category_id"]).execute()
        if cat_result.data:
            updated_tx["category_name"] = cat_result.data[0]["name"]
            
        return updated_tx
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.delete("/{transaction_id}", summary="Delete a Transaction")
async def delete_transaction(
    transaction_id: str,
    user = Depends(get_current_user),
    db = Depends(get_supabase)
):
    """
    Delete a transaction owned by the authenticated user.
    """
    try:
        if db is None:
            raise HTTPException(status_code=503, detail="Database client unavailable")

        check = db.table("transactions").select("id").eq("id", transaction_id).eq("user_id", user.id).execute()
        if not check.data:
            raise HTTPException(status_code=404, detail="Transaction not found or unauthorized")

        db.table("transactions").delete().eq("id", transaction_id).execute()
        return {"message": "Transaction deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
