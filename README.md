# FinTrack

A personal finance tracker built as a Flutter mobile client backed by a FastAPI service, a Supabase (PostgreSQL) database, and a Gemini-powered AI financial assistant.

This README covers everything needed to set up and run the project. The READMEs inside `fintrack-api/` and `fintrack-mobile/` only cover details specific to each half.

---

## Table of contents

1. [What you are setting up](#1-what-you-are-setting-up)
2. [Prerequisites](#2-prerequisites)
3. [Get the code](#3-get-the-code)
4. [Set up the database](#4-set-up-the-database)
5. [Set up the backend](#5-set-up-the-backend)
6. [Run the backend](#6-run-the-backend)
7. [Set up the Flutter client](#7-set-up-the-flutter-client)
8. [Run the Flutter client](#8-run-the-flutter-client)
9. [First run through the app](#9-first-run-through-the-app)
10. [Running the tests](#10-running-the-tests)
11. [Troubleshooting](#11-troubleshooting)
12. [Project structure](#12-project-structure)
13. [API reference](#13-api-reference)
14. [Known gotchas](#14-known-gotchas)

---

## 1. What you are setting up

There are three pieces, and all three must be working before the app is usable.

```
┌──────────────────┐        HTTP + JWT        ┌──────────────────┐
│  Flutter client  │ ───────────────────────► │   FastAPI API    │
│ (fintrack-mobile)│ ◄─────────────────────── │  (fintrack-api)  │
└──────────────────┘                          └────────┬─────────┘
                                                       │
                                        Supabase REST  │  asyncpg
                                        + Auth admin   │  (AI session memory)
                                                       ▼
                                              ┌──────────────────┐
                                              │  Supabase        │
                                              │  (PostgreSQL)    │
                                              └──────────────────┘
                                                       ▲
                                              Gemini   │
                                              via      │
                                              Google ADK
```

The Flutter app never talks to Supabase or Gemini directly. Every request goes through the FastAPI server, which holds the service key and the Gemini key. If the backend is not running, the app will fail at the login screen.

**Feature modules:** Onboarding and financial profile, Dashboard, Transactions, Budgets, and the AI Financial Assistant.

---

## 2. Prerequisites

The following tools are required. Versions listed are those the project was developed and tested against.

| Tool | Version | Check with | Notes |
|---|---|---|---|
| Python | 3.13.2 (3.11 or newer works) | `python --version` | On Windows, tick "Add Python to PATH" during install |
| Flutter SDK | 3.41.9 stable (Dart 3.11.5) | `flutter --version` | `pubspec.yaml` requires Dart `^3.11.5`, so older Flutter versions will not resolve |
| Git | any recent | `git --version` | |
| Android Studio | any recent | | Only if you want to run on an Android emulator |
| Chrome | any recent | | Easiest target for a first run, needs no emulator |

You also need two accounts:

- A **Supabase** project. Free tier is fine. https://supabase.com
- A **Google Gemini API key** from Google AI Studio. Free tier is fine. https://aistudio.google.com/apikey

Then run `flutter doctor` and resolve anything it reports as an error for the platform you intend to run on. Warnings about platforms you are not using can be ignored.

> If working with an existing Supabase project, use the provided `.env` values and project invite instead of creating a new one. That skips [section 4](#4-set-up-the-database) entirely.

---

## 3. Get the code

```bash
git clone https://github.com/wenPen20/Mobile-App-Fintrack-G7.git
cd Mobile-App-Fintrack-G7
```

You should see two folders, `fintrack-api` and `fintrack-mobile`. Every command in this README is written relative to the repository root, and each section tells you which folder to be in.

---

## 4. Set up the database

Skip this section if you were given access to the team's existing Supabase project.

The repository does not contain a migration script, so the schema below was reconstructed from what the API code reads and writes. Create a new Supabase project, open the **SQL Editor**, and run the following.

### 4.1 Tables

```sql
-- User profile, one row per auth user
create table if not exists public.profiles (
  id               uuid primary key references auth.users (id) on delete cascade,
  full_name        text,
  onboarding_done  boolean default false,
  monthly_income   numeric,
  fixed_expenses   numeric,
  income_frequency text,
  risk_appetite    text,
  created_at       timestamptz default now()
);

-- Categories. A row with user_id IS NULL is a global template.
-- Templates are copied into per-user rows the first time a user loads categories.
create table if not exists public.categories (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references auth.users (id) on delete cascade,
  name       text not null,
  icon       text not null,
  color_hex  text not null,
  type       text not null check (type in ('income', 'expense')),
  is_default boolean default false,
  created_at timestamptz default now()
);

create table if not exists public.transactions (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references auth.users (id) on delete cascade,
  category_id      uuid not null references public.categories (id),
  type             text not null check (type in ('income', 'expense')),
  amount           numeric not null check (amount > 0),
  title            text,
  note             text,
  transaction_date timestamptz not null,
  created_at       timestamptz default now()
);

create table if not exists public.budgets (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users (id) on delete cascade,
  category_id  uuid not null references public.categories (id),
  amount_limit numeric not null check (amount_limit >= 0),
  month        int not null check (month between 1 and 12),
  year         int not null,
  created_at   timestamptz default now(),
  -- required: the API upserts budgets on this exact conflict target
  unique (user_id, category_id, month, year)
);

create table if not exists public.ai_chat_messages (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  session_id text not null default 'default',
  role       text not null check (role in ('user', 'assistant')),
  content    text not null,
  created_at timestamptz default now()
);
```

The unique constraint on `budgets` is not optional. `POST /budgets/` upserts with `on_conflict="user_id,category_id,month,year"` and will fail without it.

### 4.2 Seed the default categories

New users are given a copy of every category whose `user_id` is `NULL`. If you skip this step, a freshly registered user gets an empty category list and cannot record a transaction.

These are the fourteen categories the Flutter client has icon mappings for, in [category_visuals.dart](fintrack-mobile/lib/core/constants/category_visuals.dart). The `icon` strings must match exactly. The colours below are placeholders, so adjust them to taste.

```sql
insert into public.categories (user_id, name, icon, color_hex, type, is_default) values
  (null, 'Salary',          'briefcase',       '#22C55E', 'income',  true),
  (null, 'Freelance',       'laptop',          '#10B981', 'income',  true),
  (null, 'Investment',      'trending-up',     '#0EA5E9', 'income',  true),
  (null, 'Business',        'store',           '#6366F1', 'income',  true),
  (null, 'Other Income',    'plus-circle',     '#84CC16', 'income',  true),
  (null, 'Food & Drinks',   'utensils',        '#D85A30', 'expense', true),
  (null, 'Transport',       'car',             '#F59E0B', 'expense', true),
  (null, 'Shopping',        'shopping-bag',    '#EC4899', 'expense', true),
  (null, 'Bills',           'file-text',       '#64748B', 'expense', true),
  (null, 'Entertainment',   'film',            '#8B5CF6', 'expense', true),
  (null, 'Health',          'heart',           '#EF4444', 'expense', true),
  (null, 'Education',       'book',            '#3B82F6', 'expense', true),
  (null, 'Travel',          'map-pin',         '#14B8A6', 'expense', true),
  (null, 'Other Expense',   'more-horizontal', '#94A3B8', 'expense', true);
```

An icon name that is not in that list will not crash the app, it just renders a generic fallback icon.

### 4.3 A note on Row Level Security

The backend connects with the Supabase **service role key**, which bypasses Row Level Security. Per-user data isolation is enforced in application code, where every query filters on the `user_id` taken from the verified JWT. You can leave RLS enabled on these tables, and the API will still work, but do not rely on RLS as the only defence.

### 4.4 AI session tables

You do not create these. The Google ADK `DatabaseSessionService` connects over `DATABASE_URL` and creates its own session and event tables automatically the first time the backend starts. `ai_chat_messages` is separate from those, and exists so the chat screen can render readable history.

---

## 5. Set up the backend

All commands in this section run from `fintrack-api`.

```bash
cd fintrack-api
```

### 5.1 Create a virtual environment

```bash
python -m venv .venv
```

This creates an isolated Python environment inside `fintrack-api/.venv`, so the project's packages do not collide with anything else on your machine. It is gitignored.

### 5.2 Activate it

You have to do this in **every new terminal** you use for the backend. Your prompt shows `(.venv)` once it works.

| Shell | Command |
|---|---|
| PowerShell (Windows default) | `.\.venv\Scripts\Activate.ps1` |
| Command Prompt (Windows) | `.\.venv\Scripts\activate.bat` |
| Git Bash (Windows) | `source .venv/Scripts/activate` |
| macOS / Linux | `source .venv/bin/activate` |

If PowerShell refuses with *"running scripts is disabled on this system"*, allow scripts for that one terminal session only:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Then run the activate command again. To leave the environment later, type `deactivate`.

### 5.3 Install the dependencies

```bash
pip install -r requirements.txt
```

This pulls in FastAPI and Uvicorn for the web server, the Supabase Python client, `python-jose` for JWT verification, `google-adk` for the AI agent runtime, and `asyncpg` for the agent's PostgreSQL session store. Expect it to take a couple of minutes on a first install.

### 5.4 Create the `.env` file

`.env` holds every secret and is gitignored, so a fresh clone will not have one. Copy the template:

```bash
# PowerShell / Command Prompt
copy .env.example .env

# Git Bash / macOS / Linux
cp .env.example .env
```

Then open `fintrack-api/.env` and fill in all six values.

| Variable | Where to find it | Required |
|---|---|---|
| `SUPABASE_URL` | Supabase dashboard → Project Settings → Data API → Project URL. Looks like `https://abcdefgh.supabase.co` | Yes |
| `SUPABASE_SERVICE_KEY` | Supabase dashboard → Project Settings → API Keys → `service_role` key. **Secret. Never commit it or put it in the Flutter app.** | Yes |
| `JWT_SECRET` | Supabase dashboard → Project Settings → JWT Keys → JWT Secret. The API uses it to verify HS256 tokens from Supabase Auth | Yes |
| `GEMINI_API_KEY` | Google AI Studio → Get API key. Read from the environment by the Google GenAI SDK | Yes, for the AI chat |
| `DATABASE_URL` | Supabase dashboard → Connect → Connection string → URI. Replace `[YOUR-PASSWORD]` with your actual database password | Yes, the server will not start without it |
| `GEMINI_MODEL` | The model name, for example `gemini-2.5-flash`. Defaults to `gemini-2.5-flash` if left blank | No |

A filled file looks like this:

```env
SUPABASE_URL=https://abcdefghijkl.supabase.co
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
JWT_SECRET=super-long-random-string-from-supabase
GEMINI_API_KEY=AIzaSy...
DATABASE_URL=postgresql://postgres:your-db-password@db.abcdefghijkl.supabase.co:5432/postgres
GEMINI_MODEL=gemini-2.5-flash
```

Two things that catch people out:

- `DATABASE_URL` is read when the module is imported, not when the AI endpoint is first called. If it is missing, or if you left `[YOUR-PASSWORD]` in place, the server raises a `RuntimeError` and refuses to start at all, even for endpoints that have nothing to do with the AI feature.
- Do not wrap values in quotes and do not leave trailing spaces.

---

## 6. Run the backend

From `fintrack-api`, with the virtual environment active:

```bash
uvicorn app.main:app --reload
```

**Run it from `fintrack-api`, not from the repository root.** The code calls `load_dotenv(".env")` with a relative path, and the `app` and `agents` packages are both resolved relative to the working directory. Starting it from anywhere else produces missing-configuration or import errors.

You should see:

```
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
INFO:     Application startup complete.
```

Verify it before you touch Flutter:

- http://localhost:8000 returns `{"message":"Welcome to FinTrack API"}`
- http://localhost:8000/docs is the interactive Swagger UI, where you can try every endpoint

`--reload` restarts the server whenever a Python file is saved. Keep this terminal running and open a separate terminal for the Flutter client.

---

## 7. Set up the Flutter client

All commands in this section run from `fintrack-mobile`.

```bash
cd fintrack-mobile
flutter pub get
```

### 7.1 Point the app at the backend

This is the most commonly missed step. The API base URL is currently hardcoded in **two** places, and both must match:

- [lib/core/services/api_service.dart:338](fintrack-mobile/lib/core/services/api_service.dart#L338)
- [lib/features/auth/providers/auth_provider.dart:37](fintrack-mobile/lib/features/auth/providers/auth_provider.dart#L37)

Both read `http://localhost:8000`. Which value is correct depends entirely on where the app is running, because `localhost` means "this device", and on an emulator or a phone that is not your computer.

| Run target | Use this base URL | Why |
|---|---|---|
| Chrome, Windows desktop, iOS simulator | `http://localhost:8000` | Shares the host machine's network stack |
| Android emulator | `http://10.0.2.2:8000` | `10.0.2.2` is the emulator's alias for the host machine's loopback |
| Physical phone on the same Wi-Fi | `http://<your-computer-LAN-IP>:8000` | Find it with `ipconfig` on Windows or `ifconfig` on macOS. The phone and computer must be on the same network |

If you use a physical device or another machine on the network, also start the backend so it listens beyond loopback:

```bash
uvicorn app.main:app --reload --host 0.0.0.0
```

You may need to allow Python through the Windows Firewall the first time.

---

## 8. Run the Flutter client

Check what you can run on:

```bash
flutter devices
```

Then pick a target:

```bash
# Chrome, the quickest way to see the app working
flutter run -d chrome

# Windows desktop
flutter run -d windows

# Android emulator (start it from Android Studio first, then)
flutter run
```

While it is running, press `r` for hot reload, `R` for hot restart, and `q` to quit.

The app wraps itself in `DevicePreview` in debug builds ([lib/main.dart](fintrack-mobile/lib/main.dart)), so on desktop and web you will see the UI rendered inside a phone frame. That is intentional, not a layout bug.

---

## 9. First run through the app

With the backend running and the base URL set correctly:

1. **Register.** The API creates the user through Supabase's admin endpoint with `email_confirm: true`, so no confirmation email is needed and you can sign in immediately.
2. **Log in.** You get a Supabase JWT back, which the client stores and sends as `Authorization: Bearer <token>` on every later request.
3. **Complete onboarding.** Name, monthly income, fixed expenses, income frequency, and risk appetite are written to the `profiles` table.
4. **Land on the dashboard.** It is empty until you add something.
5. **Add a transaction.** The first time the app loads categories, the backend copies the fourteen global template categories into rows owned by the user. If the picker is empty, the seed script from [section 4.2](#42-seed-the-default-categories) was not run.
6. **Open the AI assistant** from the floating button and ask something like "how much did I spend this month?". The agent calls its read-only tools against your real data and answers in Ringgit. Chat history persists per session.

To confirm the data landed, open the Supabase **Table Editor** and look at `transactions` and `ai_chat_messages`.

---

## 10. Running the tests

From `fintrack-mobile`:

```bash
flutter test
```

Static analysis, using the lint rules in `analysis_options.yaml`:

```bash
flutter analyze
```

The backend has no automated test suite. API endpoints are exercised manually through the Swagger UI at http://localhost:8000/docs, and manual test cases for the AI chat feature are recorded in [docs/test-cases-ai-chat.md](docs/test-cases-ai-chat.md).

---

## 11. Troubleshooting

**`RuntimeError: DATABASE_URL is not set` on startup**
The `.env` file is missing, empty, or you started Uvicorn from the wrong directory. `load_dotenv(".env")` resolves relative to your working directory, so you must launch from `fintrack-api`.

**`RuntimeError: DATABASE_URL contains the '[YOUR-PASSWORD]' placeholder`**
You pasted the Supabase connection string without substituting your database password. If you have forgotten it, reset it under Project Settings → Database.

**PowerShell: "running scripts is disabled on this system"**
`Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`, then activate again. The `-Scope Process` part limits the change to that terminal window.

**`uvicorn` is not recognised**
The virtual environment is not active. Look for `(.venv)` in your prompt and redo [section 5.2](#52-activate-it).

**`ModuleNotFoundError: No module named 'app'` or `'agents'`**
You are running Uvicorn from the repository root. `cd fintrack-api` first.

**App shows "Connection refused" / "Failed to host lookup" / a network error on login**
Either the backend is not running, or the base URL is wrong for your target. Re-read [section 7.1](#71-point-the-app-at-the-backend). The Android emulator case, `localhost` instead of `10.0.2.2`, is by far the most common cause.

**Login returns 401 with correct credentials**
`SUPABASE_URL` or `SUPABASE_SERVICE_KEY` is wrong. Confirm you copied the `service_role` key and not the `anon` key.

**Category picker is empty and transactions cannot be saved**
No global template categories exist. Run the seed in [section 4.2](#42-seed-the-default-categories), then reopen the app.

**AI chat returns a 500 mentioning the model name**
`GEMINI_MODEL` names a model your API key cannot reach. Clear it to fall back to `gemini-2.5-flash`, or set a model listed for your key in Google AI Studio.

**AI chat times out or reports high demand**
A Gemini free-tier rate limit or a transient capacity issue upstream. Wait and retry.

**AI chat fails only on campus Wi-Fi**
The Sunway campus network has been observed blocking outbound calls to the Gemini API. Everything else in the app keeps working, since only the assistant leaves the local network for a third-party API. Use a different network or a hotspot when demonstrating the AI feature.

**Budget save fails with a conflict error**
The `unique (user_id, category_id, month, year)` constraint is missing from the `budgets` table. The upsert names that exact conflict target.

**`flutter pub get` fails on the SDK constraint**
Your Flutter is older than the project needs. `pubspec.yaml` requires Dart `^3.11.5`, which ships with Flutter 3.41.x. Run `flutter upgrade`.

---

## 12. Project structure

```
Mobile-App-Fintrack-G7/
├── README.md                  ← you are here
├── docs/                      Test cases and defect logs (not tracked in git)
│
├── fintrack-api/              FastAPI backend
│   ├── .env                   Your secrets, gitignored, you create this
│   ├── .env.example           Template to copy
│   ├── requirements.txt
│   ├── app/
│   │   ├── main.py            App instance, CORS, router registration
│   │   ├── core/
│   │   │   ├── dependencies.py    JWT verification, get_current_user
│   │   │   └── supabase_client.py Supabase client factory
│   │   ├── routers/           auth, profile, transactions, budgets,
│   │   │                      categories, summary, ai
│   │   ├── schemas/           Pydantic request and response models
│   │   └── services/
│   │       └── ai_service.py  Runs agent turns, mirrors them to ai_chat_messages
│   └── agents/
│       ├── assistant.py       ADK agent, Gemini model, session persistence
│       └── tools.py           Read-only financial query tools for the agent
│
└── fintrack-mobile/           Flutter client
    ├── pubspec.yaml
    ├── lib/
    │   ├── main.dart          Entry point, DevicePreview, ProviderScope
    │   ├── app.dart
    │   ├── core/
    │   │   ├── constants/     Colours, text styles, category icon mapping
    │   │   ├── models/
    │   │   ├── router/        go_router config and auth guard
    │   │   ├── services/      api_service.dart, auth_api_service.dart
    │   │   └── widgets/
    │   ├── features/          One folder per module, each with
    │   │   ├── ai_assistant/    screens / providers / models / widgets
    │   │   ├── auth/
    │   │   ├── budget/
    │   │   ├── dashboard/
    │   │   ├── onboarding/
    │   │   ├── profile/
    │   │   └── transactions/
    │   └── shared/navigation/
    └── test/
```

**State management** is Riverpod. **Routing** is go_router, with a redirect guard that keeps unauthenticated users on the auth screens. **Networking** is the `http` package through `ApiService`, which is exposed as a Riverpod provider that rebuilds whenever the auth token changes.

---

## 13. API reference

Every endpoint except the auth ones requires an `Authorization: Bearer <token>` header. The full interactive reference is at http://localhost:8000/docs once the server is running.

| Method | Path | Purpose |
|---|---|---|
| GET | `/` | Health check |
| POST | `/auth/register` | Create a user, auto-confirmed |
| POST | `/auth/login` | Exchange credentials for a JWT |
| POST | `/auth/forgot-password` | Send a reset code |
| POST | `/auth/reset-password` | Complete a reset |
| POST | `/auth/confirm-password` | Re-confirm the current password |
| POST | `/auth/update-password` | Change the password |
| GET | `/profile/` | Current user's profile |
| PUT | `/profile/update-name` | Update display name |
| PUT | `/profile/update-onboarding` | Save onboarding answers |
| POST | `/transactions/` | Create a transaction |
| GET | `/transactions/` | List, filterable by month, year, type |
| PUT | `/transactions/{id}` | Update |
| DELETE | `/transactions/{id}` | Delete |
| POST | `/budgets/` | Create or update a budget for a category and month |
| GET | `/budgets/` | List, filterable by month and year |
| GET | `/categories/` | List, seeding defaults on first call |
| POST | `/categories/` | Create a custom category |
| PUT | `/categories/{id}` | Update |
| DELETE | `/categories/{id}` | Delete |
| GET | `/summary/` | Income, expense, and category totals for a month |
| POST | `/ai/chat` | Send a message to the assistant |
| GET | `/ai/history` | Chat history for a session |

---

## 14. Known gotchas

Current limitations and known issues in the codebase.

- **The API base URL is hardcoded in two files.** Changing one and not the other produces the confusing state where login works but nothing else loads, or the reverse. A single shared constant or a `--dart-define` would remove the problem, and has not been done yet.
- **CORS is wide open.** `allow_origins=["*"]` in [app/main.py](fintrack-api/app/main.py) is convenient for local development on Flutter web, and is not a production-safe setting.
- **JWT verification falls back to unverified claims.** If `JWT_SECRET` is absent or signature verification fails, [dependencies.py](fintrack-api/app/core/dependencies.py) decodes the token without verifying it so local development keeps working. That is a development affordance rather than a security control, and it is why a wrong `JWT_SECRET` can still appear to "work".
- **`AndroidManifest.xml` declares the INTERNET permission only in the debug variant.** Debug builds are fine. A release build (`flutter build apk --release`) will have no network access until `<uses-permission android:name="android.permission.INTERNET"/>` is added to `android/app/src/main/AndroidManifest.xml`.
- **The `profiles` table is written with both `onboarding_done` and `onboarding_completed`.** The API tries one column name and falls back to the other, so either schema works. The SQL in section 4.1 uses `onboarding_done`.
- **The backend imports the AI agent at startup.** A misconfigured `DATABASE_URL` takes down the entire API, not just the chat feature.
