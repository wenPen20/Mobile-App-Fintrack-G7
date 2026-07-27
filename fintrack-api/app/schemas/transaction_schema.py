from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class TransactionBase(BaseModel):
    category_id: str = Field(..., description="UUID of the transaction category")
    type: str = Field(..., description="'income' or 'expense'")
    amount: float = Field(..., gt=0, description="Amount of the transaction, must be positive")
    title: Optional[str] = Field(None, description="Short label for the transaction")
    note: Optional[str] = Field(None, description="Optional note about the transaction")
    transaction_date: datetime = Field(..., description="Timestamp of the transaction")

class TransactionCreate(TransactionBase):
    pass

class TransactionUpdate(BaseModel):
    category_id: Optional[str] = None
    type: Optional[str] = None
    amount: Optional[float] = None
    title: Optional[str] = None
    note: Optional[str] = None
    transaction_date: Optional[datetime] = None

class TransactionResponse(TransactionBase):
    id: str
    user_id: str
    category_name: Optional[str] = None
    category_icon: Optional[str] = None
    category_color_hex: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True
