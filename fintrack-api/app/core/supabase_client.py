import os
from dotenv import load_dotenv

# Load environment variables from the .env file
load_dotenv()

try:
    from supabase import create_client, Client
    HAS_SUPABASE = True
except ImportError:
    create_client = None
    Client = None
    HAS_SUPABASE = False

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY") or os.getenv("SUPABASE_ANON_KEY")

def get_supabase():
    """
    Dependency to inject the Supabase client into endpoints.
    Returns None if supabase library or keys are missing for defensive local fallback.
    """
    if not HAS_SUPABASE or not SUPABASE_URL or not SUPABASE_KEY:
        return None
    try:
        return create_client(SUPABASE_URL, SUPABASE_KEY)
    except Exception:
        return None
