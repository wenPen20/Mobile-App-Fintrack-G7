# FinTrack API

Backend API using FastAPI.

## Setup

1. Create a virtual environment:
   ```bash
   python -m venv venv
   ```
2. Activate virtual environment:
   - Windows: `.\venv\Scripts\activate`
   - Unix/macOS: `source venv/bin/activate`
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Copy `.env.example` to `.env` and fill in configuration.
5. Run the server:
   ```bash
   uvicorn app.main:app --reload
   ```
