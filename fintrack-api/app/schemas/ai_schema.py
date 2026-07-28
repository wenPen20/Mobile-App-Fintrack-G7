"""Pydantic schemas for the AI assistant API endpoints."""

from datetime import datetime
from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    """Payload schema for sending a message to the AI assistant."""

    message: str = Field(..., description="The user's message to the assistant.")
    session_id: str = Field(
        "default",
        description="Conversation ID for maintaining conversation context across turns.",
    )


class ChatResponse(BaseModel):
    """Response schema containing the assistant's reply."""

    reply: str = Field(..., description="The assistant's text response.")


class ChatMessage(BaseModel):
    """Schema representing a single message in the chat history log."""

    role: str = Field(..., description="Message author role: 'user' or 'assistant'.")
    content: str = Field(..., description="Text message content.")
    created_at: datetime = Field(..., description="Timestamp when the message was sent.")
