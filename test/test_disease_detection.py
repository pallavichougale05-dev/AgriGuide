"""Run from the backend folder:   python -m pytest tests/test_disease_detection.py
Uses the real models (first run takes a few seconds to load them)."""
import io, json, pathlib, sys
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

import numpy as np
import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from PIL import Image

from disease_detection import image_utils
from disease_detection.detector import detector
from disease_detection.labels import describe
from disease_detection.router import router

app = FastAPI(); app.include_router(router); client = TestClient(app)


def png(array):
    buf = io.BytesIO(); Image.fromarray(np.asarray(array, dtype=np.uint8)).save(buf, "PNG"); return buf.getvalue()


def post(data, name="leaf.png", ctype="image/png"):
    return client.post("/disease/detect", files={"image": (name, data, ctype)})


def index_of(crop, disease):
    for i, label in enumerate(detector.labels):
        if label["crop"] == crop and label["disease"] == disease:
            return i
    raise AssertionError(f"{crop} / {disease} not in the model")


def fake_probs(monkeypatch, **weights):
    """Make the models answer with chosen probabilities (to test the decision rules)."""
    p = np.full(len(detector.names), 1e-4)
    for index, value in weights.items():
        p[int(index)] = value
    monkeypatch.setattr(detector, "_probabilities", lambda array: p)


def test_models_are_loaded():
    assert client.get("/disease/status").json() == {"ready": True, "error": None, "classes": 78}


def test_every_class_has_a_readable_name():
    for raw in detector.names:
        d = describe(raw)
        assert d["crop"] and d["disease"] and "_" not in d["disease"] and "/" not in d["disease"], raw


def test_solutions_never_contain_spray_advice():
    for raw, entry in detector.solutions.items():
        assert set(entry) <= {"healthy", "symptoms", "causes", "fertilizer"}, raw


@pytest.mark.parametrize("make", [
    lambda: np.random.RandomState(0).randint(0, 256, (300, 300, 3)),
    lambda: np.full((300, 300, 3), 128),
    lambda: np.full((300, 300, 3), 255),
    lambda: np.dstack([np.full((300, 300), 40), np.full((300, 300), 160), np.full((300, 300), 50)]),
])
def test_pictures_that_are_not_leaves_never_get_a_confident_answer(make):
    body = post(png(make())).json()
    assert body["status"] != "ok" and body["disease"] is None and body["solution"] is None


def test_dark_and_small_photos_are_refused_politely():
    assert post(png(np.full((300, 300, 3), 5))).json()["status"] == "too_dark"
    assert post(png(np.full((100, 100, 3), 150))).json()["status"] == "too_small"


def test_files_that_are_not_images_get_a_400():
    assert post(b"hello, I am not a picture", "a.txt", "text/plain").status_code == 400
    assert post(b"", "empty.png").status_code == 400
    assert post(b"\x00" * (image_utils.MAX_BYTES + 10)).status_code == 400


def test_phone_rotation_tag_is_applied():
    img = Image.new("RGB", (300, 224), (10, 120, 30)); exif = Image.Exif(); exif[0x0112] = 6
    buf = io.BytesIO(); img.save(buf, "JPEG", exif=exif)
    assert image_utils.open_image(buf.getvalue()).size == (224, 300)


def test_response_has_the_fields_the_app_needs():
    body = post(png(np.random.RandomState(1).randint(0, 256, (300, 300, 3)))).json()
    assert set(body) == {"status", "message", "is_blurry", "crop", "disease", "is_healthy", "is_pest", "part",
                         "confidence", "alternatives", "solution"}


def test_confident_disease_shows_review_note_and_no_spray_names(monkeypatch):
    i = index_of("Tomato", "Early blight"); fake_probs(monkeypatch, **{str(i): 0.92})
    body = post(png(np.full((300, 300, 3), 120))).json()
    assert body["status"] == "ok" and body["crop"] == "Tomato" and body["disease"] == "Early blight"
    s = body["solution"]
    assert s["kind"] == "disease" and s["symptoms"] and s["review_note"] and s["spray_note"]
    assert "pesticide" not in json.dumps(s).lower() or "No verified spray" in s["spray_note"]


def test_insect_pest_gets_no_disease_advice(monkeypatch):
    i = index_of("Rice", "Leaf folder"); fake_probs(monkeypatch, **{str(i): 0.9})
    body = post(png(np.full((300, 300, 3), 120))).json()
    assert body["is_pest"] and body["solution"]["kind"] == "pest" and "symptoms" not in body["solution"]


def test_class_without_approved_solution_says_so(monkeypatch):
    i = index_of("Tomato", "Late blight"); fake_probs(monkeypatch, **{str(i): 0.9})
    body = post(png(np.full((300, 300, 3), 120))).json()
    assert body["status"] == "ok" and body["solution"]["kind"] == "none"


def test_healthy_needs_more_proof_than_a_disease(monkeypatch):
    i = index_of("Tomato", "Healthy")
    fake_probs(monkeypatch, **{str(i): 0.65}); assert post(png(np.full((300, 300, 3), 120))).json()["status"] == "not_confident"
    fake_probs(monkeypatch, **{str(i): 0.85}); body = post(png(np.full((300, 300, 3), 120))).json()
    assert body["status"] == "ok" and body["is_healthy"] and body["solution"]["kind"] == "healthy"


def test_two_close_guesses_are_not_confident(monkeypatch):
    a, b = index_of("Tomato", "Early blight"), index_of("Potato", "Early blight")
    fake_probs(monkeypatch, **{str(a): 0.50, str(b): 0.45})
    body = post(png(np.full((300, 300, 3), 120))).json()
    assert body["status"] == "not_confident" and len(body["alternatives"]) == 3


def test_the_answer_says_if_the_photo_is_a_leaf_a_root_or_an_insect(monkeypatch):
    for crop, disease, part in [("Tomato", "Early blight", "leaf"), ("Rice", "Leaf folder", "insect"),
                                ("Turmeric", "Rhizome disease (root)", "rhizome")]:
        fake_probs(monkeypatch, **{str(index_of(crop, disease)): 0.9})
        body = post(png(np.full((300, 300, 3), 120))).json()
        assert body["status"] == "ok" and body["part"] == part, (crop, disease)
