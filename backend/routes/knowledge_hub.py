from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from database import get_db
from models.knowledge_hub import KnowledgeArticle


router = APIRouter(
    prefix="/knowledge",
    tags=["Knowledge Hub"],
)


# ============================================================
# GET ALL KNOWLEDGE ARTICLES
# ============================================================
#
# Endpoint:
# GET /knowledge/articles
#
# Data source:
# PostgreSQL -> knowledge_articles
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
# ============================================================
#
# Endpoint:
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

    if not article:
        return {
            "success": False,
            "message": "Knowledge article not found.",
        }

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


# ============================================================
# GET ARTICLES BY CATEGORY
# ============================================================
#
# Endpoint:
# GET /knowledge/categories/{category}
#
# Example:
# GET /knowledge/categories/Soil
# ============================================================

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