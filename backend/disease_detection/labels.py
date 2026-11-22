"""
Turns the model's raw class names (folder names from the training data, for example
"Banana dataset/Banana disease/cordana") into names a farmer can read.

Raw class names never change (the model outputs them in a fixed order). Only the display
names live here, so a wrong spelling can be fixed in one place.
"""
import re

# raw folder name -> (name shown to the farmer, crop name used in the solutions Excel file)
CROPS = {
    "Banana dataset": ("Banana", "Banana"),
    "Black Gram": ("Black gram", "Black Gram"),
    "Cotton_Original_Dataset": ("Cotton", "Cotton"),
    "Cucumber Leaf Disease": ("Cucumber", "Cucumber"),
    "Grapes Dataset": ("Grapes", "Grape"),
    "Maize disease": ("Maize", "Maize"),
    "PPLD": ("Tur (pigeon pea)", "Tur"),
    "Rice": ("Rice", "Rice"),
    "Sugarcane Leaf Disease Dataset": ("Sugarcane", "Sugarcane"),
    "Sunflower Leaf Original": ("Sunflower", "Sunflower"),
    "Tomato Disease": ("Tomato", "Tomato"),
    "Turmeric Plant Dataset": ("Turmeric", "Turmeric"),
    "Wheat Disease": ("Wheat", "Wheat"),
    "bajra": ("Bajra (pearl millet)", "Bajra"),
    "groundnut leaf dataset": ("Groundnut", "Groundnut"),
    "onion": ("Onion", "Onion"),
    "potato Detaset": ("Potato", "Potato"),
    "soyabean": ("Soybean", "Soybean"),
}

# raw disease name (last part of the class name) -> display name, where plain cleaning is not enough
DISEASE_NAMES = {
    "healthy": "Healthy", "healthy leaves": "Healthy", "healthy leaf": "Healthy",
    "healthy_soyabean": "Healthy", "healthy leaves ": "Healthy",
    "rhizome healthy root": "Healthy rhizome (root)",
    "rhizome disease root": "Rhizome disease (root)",
    "cordana": "Cordana leaf spot", "pestalotiopsis": "Pestalotiopsis leaf spot",
    "leaf crinckle": "Leaf crinkle",
    "leaf_yellow_curl_virus": "Yellow leaf curl virus", "mold_leaf": "Leaf mold",
    "septora_leaf_spot": "Septoria leaf spot", "leaf_late_blight": "Late blight",
    "sterilic_mosaic": "Sterility mosaic", "soyabean_frog_leaf_eye": "Frogeye leaf spot",
    "soyabean_spectoria_brown_spot": "Septoria brown spot",
    "stemphylium leaf blight and collectrichum leaf blight": "Stemphylium and Colletotrichum leaf blight",
    "drecro_exserohilum rostratum": "Exserohilum leaf spot (Exserohilum rostratum)",
    "pyrisp_ pyricularia sp": "Pyricularia leaf spot",
    "redrot": "Red rot", "yellow": "Yellow leaf",
    "gray_spot": "Gray leaf spot", "leaf_spot": "Leaf spot",
    "leaf spot (early and late)": "Leaf spot (early and late)",
    "04_leaf_sheath_blight": "Sheath blight",
}

# These classes are insects, not leaf diseases. The app shows the name but gives no spray advice.
PESTS = {"05_leaf_folder", "06_rice_skipper", "07_white_stem_borer", "08_yellow_stem_borer",
         "fall_armyworm", "leaf_webber"}

# "Wheat Disease/Wheat" is the healthy wheat folder (the team's own mapping sheet treats it as Healthy).
SPECIAL = {("Wheat Disease", "wheat"): "Healthy"}


def _plain(text):
    text = re.sub(r"^\d+_", "", text)           # 01_Bacterial_leaf_blight -> Bacterial_leaf_blight
    text = text.replace("_", " ").strip()
    text = " ".join(text.split())
    return text[:1].upper() + text[1:].lower() if text else text


def split_raw(raw):
    parts = raw.replace("\\", "/").split("/")
    leaf = parts[-1]
    if leaf.startswith("PESGL_"):                 # bajra: the class folder repeats its parent name
        leaf = leaf[len("PESGL_"):]
    return parts[0], leaf


def describe(raw):
    """Returns the readable names and flags for one raw class name."""
    folder, leaf = split_raw(raw)
    crop_show, crop_key = CROPS[folder]
    key = leaf.strip().lower()
    disease = SPECIAL.get((folder, key)) or DISEASE_NAMES.get(key) or _plain(leaf)
    return {
        "crop": crop_show,
        "crop_key": crop_key,
        "disease": disease,
        "is_healthy": disease.lower().startswith("healthy"),
        "is_pest": key in PESTS,
        "part": "insect" if key in PESTS else ("rhizome" if "rhizome" in key else "leaf"),
        "raw": raw,
        "raw_leaf": leaf,
    }
