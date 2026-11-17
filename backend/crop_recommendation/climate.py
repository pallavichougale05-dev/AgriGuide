
import time
import math
from datetime import date, timedelta

import httpx

ARCHIVE_URL = "https://archive-api.open-meteo.com/v1/archive"
_CACHE: dict = {}
_CACHE_SECONDS = 24 * 3600


class ClimateUnavailable(Exception):
    pass



def summarize(payload: dict) -> dict:
    daily = payload.get("daily") or {}

    temps = daily.get("temperature_2m_mean") or []
    humidity = daily.get("relative_humidity_2m_mean") or []
    rain = daily.get("precipitation_sum") or []
    dates = daily.get("time") or []

    if not (len(temps) == len(humidity) == len(rain) == len(dates)):
        raise ClimateUnavailable("Climate arrays have different lengths.")

    if len(dates) < 330:
        raise ClimateUnavailable(
            f"Insufficient daily climate data: {len(dates)} days."
        )

    # Keep only days where all three climate measurements are valid.
    valid_days = []

    for day, temp, hum, rainfall in zip(dates, temps, humidity, rain):
        if temp is None or hum is None or rainfall is None:
            continue

        values = [temp, hum, rainfall]

        if not all(
            isinstance(v, (int, float)) and math.isfinite(v)
            for v in values
        ):
            continue

        if not -10 <= temp <= 60:
            continue

        if not 0 <= hum <= 100:
            continue

        if rainfall < 0:
            continue

        valid_days.append((day, temp, hum, rainfall))

    if len(valid_days) < 330:
        raise ClimateUnavailable(
            f"Only {len(valid_days)} valid climate days are available."
        )

    temperature = sum(row[1] for row in valid_days) / len(valid_days)
    mean_humidity = sum(row[2] for row in valid_days) / len(valid_days)
    total_rainfall = sum(row[3] for row in valid_days)

    print("Climate diagnostic:")
    print("Valid days:", len(valid_days))
    print("Dates:", valid_days[0][0], "to", valid_days[-1][0])
    print(
        "Temperature min/max:",
        min(row[1] for row in valid_days),
        max(row[1] for row in valid_days)
    )
    print(
        "Humidity min/max:",
        min(row[2] for row in valid_days),
        max(row[2] for row in valid_days)
    )
    print("Annual mean temperature:", round(temperature, 1))
    print("Annual mean humidity:", round(mean_humidity, 1))
    print("Annual rainfall:", round(total_rainfall, 1))

    return {
        "temperature": round(temperature, 1),
        "humidity": round(mean_humidity, 1),
        "rainfall": round(total_rainfall, 1),
    }


async def get_annual_climate(latitude: float, longitude: float) -> dict:
    key = (round(latitude, 2), round(longitude, 2))

    hit = _CACHE.get(key)
    if hit and time.time() - hit[0] < _CACHE_SECONDS:
        return hit[1]

    end = date.today() - timedelta(days=7)
    start = end - timedelta(days=364)

    params = {
        "latitude": latitude,
        "longitude": longitude,
        "start_date": start.isoformat(),
        "end_date": end.isoformat(),
        "daily": (
            "temperature_2m_mean,"
            "relative_humidity_2m_mean,"
            "precipitation_sum"
        ),
        "temperature_unit": "celsius",
        "precipitation_unit": "mm",
        "timezone": "Asia/Kolkata",
    }

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(ARCHIVE_URL, params=params)
            response.raise_for_status()
            payload = response.json()

            print("Open-Meteo response coordinates:",
                  payload.get("latitude"), payload.get("longitude"))
            print("Open-Meteo daily units:",
                  payload.get("daily_units"))
            print("Requested dates:", start, "to", end)

            result = summarize(payload)

    except httpx.HTTPError as exc:
        raise ClimateUnavailable(
            "Could not get weather history right now."
        ) from exc

    _CACHE[key] = (time.time(), result)
    return result
