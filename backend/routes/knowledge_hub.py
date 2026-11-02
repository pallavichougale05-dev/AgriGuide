from pathlib import Path
from uuid import uuid4
from translation_service import translate_text

from fastapi import (
    APIRouter,
    Depends,
    File,
    Form,
    HTTPException,
    UploadFile,
)
from sqlalchemy.orm import Session

from database import get_db
from models.knowledge_hub import KnowledgeArticle
from models.farmer_experience import FarmerExperience
from models.user import User
from routes.auth import get_current_user


router = APIRouter(prefix="/knowledge", tags=["Knowledge Hub"])
def localize_experience(item, lang: str):
    title = item.title
    topic = item.topic
    content = item.content

    if lang == "mr":
        title = translate_text(title, "mr")
        topic = translate_text(topic, "mr")
        content = translate_text(content, "mr")

    return {
        "id": item.id,
        "user_id": item.user_id,
        "title": title,
        "topic": topic,
        "content": content,
        "author_name": item.user.full_name if item.user else "Farmer",
        "photo_url": item.photo_url,
        "created_at": (
            item.created_at.isoformat()
            if item.created_at else None
        ),
    }
# ============================================================
# GET ALL KNOWLEDGE ARTICLES
# GET /knowledge/articles
# ============================================================

@router.get("/articles")
def get_articles(db: Session = Depends(get_db)):

    articles = (
        db.query(KnowledgeArticle)
        .order_by(KnowledgeArticle.id)
        .all()
    )

    return {
        "success": True,
        "count": len(articles),
        "articles": [
            {
                "id": article.id,
                "title": article.title,
                "category": article.category,
                "summary": article.summary,
                "content": article.content,
            }
            for article in articles
        ],
    }


# ============================================================
# GET SINGLE ARTICLE
# GET /knowledge/articles/{article_id}
# ============================================================

@router.get("/articles/{article_id}")
def get_article(
    article_id: int,
    db: Session = Depends(get_db),
):

    article = (
        db.query(KnowledgeArticle)
        .filter(KnowledgeArticle.id == article_id)
        .first()
    )

    if article is None:
        raise HTTPException(
            status_code=404,
            detail="Knowledge article not found.",
        )

    return {
        "success": True,
        "article": {
            "id": article.id,
            "title": article.title,
            "category": article.category,
            "summary": article.summary,
            "content": article.content,
        },
    }

# GET ARTICLES BY CATEGORY


@router.get("/categories/{category}")
def get_articles_by_category(
    category: str,
    db: Session = Depends(get_db),
):

    articles = (
        db.query(KnowledgeArticle)
        .filter(
            KnowledgeArticle.category.ilike(category)
        )
        .order_by(KnowledgeArticle.id)
        .all()
    )

    return {
        "success": True,
        "category": category,
        "count": len(articles),
        "articles": [
            {
                "id": article.id,
                "title": article.title,
                "category": article.category,
                "summary": article.summary,
                "content": article.content,
            }
            for article in articles
        ],
    }

# ============================================================
# GET EXPERIENCES SHARED BY THE LOGGED-IN FARMER
# GET /knowledge/my-experiences?lang=en or ?lang=mr
# Requires JWT authentication.

