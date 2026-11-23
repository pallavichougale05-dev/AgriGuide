"""Read and preprocess images for AgriGuide disease detection."""
import io
import numpy as np
from PIL import Image, ImageOps, UnidentifiedImageError

MAX_BYTES = 10 * 1024 * 1024
IMAGE_SIZE = (224, 224)


class BadImage(Exception):
    """The file is not a usable image."""


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
    Never reject an image based on blur, darkness, or dimensions.

    Returns:
        (None, is_blurry)
    """

    gray = np.asarray(image.convert("L"), dtype=np.float32)

    if gray.shape[0] < 3 or gray.shape[1] < 3:
        return None, True

    lap = (
        -4 * gray[1:-1, 1:-1]
        + gray[:-2, 1:-1]
        + gray[2:, 1:-1]
        + gray[1:-1, :-2]
        + gray[1:-1, 2:]
    )

    is_blurry = bool(lap.var() < 80.0)

    return None, is_blurry


def to_model_input(image: Image.Image) -> np.ndarray:
    """Resize an RGB image to the model's expected input dimensions."""

    resized = image.resize(
        IMAGE_SIZE,
        Image.Resampling.BILINEAR,
    )

    return np.expand_dims(
        np.asarray(resized, dtype=np.float32),
        axis=0,
    )
