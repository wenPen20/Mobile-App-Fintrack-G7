from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class BudgetBase(BaseModel):
    category_id: str = Field(..., description="UUID of the budget category")
    amount_limit: float = Field(..., ge=0, description="Spending limit, must be non-negative")
    month: int = Field(..., ge=1, le=12, description="Month of the budget (1-12)")
    year: int = Field(..., ge=2000, le=2100, description="Year of the budget")

class BudgetCreate(BudgetBase):
    pass

class BudgetResponse(BudgetBase):
    id: str
    user_id: str
    category_name: Optional[str] = None
    category_icon: Optional[str] = None
    category_color_hex: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True
