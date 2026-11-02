
import requests

# Cache translated text during the current backend session.
_translation_cache = {}


def translate_text(text: str, target_language: str = "mr") -> str:
    if not text or not text.strip():
        return text

    if target_language == "en":
        return text

    cache_key = (text.strip(), target_language)

    # Return cached translation if available.
    if cache_key in _translation_cache:
        return _translation_cache[cache_key]

    try:
        response = requests.get(
            "https://api.mymemory.translated.net/get",
            params={
                "q": text,
                "langpair": f"en|{target_language}",
            },
            timeout=15,
        )

        response.raise_for_status()
        data = response.json()

        if data.get("responseStatus") == 200:
            translated_text = data["responseData"]["translatedText"]

            # Store successful translation.
            _translation_cache[cache_key] = translated_text

            return translated_text

        print("Translation service response:", data.get("responseDetails"))
        return text

    except requests.RequestException as error:
        print(f"Translation error: {error}")
        return text
