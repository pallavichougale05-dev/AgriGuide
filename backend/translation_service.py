
import requests
import re
import html
import time

_translation_blocked_until = 0
TRANSLATION_COOLDOWN_SECONDS = 600

# Cache successful translations during the backend session.
_translation_cache = {}

# MyMemory allows a maximum of 500 characters per request.
# Use 450 to leave a safety margin.
MAX_CHUNK_LENGTH = 450


def detect_source_language(text: str) -> str:
    """
    Detect English or Marathi using the Devanagari script.
    Marathi text is normally written in Devanagari.
    """

    if any("\u0900" <= char <= "\u097F" for char in text):
        return "mr"

    return "en"


def split_text(text: str, max_length: int = MAX_CHUNK_LENGTH):
    """
    Split long text into chunks without cutting words.
    """

    words = text.split()
    chunks = []
    current_chunk = ""

    for word in words:

        if len(word) > max_length:
            if current_chunk:
                chunks.append(current_chunk)
                current_chunk = ""

            for i in range(0, len(word), max_length):
                chunks.append(word[i:i + max_length])

            continue

        candidate = (
            f"{current_chunk} {word}"
            if current_chunk
            else word
        )

        if len(candidate) <= max_length:
            current_chunk = candidate
        else:
            chunks.append(current_chunk)
            current_chunk = word

    if current_chunk:
        chunks.append(current_chunk)

    return chunks



def translate_chunk(
    text: str,
    source_language: str,
    target_language: str,
) -> str:

    global _translation_blocked_until

    cache_key = (
        text,
        source_language,
        target_language,
    )

    if cache_key in _translation_cache:
        return _translation_cache[cache_key]

    # Avoid calling MyMemory during cooldown.
    if time.time() < _translation_blocked_until:
        return text

    try:
        response = requests.get(
            "https://api.mymemory.translated.net/get",
            params={
                "q": text,
                "langpair": (
                    f"{source_language}|{target_language}"
                ),
            },
            timeout=15,
        )

        if response.status_code == 429:
            _translation_blocked_until = (
                time.time() + TRANSLATION_COOLDOWN_SECONDS
            )

            print(
                "MyMemory rate limit reached. "
                "Translation paused for 10 minutes."
            )

            return text

        response.raise_for_status()
        data = response.json()

        if data.get("responseStatus") == 200:
            translated_text = html.unescape(
                data["responseData"]["translatedText"]
            )

            _translation_cache[cache_key] = translated_text

            return translated_text

        print(
            "Translation service response:",
            data.get("responseDetails"),
        )

        return text

    except requests.RequestException as error:
        print(f"Translation error: {error}")
        return text



def translate_text(
    text: str,
    target_language: str = "mr",
) -> str:

    if not text or not text.strip():
        return text

    if target_language not in ("en", "mr"):
        return text

    # Detect the language of the original text.
    source_language = detect_source_language(text)

    # Do not send same-language translation requests.
    if source_language == target_language:
        return text

    # Split long text into smaller requests.
    chunks = split_text(text)

    translated_chunks = []

    for chunk in chunks:

        translated_chunk = translate_chunk(
            chunk,
            source_language,
            target_language,
        )

        translated_chunks.append(translated_chunk)

    return " ".join(translated_chunks)
