"""FinTrack AI Assistant Google ADK Chatbot Agent.

Configures the ADK root agent with Gemini model integration, read-only tools,
and PostgreSQL DatabaseSessionService for agent session memory.
"""

import os
import ssl
from datetime import datetime

from dotenv import load_dotenv
from google.adk.agents import Agent
from google.adk.agents.readonly_context import ReadonlyContext
from google.adk.runners import Runner
from google.adk.sessions import DatabaseSessionService
from google.genai import types

from agents.tools import (
    get_budget_status,
    get_financial_summary,
    get_recent_transactions,
)

load_dotenv()
GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-2.5-flash")


def _instruction(context: ReadonlyContext) -> str:
    """Build system instructions per turn so the agent knows today's date.

    Args:
        context: ReadonlyContext supplied by ADK runtime.

    Returns:
        System prompt string with date context and financial guidance rules.
    """
    today = datetime.now().strftime("%Y-%m-%d")
    return (
        "You are FinTrack's friendly finance assistant. Today's date is "
        f"{today}. Help the user understand their spending, budgets, and "
        "saving habits, and give concise, practical plans and insights.\n\n"
        "You can call tools to read the user's real data: get_financial_summary, "
        "get_recent_transactions, and get_budget_status. Prefer calling a tool "
        "over guessing whenever a question is about the user's actual finances. "
        "When the user says 'this month', use the current month and year from "
        "today's date. Base every number on tool results - never invent figures. "
        "Amounts are in Malaysian Ringgit (RM). If the user has no relevant data, "
        "say so and offer general guidance.\n\n"
        "You offer general financial guidance and education, not professional "
        "financial advice. Do not recommend specific investments, financial "
        "products, or providers. When a question calls for that, give general "
        "information and suggest speaking to a licensed financial professional."
    )


root_agent = Agent(
    name="fintrack_assistant",
    model=GEMINI_MODEL,
    description="A helpful personal-finance assistant for the FinTrack app.",
    instruction=_instruction,
    tools=[
        get_financial_summary,
        get_recent_transactions,
        get_budget_status,
    ],
)

APP_NAME = "fintrack"

# Database connection for ADK session memory persistence
_DATABASE_URL = os.getenv("DATABASE_URL")
if not _DATABASE_URL:
    raise RuntimeError(
        "DATABASE_URL is not set. Add your Supabase Postgres connection string "
        "to fintrack-api/.env."
    )
if "[YOUR-PASSWORD]" in _DATABASE_URL:
    raise RuntimeError(
        "DATABASE_URL contains the '[YOUR-PASSWORD]' placeholder. "
        "Replace it with your actual Supabase database password."
    )

# Force asyncpg driver for async SQLAlchemy pool inside ADK DatabaseSessionService
if _DATABASE_URL.startswith("postgresql://"):
    _DATABASE_URL = _DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://", 1)
elif _DATABASE_URL.startswith("postgres://"):
    _DATABASE_URL = _DATABASE_URL.replace("postgres://", "postgresql+asyncpg://", 1)

# Supabase requires SSL TLS connection
_ssl_ctx = ssl.create_default_context()
_ssl_ctx.check_hostname = False
_ssl_ctx.verify_mode = ssl.CERT_NONE

_session_service = DatabaseSessionService(
    db_url=_DATABASE_URL,
    connect_args={"ssl": _ssl_ctx},
)

_runner = Runner(
    agent=root_agent,
    app_name=APP_NAME,
    session_service=_session_service,
)


async def chat(message: str, user_id: str = "local", session_id: str = "default") -> str:
    """Send one message turn to the ADK agent and return its reply text.

    Args:
        message: User prompt string.
        user_id: Authenticated user ID string.
        session_id: Active session identifier string.

    Returns:
        The assistant's text response.
    """
    session = await _session_service.get_session(
        app_name=APP_NAME, user_id=user_id, session_id=session_id
    )
    if session is None:
        session = await _session_service.create_session(
            app_name=APP_NAME, user_id=user_id, session_id=session_id
        )

    content = types.Content(role="user", parts=[types.Part(text=message)])

    reply = ""
    async for event in _runner.run_async(
        user_id=user_id, session_id=session.id, new_message=content
    ):
        if event.is_final_response() and event.content and event.content.parts:
            reply = "".join(part.text or "" for part in event.content.parts)
    return reply
