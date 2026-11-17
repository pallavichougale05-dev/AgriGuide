"""
Loads the trained crop model once (when the server starts) and returns the top-5 crops.
All file paths are relative to this file, so it works no matter where you start the server from.
"""
import json
from pathlib import Path

import joblib
import numpy as np
import pandas as pd

MODEL_DIR = Path(__file__).resolve().parent / "models"

try:
    _bundle = joblib.load(MODEL_DIR / "crop_model.pkl")
    _model = _bundle["model"]
    FEATURES = _bundle["features"]          # exact column names and order used in training
    _varieties = json.loads((MODEL_DIR / "varieties.json").read_text(encoding="utf-8"))
except Exception as exc:                    # wrong scikit-learn version, missing file, etc.
    raise RuntimeError(
        "Could not load the crop model. Run this once from the backend folder, then start the "
        "server again:  python -m crop_recommendation.train   (original error: %s)" % exc
    ) from exc


def recommend_top5(nitrogen, phosphorus, potassium, temperature, humidity, ph, rainfall):
    values = {"Temperature_C": temperature, "Humidity_pct": humidity, "Rainfall_mm": rainfall,
              "Soil_pH": ph, "Nitrogen_N": nitrogen, "Phosphorus_P": phosphorus, "Potassium_K": potassium}
    row = pd.DataFrame([[values[f] for f in FEATURES]], columns=FEATURES)
    scores = _model.predict_proba(row)[0]
    top = np.argsort(scores)[::-1][:5]
    return [{
        "crop": str(_model.classes_[i]),
        "score": round(float(scores[i]), 4),          # the model's probability, NOT "accuracy"
        "varieties": _varieties.get(str(_model.classes_[i]), []),
    } for i in top]
