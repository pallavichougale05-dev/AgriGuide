# ============================================================
# AgriGuide Assistant - Gemini Chatbot API
# ============================================================
#
# This API powers the AgriGuide farming assistant.
#
# FLOW:
#
# Flutter
#    ↓
# POST /chat/message
#    ↓
# FastAPI
#    ↓
# Gemini
#    ↓
# Complete agriculture answer
#    ↓
# Flutter
#
# IMPORTANT:
# - Language is controlled by the backend.
# - Responses are requested in ONE language only.
# - Output length is increased so answers are not cut short.
# - The model is instructed to complete its answer.
# ============================================================


# ============================================================
# IMPORTS
# ============================================================

import os

from dotenv import load_dotenv
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from google import genai
from google.genai import types


# ============================================================
# LOAD ENVIRONMENT VARIABLES
# ============================================================

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

if not GEMINI_API_KEY:
    raise RuntimeError(
        "GEMINI_API_KEY is not configured. "
        "Please add it to backend/.env"
    )


# ============================================================
# CREATE GEMINI CLIENT
# ============================================================
#
# Timeout:
# 60000 ms = 60 seconds
#
# This gives Gemini enough time to generate a complete
# agriculture response without allowing the request to hang
# indefinitely.
# ============================================================

client = genai.Client(
    api_key=GEMINI_API_KEY,
    http_options=types.HttpOptions(
        timeout=60000,
    ),
)


# ============================================================
# FASTAPI ROUTER
# ============================================================

router = APIRouter(
    prefix="/chat",
    tags=["AgriGuide Assistant"],
)


# ============================================================
# REQUEST MODEL
# ============================================================

class ChatRequest(BaseModel):
    message: str


# ============================================================
# RESPONSE MODEL
# ============================================================

class ChatResponse(BaseModel):
    response: str


# ============================================================
# LANGUAGE DETECTION
# ============================================================

def detect_requested_language(
    message: str,
) -> str:

    text = message.lower().strip()

    marathi_indicators = [
        "in marathi",
        "marathi",
        "मराठीत",
        "मराठीमध्ये",
        "मराठी मध्ये",
        "मराठी",
    ]

    for indicator in marathi_indicators:
        if indicator in text:
            return "Marathi"

    english_indicators = [
        "in english",
        "english",
    ]

    for indicator in english_indicators:
        if indicator in text:
            return "English"

    # Default language.
    return "English"


# REMOVE UNWANTED MODEL FORMATTING


def clean_model_response(
    answer: str,
) -> str:

    result = answer.strip()

    # Remove Markdown bold markers.
    result = result.replace(
        "**",
        "",
    )

    result = result.replace(
        "__",
        "",
    )

    # Remove horizontal separators.
    result = result.replace(
        "---",
        "",
    )

    result = result.replace(
        "___",
        "",
    )

    # Remove fenced code markers if the model ever produces them.
    result = result.replace(
        "```",
        "",
    )

    # Avoid excessive blank lines.
    while "\n\n\n" in result:
        result = result.replace(
            "\n\n\n",
            "\n\n",
        )

    return result.strip()


# ============================================================
# AGRIGUIDE SYSTEM INSTRUCTION

SYSTEM_INSTRUCTION = """
You are AgriGuide Assistant, a professional agriculture
"""

# CHAT ENDPOINT

@router.post(
    "/message",
    response_model=ChatResponse,
)
async def chat_message(
    data: ChatRequest,
):

    # VALIDATE USER MESSAGE

    message = data.message.strip()

    if not message:
        raise HTTPException(
            status_code=400,
            detail="Message cannot be empty.",
        )


    # ========================================================
    # DETECT REQUESTED LANGUAGE
    # ========================================================

    requested_language = detect_requested_language(
        message,
    )

    # CREATE FINAL GEMINI PROMPT
   

    final_prompt = f"""
REQUESTED RESPONSE LANGUAGE:
{requested_language}

IMPORTANT:
Respond ONLY in {requested_language}.

Do not provide a second-language translation.

The farmer's original request is below:

{message}

Now provide a complete, practical agriculture answer.

Make sure the answer:
- directly answers the farmer's question,
- includes the important checks,
- explains what the farmer should do,
- is complete,
- does not stop halfway,
- ends properly,
- does not use Markdown formatting.
"""


    try:

        # ====================================================
        # SEND REQUEST TO GEMINI
        # ====================================================
        #
        # Increased from 300 to 800 tokens.
        #
        # This gives the assistant enough space for:
        #
        # - explanation
        # - checks
        # - practical steps
        # - final recommendation
        #
        # without making answers unnecessarily long.
        # ====================================================

        response = await client.aio.models.generate_content(
            model="gemini-3.5-flash-lite",

            contents=final_prompt,

            config=types.GenerateContentConfig(
                system_instruction=SYSTEM_INSTRUCTION,

                max_output_tokens=800,

                temperature=0.4,
            ),
        )


        # ====================================================
        # READ GEMINI RESPONSE
        # ====================================================

        answer = response.text


        # ====================================================
        # CHECK EMPTY RESPONSE
        # ====================================================

        if not answer:
            raise HTTPException(
                status_code=502,
                detail="Gemini returned an empty response.",
            )


        # ====================================================
        # CLEAN RESPONSE
        # ====================================================

        answer = clean_model_response(
            answer,
        )


        # ====================================================
        # FINAL EMPTY CHECK
        # ====================================================

        if not answer:
            raise HTTPException(
                status_code=502,
                detail="Gemini returned an empty response.",
            )


        # ====================================================
        # RETURN RESPONSE TO FLUTTER
        # ========================================================

        return ChatResponse(
            response=answer,
        )


    except HTTPException:
        raise


    except Exception as error:

        # ----------------------------------------------------
        # DEVELOPMENT LOGGING
        # ----------------------------------------------------

        print(
            "GEMINI ERROR TYPE:",
            type(error).__name__,
        )

        print(
            "GEMINI ERROR:",
            str(error),
        )


        # ----------------------------------------------------
        # RETURN SAFE API ERROR
        # ----------------------------------------------------

        raise HTTPException(
            status_code=502,
            detail="Unable to get a response from Gemini.",
        ) from error