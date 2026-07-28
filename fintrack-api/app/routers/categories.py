from fastapi import APIRouter, Depends, HTTPException
from typing import List
from app.core.supabase_client import get_supabase
from app.core.dependencies import get_current_user
from app.schemas.category_schema import CategoryCreate, CategoryUpdate, CategoryResponse
from supabase import Client

router = APIRouter()


def _seed_defaults_for_user(user_id: str, db: Client):
    """
    Copy every global template category (user_id IS NULL) into
    user-specific rows. Called once when a user's category count is 0.
    """
    templates = db.table("categories").select("*").is_("user_id", "null").execute()
    if not templates.data:
        return

    rows = []
    for t in templates.data:
        rows.append({
            "user_id": user_id,
            "name": t["name"],
            "icon": t["icon"],
            "color_hex": t["color_hex"],
            "type": t["type"],
            "is_default": True,
        })

    db.table("categories").insert(rows).execute()


@router.get("/", response_model=List[CategoryResponse], summary="Get All Categories")
async def get_categories(
    user=Depends(get_current_user),
    db: Client = Depends(get_supabase),
):
    try:
        result = db.table("categories").select("*").eq("user_id", user.id).execute()

        # First-time user: seed from global defaults then re-fetch
        if not result.data:
            _seed_defaults_for_user(user.id, db)
            result = db.table("categories").select("*").eq("user_id", user.id).execute()

        return result.data
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/", response_model=CategoryResponse, summary="Create a Custom Category")
async def create_category(
    category_data: CategoryCreate,
    user=Depends(get_current_user),
    db: Client = Depends(get_supabase),
):
    try:
        data = category_data.model_dump()
        data["user_id"] = user.id
        data["is_default"] = False

        result = db.table("categories").insert(data).execute()

        if not result.data:
            raise HTTPException(status_code=400, detail="Category creation failed")

        return result.data[0]
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.put("/{category_id}", response_model=CategoryResponse, summary="Update a Category")
async def update_category(
    category_id: str,
    category_data: CategoryUpdate,
    user=Depends(get_current_user),
    db: Client = Depends(get_supabase),
):
    try:
        # Verify ownership
        existing = (
            db.table("categories")
            .select("id")
            .eq("id", category_id)
            .eq("user_id", user.id)
            .execute()
        )
        if not existing.data:
            raise HTTPException(status_code=404, detail="Category not found")

        updates = {k: v for k, v in category_data.model_dump().items() if v is not None}
        if not updates:
            raise HTTPException(status_code=400, detail="No fields to update")

        result = (
            db.table("categories")
            .update(updates)
            .eq("id", category_id)
            .eq("user_id", user.id)
            .execute()
        )

        if not result.data:
            raise HTTPException(status_code=400, detail="Update failed")

        return result.data[0]
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/{category_id}", summary="Delete a Category")
async def delete_category(
    category_id: str,
    user=Depends(get_current_user),
    db: Client = Depends(get_supabase),
):
    try:
        # Verify ownership
        existing = (
            db.table("categories")
            .select("id")
            .eq("id", category_id)
            .eq("user_id", user.id)
            .execute()
        )
        if not existing.data:
            raise HTTPException(status_code=404, detail="Category not found")

        # Guard: reject deletion if category is still used by budgets or transactions
        budget_refs = (
            db.table("budgets")
            .select("id")
            .eq("category_id", category_id)
            .eq("user_id", user.id)
            .execute()
        )
        tx_refs = (
            db.table("transactions")
            .select("id")
            .eq("category_id", category_id)
            .eq("user_id", user.id)
            .execute()
        )

        if budget_refs.data or tx_refs.data:
            raise HTTPException(
                status_code=409,
                detail="This category is still used by existing budgets or transactions. "
                       "Please reassign or delete them first.",
            )

        db.table("categories").delete().eq("id", category_id).eq("user_id", user.id).execute()
        return {"message": "Category deleted successfully"}
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e))
