"""Paths for the floor plan scripts, found from the repository root.

The root is the nearest folder above this file that has a `.git`, so the
scripts keep working wherever the skill folder is moved.
"""

from __future__ import annotations

import os


def _find_repo() -> str:
    here = os.path.dirname(os.path.abspath(__file__))
    folder = here
    while True:
        if os.path.exists(os.path.join(folder, ".git")):
            return folder
        parent = os.path.dirname(folder)
        if parent == folder:
            raise RuntimeError(f"no .git found above {here}")
        folder = parent


REPO = _find_repo()

# Where finished previews go (not committed).
OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "out")


def repo_path(*parts: str) -> str:
    """A path inside the repository, e.g. repo_path("reference", "X_Floor1.png")."""
    return os.path.join(REPO, *parts)


def image_path(building: str, level: int) -> str:
    """The plan image for a floor: reference/<BUILDING>_Floor<N>.png."""
    return repo_path("reference", f"{building}_Floor{level}.png")


def geojson_path(building: str, level: int) -> str:
    """Where the app reads a floor: app/assets/maps/<B>/<B>_Floor<N>.geojson."""
    return repo_path("app", "assets", "maps", building, f"{building}_Floor{level}.geojson")
