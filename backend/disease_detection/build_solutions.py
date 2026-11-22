"""
Builds data/solutions.json (what the app shows under "What should you do?") from the team's
Excel file. Run it again whenever the Excel file changes:

    python -m disease_detection.build_solutions

Rules (they follow the team's own review notes in the Excel file):
  * Only classes whose mapping row says "Exact match after formatting", or whose
    "Approved" cell has been changed to YES, get a solution. Everything else gets none.
  * Spray / pesticide advice is NEVER copied. It is marked PENDING in the Excel file. The app shows a
    "ask your local agriculture office" note instead.
  * Symptoms, causes and fertilizer text are still marked DRAFT (not validated by a crop expert),
    so every solution carries a review note that the app shows.
"""
import json
from pathlib import Path

import pandas as pd

from .labels import describe

HERE = Path(__file__).resolve().parent
EXCEL = HERE / "data" / "AgriGuide_Crops_Reviewed.xlsx"
CLASSES = HERE / "models" / "class_names_v3.json"
OUT = HERE / "data" / "solutions.json"

import re


def norm(text):
    text = re.sub(r"^\d+_", "", str(text).strip().lower())
    return " ".join(re.sub(r"[^a-z0-9]+", " ", text).split())


def main():
    classes = json.loads(CLASSES.read_text(encoding="utf-8"))
    solutions = pd.read_excel(EXCEL, sheet_name="Farmer_Solutions_Draft")
    mapping = pd.read_excel(EXCEL, sheet_name="Disease_Mapping_Review")
    solutions.columns = [c.strip() for c in solutions.columns]
    mapping.columns = [c.strip() for c in mapping.columns]
    approved_col = [c for c in mapping.columns if c.startswith("Approved")][0]

    lookup = {(str(r.Crops).strip().casefold(), str(r.Disease).strip().casefold()): r
              for r in solutions.itertuples(index=False)}

    out, report = {}, {"with_solution": 0, "no_solution": 0, "not_approved": 0, "pest": 0}
    for raw in classes:
        info = describe(raw)
        leaf = "healthy" if info["disease"] == "Healthy" and info["raw_leaf"].lower() == "wheat" else info["raw_leaf"]
        rows = mapping[(mapping["Detection_Crop"].astype(str).str.strip().str.casefold() == info["crop_key"].casefold())
                       & (mapping["Model_Disease_Label"].map(norm) == norm(leaf))]
        if len(rows) != 1:
            raise SystemExit(f"Could not match class '{raw}' to exactly one mapping row ({len(rows)} found).")
        row = rows.iloc[0]
        ok = str(row["Status"]).startswith("Exact") or str(row[approved_col]).strip().upper() == "YES"
        if info["is_pest"]:
            report["pest"] += 1
            continue
        if not ok:
            report["not_approved"] += 1
            continue
        record = lookup.get((str(row["Possible_Solution_Crop"]).strip().casefold(),
                             str(row["Possible_Solution_Disease"]).strip().casefold()))
        if record is None:
            report["no_solution"] += 1
            continue
        entry = {"healthy": info["is_healthy"]}
        if not info["is_healthy"]:
            entry.update({"symptoms": str(record.Symptoms).strip(),
                          "causes": str(record.Cause_or_Risk_Factors).strip(),
                          "fertilizer": str(record.Fertilizer_Management).strip()})
        out[raw] = entry
        report["with_solution"] += 1

    OUT.write_text(json.dumps(out, indent=1, ensure_ascii=False), encoding="utf-8")
    print("Saved", OUT)
    print(report, "of", len(classes), "classes")


if __name__ == "__main__":
    main()
