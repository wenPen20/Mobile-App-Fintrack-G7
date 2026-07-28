# FastAPI router for AI assistant endpoints.

from fastapi import APIRouter, Depends, HTTPException, Query
from supabase import Client

from app.core.dependencies import get_current_user
from app.core.supabase_client import get_supabase
from app.schemas.ai_schema import ChatMessage, ChatRequest, ChatResponse
from app.services.ai_service import get_history, process_chat

router = APIRouter()

# Send a message turn to the ADK agent and return its response.
# The conversation context is scoped by the authenticated user's ID.
@router.post("/chat", response_model=ChatResponse, summary="Chat with the FinTrack assistant")
async def chat_endpoint(
    payload: ChatRequest,
    user=Depends(get_current_user),
    db: Client = Depends(get_supabase),
):
    try:
        reply = await process_chat(payload.message, str(user.id), payload.session_id, db)
        return ChatResponse(reply=reply)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Retrieve history log messages for a given user session, oldest first.
@router.get("/history", response_model=list[ChatMessage], summary="Get chat history")
async def history_endpoint(
    session_id: str = Query("default", description="Which conversation session to load."),
    user=Depends(get_current_user),
    db: Client = Depends(get_supabase),
):
    try:
        return get_history(str(user.id), session_id, db)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
