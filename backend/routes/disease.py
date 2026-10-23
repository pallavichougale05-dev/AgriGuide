"""
Disease Detection API
=====================

This file defines the FastAPI endpoint used by the Flutter
Disease Detection screen.

IMPORTANT:
------------
The actual disease detection ML model is NOT trained yet.

Therefore, this API currently handles only the IMAGE UPLOAD
part of the workflow.

Current workflow:

Flutter
   ↓
Select / Capture crop image
   ↓
POST image to /disease/detect
   ↓
FastAPI receives image
   ↓
[ML MODEL WILL BE CONNECTED HERE LATER]
   ↓
Disease name + confidence + solution

We intentionally DO NOT return fake disease predictions.
"""


# ============================================================
# IMPORTS
# ============================================================

from fastapi import APIRouter, File, UploadFile


# ============================================================
# CREATE ROUTER
# ============================================================

# APIRouter allows us to keep Disease APIs in a separate file.
#
# prefix="/disease" means every endpoint in this router starts
# with /disease.
#
# Example:
#     @router.post("/detect")
#
# becomes:
#     POST /disease/detect

router = APIRouter(
    prefix="/disease",
    tags=["Disease Detection"],
)


# ============================================================
# DISEASE DETECTION ENDPOINT
# ============================================================

@router.post("/detect")
async def detect_disease(
    image: UploadFile = File(...)
):
    """
    Receive a crop image from the Flutter application.

    Parameters
    ----------
    image:
        The image uploaded by the user.

    Returns
    -------
    dict:
        Information about the current model status.

    NOTE:
    -----
    The ML model is not trained yet, so this endpoint does NOT
    make up a disease prediction.
    """

    # --------------------------------------------------------
    # READ THE UPLOADED IMAGE
    # --------------------------------------------------------

    # Read the image bytes into memory.
    #
    # Later, these bytes can be passed to:
    # - OpenCV
    # - PIL
    # - a trained TensorFlow/PyTorch model
    # - another image-processing pipeline

    image_bytes = await image.read()


    # --------------------------------------------------------
    # BASIC VALIDATION
    # --------------------------------------------------------

    # Check whether an image was actually uploaded.

    if not image_bytes:
        return {
            "success": False,
            "message": "No image was uploaded."
        }


    # --------------------------------------------------------
    # TEMPORARY MODEL STATUS
    # --------------------------------------------------------

    # IMPORTANT:
    # We do NOT return something like:
    #
    # "Tomato Early Blight"
    #
    # because the actual ML model does not exist yet.
    #
    # This response simply confirms that FastAPI successfully
    # received the image.

    return {
        "success": True,
        "model_ready": False,
        "message": "Image received successfully. Disease detection model is not trained yet.",
        "filename": image.filename,
        "content_type": image.content_type,
        "image_size": len(image_bytes)
    }