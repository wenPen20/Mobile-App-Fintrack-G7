# FinTrack API

FastAPI backend for FinTrack. It fronts Supabase (auth and PostgreSQL) and runs the Gemini-powered assistant through Google ADK. The Flutter client talks only to this service.

> **Setting up for the first time? Read the [root README](../README.md).** It covers prerequisites, the Supabase schema, the `.env` values, and how to point the Flutter client at this server. This page covers API-specific details only.

## Quick start

Run everything from this directory.

```bash
cd fintrack-api

# 1. Virtual environment
python -m venv .venv

# 2. Activate it
.\.venv\Scripts\Activate.ps1     # PowerShell
# .\.venv\Scripts\activate.bat   # Command Prompt
# source .venv/bin/activate      # macOS / Linux
# source .venv/Scripts/activate  # Git Bash

# 3. Dependencies
pip install -r requirements.txt

# 4. Secrets
copy .env.example .env           # cp on macOS / Linux, then fill it in

# 5. Run
uvicorn app.main:app --reload
```

Then check http://localhost:8000 and http://localhost:8000/docs.

If PowerShell blocks activation with "running scripts is disabled on this system", run `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` and try again.

**Always start Uvicorn from `fintrack-api`.** `load_dotenv(".env")` resolves relative to the working directory, and the `app` and `agents` packages are imported relative to it too.

Add `--host 0.0.0.0` if a physical device needs to reach the server over your LAN.

## Environment variables

All six live in `fintrack-api/.env`, which is gitignored. See the root README for exactly where each value comes from in the Supabase and Google AI Studio dashboards.

| Variable | Required | Notes |
|---|---|---|
| `SUPABASE_URL` | Yes | Project URL |
| `SUPABASE_SERVICE_KEY` | Yes | `service_role` key, not `anon`. Secret |
| `JWT_SECRET` | Yes | Verifies HS256 tokens issued by Supabase Auth |
| `GEMINI_API_KEY` | Yes for AI chat | Read from the environment by the Google GenAI SDK |
| `DATABASE_URL` | Yes | Postgres URI for ADK session memory. The server refuses to start without it |
| `GEMINI_MODEL` | No | Defaults to `gemini-2.5-flash` |

`DATABASE_URL` is validated at import time in [agents/assistant.py](agents/assistant.py), and the AI router is imported by `app.main`. A missing or placeholder value therefore stops the whole API from starting, not just the chat endpoints.

## Layout

```
app/
├── main.py                   App instance, CORS, router registration
├── core/
│   ├── dependencies.py       get_current_user, JWT decoding
│   └── supabase_client.py    get_supabase dependency
├── routers/                  auth, profile, transactions, budgets,
│                             categories, summary, ai
├── schemas/                  Pydantic request and response models
└── services/
    └── ai_service.py         Runs an agent turn, mirrors both messages
                              into ai_chat_messages for UI history
agents/
├── assistant.py              ADK agent, system prompt, Gemini model,
│                             DatabaseSessionService for agent memory
└── tools.py                  Read-only tools: get_financial_summary,
                              get_recent_transactions, get_budget_status
```

## Conventions

- Every route except `/` and `/auth/*` depends on `get_current_user`, which returns the caller's Supabase user ID from the bearer token.
- Every Supabase query filters on that `user_id`. The service key bypasses Row Level Security, so this application-level scoping is what isolates user data.
- Agent tools are read-only by design. The assistant can inspect finances but cannot create, update, or delete records.
- The endpoint table is in the root README, and the live reference is at `/docs`.

## Testing

There is no automated backend test suite. Endpoints are exercised manually through the Swagger UI at `/docs`. Manual test cases for the AI chat feature are in `docs/test-cases-ai-chat.md` at the repository root.
