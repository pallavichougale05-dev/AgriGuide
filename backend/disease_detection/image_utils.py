
"""Reading and checking the photo. Nothing here saves the image anywhere."""

import io

import numpy as np
from PIL import Image, ImageOps, UnidentifiedImageError

MAX_BYTES = 10 * 1024 * 1024
MIN_SIDE = 224
IMAGE_SIZE = (224, 224)

DARK_THRESHOLD = 35.0
BLUR_THRESHOLD = 80.0


class BadImage(Exception):
    """The file is not a usable image at all (wrong file, corrupted, too big)."""


def open_image(data: bytes) -> Image.Image:
    if not data:
        raise BadImage("The photo is empty.")

    if len(data) > MAX_BYTES:
        raise BadImage("The photo is too large. Please use a photo under 10 MB.")

    try:
        Image.open(io.BytesIO(data)).verify()

        image = Image.open(io.BytesIO(data))
        image = ImageOps.exif_transpose(image)

        return image.convert("RGB")

    except (UnidentifiedImageError, OSError, ValueError, SyntaxError):
        raise BadImage(
            "This file is not a valid photo. Please choose a JPG or PNG image."
        )


def quality(image: Image.Image):
    """
    Returns (problem_code, is_blurry).

    Rejects images that are too small, too dark, or too blurry.
    """

    width, height = image.size

    if width < MIN_SIDE or height < MIN_SIDE:
        return "too_small", False

    gray = np.asarray(image.convert("L"), dtype=np.float32)

    if float(gray.mean()) < DARK_THRESHOLD:
        return "too_dark", False

    lap = (
        -4 * gray[1:-1, 1:-1]
        + gray[:-2, 1:-1]
        + gray[2:, 1:-1]
        + gray[1:-1, :-2]
        + gray[1:-1, 2:]
    )

    is_blurry = bool(lap.var() < BLUR_THRESHOLD)

    if is_blurry:
        return "too_blurry", True

    return None, False


def to_model_input(image: Image.Image) -> np.ndarray:
    """
    Same preprocessing as the team's predict_disease.py:
    RGB, 224x224, bilinear, raw 0-255 values.
    Both models scale pixels internally.
    """

    resized = image.resize(
        IMAGE_SIZE,
        Image.Resampling.BILINEAR,
    )

    return np.expand_dims(
        np.asarray(resized, dtype=np.float32),
        axis=0,
    )
