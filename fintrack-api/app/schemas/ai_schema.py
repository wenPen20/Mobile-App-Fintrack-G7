# Pydantic schemas for the AI assistant API endpoints.

from datetime import datetime
from pydantic import BaseModel, Field

# Payload schema for sending a message to the AI assistant.
class ChatRequest(BaseModel):
    message: str = Field(..., description="The user's message to the assistant.")
    session_id: str = Field(
        "default",
        description="Conversation ID for maintaining conversation context across turns.",
    )

# Response schema containing the assistant's reply.
class ChatResponse(BaseModel):
    reply: str = Field(..., description="The assistant's text response.")

# Schema representing a single message in the chat history log.
class ChatMessage(BaseModel):
    role: str = Field(..., description="Message author role: 'user' or 'assistant'.")
    content: str = Field(..., description="Text message content.")
    created_at: datetime = Field(..., description="Timestamp when the message was sent.")
