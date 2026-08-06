from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class TransactionBase(BaseModel):
    """Shared fields for transaction create and response models."""
    category_id: str = Field(..., description="UUID of the transaction category")
    type: str = Field(..., description="'income' or 'expense'")
    amount: float = Field(..., gt=0, description="Amount of the transaction, must be positive")
    title: Optional[str] = Field(None, description="Short label for the transaction")
    note: Optional[str] = Field(None, description="Optional note about the transaction")
    transaction_date: datetime = Field(..., description="Timestamp of the transaction")

class TransactionCreate(TransactionBase):
    """Request payload for creating a new transaction."""
    pass

class TransactionUpdate(BaseModel):
    """Request payload for partially updating an existing transaction."""
    category_id: Optional[str] = None
    type: Optional[str] = None
    amount: Optional[float] = None
    title: Optional[str] = None
    note: Optional[str] = None
    transaction_date: Optional[datetime] = None

class TransactionResponse(TransactionBase):
    """Response model for a transaction record with joined category info."""
    id: str
    user_id: str
    category_name: Optional[str] = None
    category_icon: Optional[str] = None
    category_color_hex: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True
