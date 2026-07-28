"""AI chat service layer.

Runs agent turns and mirrors chat turns into the `ai_chat_messages` table
for human-readable UI history retrieval.
"""

from datetime import datetime, timezone
from supabase import Client
from agents.assistant import chat


async def process_chat(message: str, user_id: str, session_id: str, db: Client) -> str:
    """Execute one agent turn and persist message records into ai_chat_messages.

    Args:
        message: The user's input prompt string.
        user_id: The authenticated user's unique identifier.
        session_id: The active chat session identifier.
        db: Supabase client instance.

    Returns:
        The assistant's text response.
    """
    user_ts = datetime.now(timezone.utc)
    reply = await chat(message, user_id=user_id, session_id=session_id)
    assistant_ts = datetime.now(timezone.utc)

    db.table("ai_chat_messages").insert(
        [
            {
                "user_id": user_id,
                "session_id": session_id,
                "role": "user",
                "content": message,
                "created_at": user_ts.isoformat(),
            },
            {
                "user_id": user_id,
                "session_id": session_id,
                "role": "assistant",
                "content": reply,
                "created_at": assistant_ts.isoformat(),
            },
        ]
    ).execute()

    return reply


def get_history(user_id: str, session_id: str, db: Client) -> list[dict]:
    """Retrieve chat history messages for a given user and session, oldest first.

    Args:
        user_id: The authenticated user's unique identifier.
        session_id: The active chat session identifier.
        db: Supabase client instance.

    Returns:
        List of message dictionaries containing role, content, and timestamp.
    """
    result = (
        db.table("ai_chat_messages")
        .select("role, content, created_at")
        .eq("user_id", user_id)
        .eq("session_id", session_id)
        .order("created_at")
        .execute()
    )
    return result.data
