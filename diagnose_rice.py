import json
import numpy as np
import tensorflow as tf
from pathlib import Path
from PIL import Image, ImageOps

base = Path("backend/disease_detection/models")
image_path = Path.home() / "Downloads" / "WhatsApp Image 2026-11-22 at 6.20.44 PM.jpeg"

labels = json.loads((base / "class_names_v3.json").read_text(encoding="utf-8"))

print("Loading MobileNetV2...")
mobilenet = tf.keras.models.load_model(
    base / "agri_mobilenetv2_weighted_best.keras",
    compile=False
)

print("Loading EfficientNetB0...")
efficientnet = tf.keras.models.load_model(
    base / "agri_efficientnetb0_v3_best.keras",
    compile=False
)

with Image.open(image_path) as img:
    img = ImageOps.exif_transpose(img).convert("RGB")
    img = img.resize((224, 224), Image.Resampling.BILINEAR)
    arr = np.asarray(img, dtype=np.float32)
    arr = np.expand_dims(arr, axis=0)

print("\nImage:", image_path.name)
print("Image tensor:", arr.shape)

def predict_top5(name, model):
    predictions = model.predict(arr, verbose=0)
    predictions = np.asarray(predictions).reshape(-1)

    print(f"\n{name} output count:", len(predictions))

    if len(predictions) != len(labels):
        print("ERROR: Output count does not match class-label count!")
        return None

    indices = np.argsort(predictions)[::-1][:5]

    print(f"\n{name} TOP 5:")
    for i in indices:
        print(f"{labels[i]} : {predictions[i]:.6f}")

    return predictions

mobile_probs = predict_top5("MobileNetV2", mobilenet)
efficient_probs = predict_top5("EfficientNetB0", efficientnet)

if mobile_probs is not None and efficient_probs is not None:
    combined = 0.40 * mobile_probs + 0.60 * efficient_probs
    indices = np.argsort(combined)[::-1][:5]

    print("\nWEIGHTED ENSEMBLE TOP 5:")
    for i in indices:
        print(f"{labels[i]} : {combined[i]:.6f}")
