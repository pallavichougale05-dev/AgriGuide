"""
Trains the crop model from data/crop_dataset.csv and saves everything the API needs.

Run from the backend folder:
    python -m crop_recommendation.train

Creates in crop_recommendation/models/:
    crop_model.pkl      the crop model (small: about 5 MB)
    varieties.json      the variety names that exist for each crop in the dataset
    model_report.json   accuracy on rows the model did not see during training

Run this again if the API says the model file could not be loaded (that
happens when scikit-learn on the server has a different version).
"""
import json
from pathlib import Path

import joblib
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, f1_score, top_k_accuracy_score
from sklearn.model_selection import train_test_split

HERE = Path(__file__).resolve().parent
DATA_PATH = HERE / "data" / "crop_dataset.csv"
MODEL_DIR = HERE / "models"

# Same 7 inputs, same order, as the teammate's original training script.
FEATURES = ["Temperature_C", "Humidity_pct", "Rainfall_mm", "Soil_pH",
            "Nitrogen_N", "Phosphorus_P", "Potassium_K"]
TARGET = "Crop"


def new_model():
    # max_depth / min_samples_leaf keep the file small (about 5 MB instead of 259 MB)
    # with the same accuracy.
    return RandomForestClassifier(n_estimators=150, max_depth=14, min_samples_leaf=3,
                                  class_weight="balanced", random_state=42, n_jobs=-1)


def main():
    df = pd.read_csv(DATA_PATH)
    df = df.dropna(subset=FEATURES + [TARGET]).drop_duplicates()
    X, y = df[FEATURES], df[TARGET]

    # 1) Honest test: train on 80%, test on the 20% the model has not seen.
    X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)
    check = new_model().fit(X_tr, y_tr)
    proba = check.predict_proba(X_te)
    report = {
        "rows": int(len(df)), "crops": int(y.nunique()),
        "top1_accuracy": round(float(accuracy_score(y_te, check.predict(X_te))), 3),
        "top3_accuracy": round(float(top_k_accuracy_score(y_te, proba, k=3, labels=check.classes_)), 3),
        "top5_accuracy": round(float(top_k_accuracy_score(y_te, proba, k=5, labels=check.classes_)), 3),
        "macro_f1": round(float(f1_score(y_te, check.predict(X_te), average="macro")), 3),
        "note": ("The training data is generated, so these numbers show how well the model learned "
                 "the generated patterns, not how it would perform on real fields."),
    }

    # 2) Final model: train on all rows.
    final = new_model().fit(X, y)
    MODEL_DIR.mkdir(exist_ok=True)
    joblib.dump({"model": final, "features": FEATURES, "classes": list(final.classes_)},
                MODEL_DIR / "crop_model.pkl", compress=3)

    varieties = {crop: sorted(g["Variety"].dropna().astype(str).unique())
                 for crop, g in df.groupby(TARGET)}
    (MODEL_DIR / "varieties.json").write_text(json.dumps(varieties, indent=1, ensure_ascii=False), encoding="utf-8")
    (MODEL_DIR / "model_report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print("Saved model, varieties and report.", report)


if __name__ == "__main__":
    main()
