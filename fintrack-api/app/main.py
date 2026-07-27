from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import auth_router, summary, profile

app = FastAPI(title="FinTrack API")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(auth_router.router, tags=["Auth"])
app.include_router(summary.router, prefix="/summary", tags=["Summary"])
app.include_router(profile.router, prefix="/profile", tags=["Profile"])

@app.get("/")
def read_root():
    return {"message": "Welcome to FinTrack API"}
