from fastapi import FastAPI

# Routers
from routes.crop import router as crop_router
from routes.weather import router as weather_router
from routes.knowledge_hub import router as knowledge_router
from routes.chatbot import router as chatbot_router
from routes.disease import router as disease_router
from routes.diary import router as diary_router
from routes.auth import router as auth_router

# Database models registered with SQLAlchemy
from models.knowledge_hub import KnowledgeArticle
from models.farmer_experience import FarmerExperience

from pathlib import Path
from fastapi.staticfiles import StaticFiles

app = FastAPI(
    title="AgriGuide API",
    description="Backend API for the AgriGuide application",
    version="1.0.0",
)

UPLOADS_DIR = Path(__file__).resolve().parent / "uploads"
UPLOADS_DIR.mkdir(parents=True, exist_ok=True)

app.mount(
    "/uploads",
    StaticFiles(directory=str(UPLOADS_DIR)),
    name="uploads",
)

# Register feature routers
app.include_router(crop_router)
app.include_router(weather_router)
app.include_router(chatbot_router)
app.include_router(disease_router)
app.include_router(knowledge_router)
app.include_router(diary_router)
app.include_router(auth_router)


@app.get("/test")
def test_api():
    return {"message": "AgriGuide API is working"}
