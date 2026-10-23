from fastapi import FastAPI

# Imports the Crop Recommendation router.
from routes.crop import router as crop_router

# Imports the Weather router.
from routes.weather import router as weather_router

# Imports the Knowledge Hub router.
from routes.knowledge_hub import router as knowledge_router

# Imports the AgriGuide Assistant router.
from routes.chatbot import router as chatbot_router

# Imports the Disease Detection router.
from routes.disease import router as disease_router

# Imports the Farm Diary router.
from routes.diary import router as diary_router

# Imports the Authentication router.
from routes.auth import router as auth_router

from models.knowledge_hub import KnowledgeArticle

# MAIN FASTAPI APPLICATION

app = FastAPI(
    title="AgriGuide API",
    description="Backend API for the AgriGuide application",
    version="1.0.0",
)

# REGISTER CROP ROUTES
app.include_router(crop_router)

# REGISTER WEATHER ROUTES
app.include_router(weather_router)


# REGISTER AGRIGUIDE ASSISTANT ROUTES
# ============================================================

app.include_router(chatbot_router)


# ============================================================
# REGISTER DISEASE DETECTION ROUTES
# ============================================================

app.include_router(disease_router)


# ============================================================
# REGISTER KNOWLEDGE HUB ROUTES
# ============================================================

app.include_router(knowledge_router)


# ============================================================
# REGISTER FARM DIARY ROUTES
# ============================================================

app.include_router(diary_router)


# ============================================================
# REGISTER AUTHENTICATION ROUTES
# ============================================================

app.include_router(auth_router)


# HEALTH CHECK

@app.get("/test")
def test_api():
    return {
        "message": "AgriGuide API is working"
    }