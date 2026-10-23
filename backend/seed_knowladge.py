from database import SessionLocal
from models.knowledge_hub import KnowledgeArticle


KNOWLEDGE_ARTICLES = [
    {
        "title": "Understanding Soil Health",
        "category": "Soil",
        "summary": (
            "Learn why healthy soil is important for crop growth "
            "and how farmers can maintain soil quality."
        ),
        "content": (
            "Healthy soil provides plants with nutrients, water, "
            "air and support for root growth. Farmers can maintain "
            "soil health by using organic matter, practicing crop "
            "rotation, avoiding excessive chemical inputs and "
            "monitoring soil properties regularly."
        ),
    },
    {
        "title": "Importance of Soil Testing",
        "category": "Soil",
        "summary": (
            "Understand how soil testing helps farmers make better "
            "fertilizer and crop management decisions."
        ),
        "content": (
            "Soil testing provides information about important "
            "properties such as nutrient availability and soil pH. "
            "Farmers can use these results to select suitable "
            "fertilizer quantities and improve soil management."
        ),
    },
    {
        "title": "Efficient Water Management",
        "category": "Water Management",
        "summary": (
            "Learn practical approaches for using irrigation water "
            "efficiently."
        ),
        "content": (
            "Efficient water management helps reduce unnecessary "
            "water use while maintaining crop growth. Farmers can "
            "consider crop water requirements, soil moisture, "
            "weather conditions and suitable irrigation methods "
            "when planning irrigation."
        ),
    },
    {
        "title": "Crop Rotation",
        "category": "Crop Management",
        "summary": (
            "Learn how growing different crops in sequence can "
            "support better farm management."
        ),
        "content": (
            "Crop rotation means growing different crops on the "
            "same field in a planned sequence. It can help improve "
            "soil management, diversify farm production and reduce "
            "the continuous pressure associated with growing the "
            "same crop repeatedly."
        ),
    },
    {
        "title": "Recognizing Crop Diseases",
        "category": "Crop Protection",
        "summary": (
            "Understand the basic signs that may indicate disease "
            "or stress in crops."
        ),
        "content": (
            "Farmers should regularly observe leaves, stems, fruits "
            "and overall plant growth. Changes such as unusual "
            "spots, discoloration, wilting or abnormal growth can "
            "indicate disease or other plant stress. Correct "
            "identification should be done before selecting a "
            "management approach."
        ),
    },
    {
        "title": "Integrated Pest Management",
        "category": "Crop Protection",
        "summary": (
            "Learn the basic idea of managing agricultural pests "
            "using multiple approaches."
        ),
        "content": (
            "Integrated Pest Management combines monitoring, "
            "preventive practices, biological approaches, cultural "
            "methods and other suitable control measures. The goal "
            "is to manage pests effectively while reducing "
            "unnecessary intervention."
        ),
    },
    {
        "title": "Weather and Farming",
        "category": "Weather",
        "summary": (
            "Understand why weather information is important for "
            "farm planning."
        ),
        "content": (
            "Weather conditions influence irrigation, sowing, "
            "fertilizer application, harvesting and crop protection. "
            "Farmers can use local weather information along with "
            "field observations when planning agricultural "
            "activities."
        ),
    },
    {
        "title": "Good Farming Record Practices",
        "category": "Farm Management",
        "summary": (
            "Learn why maintaining farm records can help with "
            "better decision-making."
        ),
        "content": (
            "Recording activities such as sowing dates, fertilizer "
            "use, irrigation, crop problems, expenses and harvest "
            "results can help farmers review farm performance and "
            "make better decisions in future seasons."
        ),
    },
]


def seed_knowledge_articles():
    db = SessionLocal()

    try:
        existing_count = db.query(KnowledgeArticle).count()

        if existing_count > 0:
            print(
                f"Knowledge Hub already contains "
                f"{existing_count} article(s)."
            )
            return

        articles = [
            KnowledgeArticle(**article)
            for article in KNOWLEDGE_ARTICLES
        ]

        db.add_all(articles)
        db.commit()

        print(
            f"Successfully inserted {len(articles)} "
            "Knowledge Hub articles."
        )

    except Exception:
        db.rollback()
        raise

    finally:
        db.close()


if __name__ == "__main__":
    seed_knowledge_articles()