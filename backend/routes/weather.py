import httpx

from fastapi import APIRouter, HTTPException


# ============================================================
# WEATHER ROUTER
# ============================================================
#
# WHAT:
# APIRouter groups all weather-related API endpoints.
#
# WHY:
# Keeping weather endpoints separate makes the backend easier
# to maintain as the project grows.
#
# FINAL FLOW:
#
# Flutter
#    ↓
# FastAPI /weather/current
#    ↓
# Open-Meteo
#    ↓
# FastAPI
#    ↓
# Flutter
# ============================================================

router = APIRouter(
    prefix="/weather",
    tags=["Weather"],
)


# ============================================================
# WEATHER API CONFIGURATION
# ============================================================

# WHAT:
# URL of Open-Meteo's public forecast API.
#
# WHY:
# Our FastAPI backend will request weather data from this API.
#
# Open-Meteo provides current weather and forecast data through
# its /v1/forecast endpoint.
OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast"


# ============================================================
# KOLHAPUR DEFAULT LOCATION
# ============================================================

# WHAT:
# Default farm location used when Flutter does not send another
# location.
#
# WHY:
# Your current AgriGuide screens use Kolhapur as the example
# farmer location.
#
# NOTE:
# These are application defaults, not user GPS coordinates.
DEFAULT_LATITUDE = 16.70
DEFAULT_LONGITUDE = 74.24


# ============================================================
# CURRENT + FORECAST WEATHER
# ============================================================

@router.get("/current")
async def get_weather(
    latitude: float = DEFAULT_LATITUDE,
    longitude: float = DEFAULT_LONGITUDE,
):
    # WHAT:
    # Query parameters allow Flutter to request weather for
    # a particular location.
    #
    # Example:
    #
    # /weather/current?latitude=16.70&longitude=74.24
    #
    # WHY:
    # Later, your app can send the farmer's actual location
    # instead of always using Kolhapur.

    # --------------------------------------------------------
    # OPEN-METEO REQUEST
    # --------------------------------------------------------

    # WHAT:
    # These parameters tell Open-Meteo which weather values
    # we want.
    #
    # current:
    #   Gets current temperature, humidity, rain, weather code
    #   and wind speed.
    #
    # daily:
    #   Gets the 5-day maximum/minimum temperature and
    #   weather code.
    #
    # timezone=auto:
    #   Lets the API return times using the location's timezone.
    params = {
        "latitude": latitude,
        "longitude": longitude,

        "current": (
            "temperature_2m,"
            "relative_humidity_2m,"
            "precipitation,"
            "weather_code,"
            "wind_speed_10m"
        ),

        "daily": (
            "weather_code,"
            "temperature_2m_max,"
            "temperature_2m_min,"
            "precipitation_probability_max"
        ),

        "forecast_days": 5,

        "timezone": "auto",

        "temperature_unit": "celsius",

        "wind_speed_unit": "kmh",

        "precipitation_unit": "mm",
    }


    try:
        # WHAT:
        # httpx.AsyncClient makes an asynchronous HTTP request.
        #
        # WHY:
        # FastAPI is designed to handle asynchronous operations,
        # which is useful for external API requests.
        async with httpx.AsyncClient(
            timeout=10.0
        ) as client:

            # Sends a GET request to Open-Meteo.
            response = await client.get(
                OPEN_METEO_URL,
                params=params,
            )


        # ----------------------------------------------------
        # EXTERNAL API ERROR
        # ----------------------------------------------------

        # WHAT:
        # raise_for_status() raises an exception for HTTP
        # errors such as 400 or 500.
        response.raise_for_status()


        # ----------------------------------------------------
        # JSON RESPONSE
        # ----------------------------------------------------

        # Converts Open-Meteo's JSON response into a Python
        # dictionary.
        data = response.json()


        # Extracts current weather information.
        current = data.get(
            "current",
            {},
        )


        # Extracts daily forecast information.
        daily = data.get(
            "daily",
            {},
        )


        # ----------------------------------------------------
        # RETURN CLEAN DATA TO FLUTTER
        # ----------------------------------------------------

        # WHAT:
        # We don't return Open-Meteo's complete response.
        #
        # WHY:
        # Flutter only receives the fields our application
        # actually needs.
        #
        # This also means the Flutter app is protected from
        # unnecessary changes in the external API response.
        return {
            "location": {
                "latitude": latitude,
                "longitude": longitude,
            },

            "current": {
                "temperature": current.get(
                    "temperature_2m"
                ),

                "humidity": current.get(
                    "relative_humidity_2m"
                ),

                "rainfall": current.get(
                    "precipitation"
                ),

                "wind_speed": current.get(
                    "wind_speed_10m"
                ),

                "weather_code": current.get(
                    "weather_code"
                ),
            },

            "forecast": {
                "dates": daily.get(
                    "time",
                    [],
                ),

                "weather_codes": daily.get(
                    "weather_code",
                    [],
                ),

                "max_temperature": daily.get(
                    "temperature_2m_max",
                    [],
                ),

                "min_temperature": daily.get(
                    "temperature_2m_min",
                    [],
                ),

                "rain_probability": daily.get(
                    "precipitation_probability_max",
                    [],
                ),
            },
        }


    except httpx.HTTPError as error:

        # WHAT:
        # Converts external API errors into a clear FastAPI
        # error response.
        #
        # WHY:
        # Flutter should receive a predictable error instead
        # of a raw Python/network exception.
        raise HTTPException(
            status_code=502,
            detail=(
                "Weather service is currently unavailable."
            ),
        ) from error


    except Exception as error:

        # Handles unexpected backend errors.
        raise HTTPException(
            status_code=500,
            detail="Unable to process weather data.",
        ) from error

# ============================================================
# LOCATION SEARCH
# ============================================================

@router.get("/search")
async def search_location(query: str):
    # WHAT:
    # Searches for a place name and returns matching locations.
    #
    # WHY:
    # The farmer can manually type a city/place instead of
    # relying only on GPS.

    if not query.strip():
        raise HTTPException(
            status_code=400,
            detail="Location query cannot be empty.",
        )

    geocoding_url = (
        "https://geocoding-api.open-meteo.com/v1/search"
    )

    params = {
        "name": query.strip(),
        "count": 5,
        "language": "en",
        "format": "json",
        "countryCode": "IN",
    }

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(
                geocoding_url,
                params=params,
            )

        response.raise_for_status()

        data = response.json()

        results = data.get("results", [])

        # Return only the fields our Flutter app needs.
        return {
            "results": [
                {
                    "name": item.get("name", ""),
                    "latitude": item.get("latitude"),
                    "longitude": item.get("longitude"),
                    "country": item.get("country", ""),
                    "admin1": item.get("admin1", ""),
                    "admin2": item.get("admin2", ""),
                }
                for item in results
            ]
        }

    except httpx.HTTPError as error:
        raise HTTPException(
            status_code=502,
            detail="Location search service is unavailable.",
        ) from error