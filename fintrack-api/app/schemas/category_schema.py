from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class CategoryCreate(BaseModel):
    """Request payload for creating a new custom category."""
    name: str = Field(..., description="Display name of the category")
    icon: str = Field(..., description="Icon identifier string, e.g. 'utensils'")
    color_hex: str = Field(..., description="Hex colour string, e.g. '#D85A30'")
    type: str = Field(..., description="'expense' or 'income'")


class CategoryUpdate(BaseModel):
    """Request payload for partially updating an existing category."""
    name: Optional[str] = Field(None, description="Updated name")
    icon: Optional[str] = Field(None, description="Updated icon identifier")
    color_hex: Optional[str] = Field(None, description="Updated hex colour")


class CategoryResponse(BaseModel):
    """Response model for a category record."""
    id: str
    user_id: Optional[str] = None
    name: str
    icon: str
    color_hex: str
    type: str
    is_default: bool
    created_at: datetime

    class Config:
        from_attributes = True
