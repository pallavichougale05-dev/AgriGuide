
"""
Loads the two trained models once and predicts the most likely crop disease.

MobileNetV2 and EfficientNetB0 are combined with 40:60 weighting.
"""

import json
import os
import threading
from pathlib import Path

import numpy as np

from . import image_utils
from .labels import describe

BASE = Path(__file__).resolve().parent
MODELS = BASE / "models"
SOLUTIONS_FILE = BASE / "data" / "solutions.json"

MOBILENET_WEIGHT = 0.40
EFFICIENTNET_WEIGHT = 0.60

# Provisional thresholds. Tune using real field images.
MIN_CONFIDENCE = float(os.getenv("DISEASE_MIN_CONFIDENCE", "0.55"))
MIN_MARGIN = float(os.getenv("DISEASE_MIN_MARGIN", "0.15"))
HEALTHY_MIN_CONFIDENCE = float(
    os.getenv("DISEASE_HEALTHY_MIN_CONFIDENCE", "0.75")
)

REVIEW_NOTE = (
    "This advice is still being reviewed by an agriculture expert. "
    "Please confirm with your local Krishi Vigyan Kendra or agriculture office "
    "before you act."
)

SPRAY_NOTE = (
    "No verified spray advice is available yet. Please ask your local "
    "agriculture office which product is allowed and how to use it."
)

MESSAGES = {
    "ok": "Result ready.",
    "not_confident": (
        "The image could not be identified confidently. "
        "Please upload a clear photo of one supported crop leaf."
    ),
    "too_dark": "The photo is too dark. Please take it in better light.",
    "too_small": "The photo is too small. Please use a clearer, larger photo.",
    "too_blurry": (
        "The image is blurry. Please upload a clear photo of one leaf."
    ),
}


class DiseaseDetector:

    def __init__(self):
        self.error = None
        self._lock = threading.Lock()

        try:
            os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")

            import tensorflow as tf

            self.names = json.loads(
                (MODELS / "class_names_v3.json").read_text(
                    encoding="utf-8"
                )
            )

            self.mobilenet = tf.keras.models.load_model(
                MODELS / "agri_mobilenetv2_weighted_best.keras",
                compile=False,
            )

            self.efficientnet = tf.keras.models.load_model(
                MODELS / "agri_efficientnetb0_v3_best.keras",
                compile=False,
            )

            if (
                self.mobilenet.output_shape[-1] != len(self.names)
                or self.efficientnet.output_shape[-1] != len(self.names)
            ):
                raise ValueError(
                    "Model output size does not match class_names_v3.json"
                )

            self.labels = [describe(name) for name in self.names]

            self.solutions = (
                json.loads(SOLUTIONS_FILE.read_text(encoding="utf-8"))
                if SOLUTIONS_FILE.exists()
                else {}
            )

        except Exception as exc:
            self.error = str(exc)

    @property
    def ready(self):
        return self.error is None

    def _probabilities(self, array):

        with self._lock:
            a = self.mobilenet(array, training=False).numpy()[0]
            b = self.efficientnet(array, training=False).numpy()[0]

        return (
            MOBILENET_WEIGHT * a
            + EFFICIENTNET_WEIGHT * b
        )

    def detect(self, data: bytes) -> dict:
        """
        Detect one crop and one disease.

        Returns a rejection response if the image quality or
        prediction confidence is insufficient.
        """

        image = image_utils.open_image(data)

        problem, is_blurry = image_utils.quality(image)

        if problem:
            return self._empty(problem, is_blurry)

        probs = self._probabilities(
            image_utils.to_model_input(image)
        )

        order = np.argsort(probs)[::-1]

        best = int(order[0])
        second = int(order[1])

        label = self.labels[best]

        top = float(probs[best])
        margin = float(probs[best] - probs[second])

        needed = (
            HEALTHY_MIN_CONFIDENCE
            if label["is_healthy"]
            else MIN_CONFIDENCE
        )

        # Reject uncertain or ambiguous predictions.
        if top < needed or margin < MIN_MARGIN:
            return self._empty("not_confident", is_blurry)

        # Return only the best prediction.
        return {
            "status": "ok",
            "message": MESSAGES["ok"],
            "is_blurry": is_blurry,
            "crop": label["crop"],
            "disease": label["disease"],
            "is_healthy": label["is_healthy"],
            "is_pest": label["is_pest"],
            "part": label["part"],
            "confidence": round(top, 4),
            "solution": self._solution(label),
        }

    def _solution(self, label):

        if label["is_healthy"]:
            return {
                "kind": "healthy",
                "message": (
                    "The leaf looks healthy. No disease treatment is needed."
                ),
                "review_note": None,
                "spray_note": None,
            }

        entry = self.solutions.get(label["raw"])

        if label["is_pest"]:
            return {
                "kind": "pest",
                "message": (
                    "This looks like an insect pest problem, "
                    "not a leaf disease."
                ),
                "review_note": None,
                "spray_note": SPRAY_NOTE,
            }

        if entry is None:
            return {
                "kind": "none",
                "message": (
                    "Detailed advice for this problem is not available yet."
                ),
                "review_note": None,
                "spray_note": SPRAY_NOTE,
            }

        return {
            "kind": "disease",
            "symptoms": entry["symptoms"],
            "causes": entry["causes"],
            "fertilizer": entry["fertilizer"],
            "management": entry.get("management"),
            "review_note": REVIEW_NOTE,
            "spray_note": SPRAY_NOTE,
        }

    @staticmethod
    def _empty(code, is_blurry):
        return {
            "status": code,
            "message": MESSAGES[code],
            "is_blurry": is_blurry,
            "crop": None,
            "disease": None,
            "is_healthy": False,
            "is_pest": False,
            "part": None,
            "confidence": None,
            "solution": None,
        }


detector = DiseaseDetector()