@router.get("/my-experiences")
def get_my_experiences(
    lang: str = "en",
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if lang not in ["en", "mr"]:
        raise HTTPException(
            status_code=400,
            detail="Language must be 'en' or 'mr'.",
        )

    experiences = (
        db.query(FarmerExperience)
        .filter(FarmerExperience.user_id == current_user.id)
        .order_by(FarmerExperience.created_at.desc())
        .all()
    )

    localized_experiences = []

    for item in experiences:
        title = item.title
        topic = item.topic
        content = item.content

        if lang == "mr":
            title = translate_text(title, "mr")
            topic = translate_text(topic, "mr")
            content = translate_text(content, "mr")

        localized_experiences.append({
            "id": item.id,
            "user_id": item.user_id,
            "title": title,
            "topic": topic,
            "content": content,
            "author_name": (
                item.user.full_name if item.user else "Farmer"
            ),
            "photo_url": item.photo_url,
            "created_at": (
                item.created_at.isoformat()
                if item.created_at else None
            ),
        })

    return {
        "success": True,
        "count": len(localized_experiences),
        "experiences": localized_experiences,
    }


# ============================================================
# DELETE A FARMER EXPERIENCE POST
# DELETE /knowledge/experiences/{experience_id}
# Requires JWT authentication.
# Only the post's author can delete it.
# ============================================================

@router.delete("/experiences/{experience_id}")
def delete_experience(
    experience_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    experience = (
        db.query(FarmerExperience)
        .filter(FarmerExperience.id == experience_id)
        .first()
    )

    if experience is None:
        raise HTTPException(
            status_code=404,
            detail="Experience post not found.",
        )

    if experience.user_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="You can delete only your own experience posts.",
        )

    db.delete(experience)
    db.commit()

    return {
        "success": True,
        "message": "Experience post deleted successfully.",
        "id": experience_id,
    }



# ============================================================
# GET FARMER EXPERIENCE POSTS
# GET /knowledge/experiences

@router.get("/experiences")
def get_experiences(
    lang: str = "en",
    db: Session = Depends(get_db),
):
    if lang not in ["en", "mr"]:
        raise HTTPException(
            status_code=400,
            detail="Language must be 'en' or 'mr'.",
        )

    experiences = (
        db.query(FarmerExperience)
        .order_by(FarmerExperience.created_at.desc())
        .all()
    )

    localized_experiences = []

    for item in experiences:
        title = item.title
        topic = item.topic
        content = item.content

        if lang == "mr":
            title = translate_text(title, "mr")
            topic = translate_text(topic, "mr")
            content = translate_text(content, "mr")

        localized_experiences.append({
            "id": item.id,
            "title": title,
            "topic": topic,
            "content": content,
            "author_name": item.user.full_name if item.user else "Farmer",
            "photo_url": item.photo_url,
            "created_at": (
                item.created_at.isoformat()
                if item.created_at else None
            ),
        })

    return {
        "success": True,
        "count": len(localized_experiences),
        "experiences": localized_experiences,
    }


# ============================================================
# CREATE AN EXPERIENCE POST
# POST /knowledge/experiences
# ============================================================

@router.post("/experiences", status_code=201)
def share_experience(
    title: str = Form(..., min_length=1, max_length=200),
    topic: str = Form(..., min_length=1, max_length=150),
    content: str = Form(..., min_length=1),
    photo: UploadFile | None = File(default=None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    title = title.strip()
    topic = topic.strip()
    content = content.strip()

    if not title or not topic or not content:
        raise HTTPException(
            status_code=400,
            detail="Title, topic, and experience description are required.",
        )

    photo_url = None
    saved_photo_path = None

    if photo is not None and photo.filename:
        allowed_types = {
            "image/jpeg": ".jpg",
            "image/png": ".png",
            "image/webp": ".webp",
        }

        extension = allowed_types.get(photo.content_type)

        if extension is None:
            raise HTTPException(
                status_code=400,
                detail="Only JPG, PNG, and WEBP images are supported.",
            )

        upload_dir = (
            Path(__file__).resolve().parents[1]
            / "uploads"
            / "experiences"
        )
        upload_dir.mkdir(parents=True, exist_ok=True)

        filename = f"{uuid4().hex}{extension}"
        saved_photo_path = upload_dir / filename

        try:
            image_bytes = photo.file.read()

            if not image_bytes:
                raise HTTPException(
                    status_code=400,
                    detail="The uploaded photo is empty.",
                )

            if len(image_bytes) > 5 * 1024 * 1024:
                raise HTTPException(
                    status_code=413,
                    detail="Photo size must not exceed 5 MB.",
                )

            saved_photo_path.write_bytes(image_bytes)
            photo_url = f"/uploads/experiences/{filename}"
        finally:
            photo.file.close()

    experience = FarmerExperience(
        user_id=current_user.id,
        title=title,
        topic=topic,
        content=content,
        photo_url=photo_url,
    )

    try:
        db.add(experience)
        db.commit()
        db.refresh(experience)
    except Exception:
        db.rollback()

        if saved_photo_path and saved_photo_path.exists():
            saved_photo_path.unlink()

        raise HTTPException(
            status_code=500,
            detail="Could not publish your experience. Please try again.",
        )

    return {
    "success": True,
    "message": "Experience published successfully.",
    "experience": {
        "id": experience.id,
        "user_id": experience.user_id,
        "title": experience.title,
        "topic": experience.topic,
        "content": experience.content,
        "author_name": current_user.full_name,
        "photo_url": experience.photo_url,
        "created_at": experience.created_at.isoformat(),
    },
}
