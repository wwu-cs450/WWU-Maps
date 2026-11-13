"""Reads wall positions off a floor plan image.

The plan images are blurry, badly upscaled exports, so tracing them by eye is only good to
about ten pixels. A floor description (see examples/krh_csp_floor1.py) therefore gives
each wall an approximate position, and `PlanImage` moves it onto the drawn line:

    image = PlanImage("KRH-CSP_Floor1.png")
    x = image.x(3380, 3700, 3850)   # vertical wall near x=3380, seen between y=3700..3850
    y = image.y(4000, 4400, 4700)   # horizontal wall near y=4000, seen between x=4400..4700

`image.rotated(frame)` gives the same interface in a rotated wing's (u, v)
frame. `gaps` finds the door openings along a wall.

Needs numpy and Pillow:  python3 -m pip install numpy pillow
"""

from __future__ import annotations

import numpy as np
from PIL import Image

Image.MAX_IMAGE_PIXELS = None


def _ink(path: str) -> np.ndarray:
    """True where the plan has a drawn (red / blue / black) line."""
    im = Image.open(path).convert("RGBA")
    flat = Image.new("RGBA", im.size, (255, 255, 255, 255))
    flat.alpha_composite(im)
    rgb = np.asarray(flat.convert("RGB"))
    return (255 - rgb.min(axis=2).astype(np.int16)) > 90


class PlanImage:
    def __init__(self, path: str | None = None, ink: np.ndarray | None = None):
        self.ink = _ink(path) if ink is None else ink
        self.missed: list[str] = []  # walls that had no line to snap to

    def rotated(self, frame, size=(8000, 4000)) -> "PlanImage":
        """The image resampled into `frame` (a render.Frame), so that the
        frame's (u, v) are this image's (x, y)."""
        (ox, oy), U, V = frame.origin, frame.U, frame.V
        src = Image.fromarray((self.ink * 255).astype(np.uint8))
        out = src.transform(
            size, Image.AFFINE, (U[0], V[0], ox, U[1], V[1], oy), resample=Image.BILINEAR
        )
        return PlanImage(ink=np.asarray(out) > 110)

    # -- wall positions -------------------------------------------------------

    def _snap(self, profile: np.ndarray, guess: float, win: int, span: float, what: str) -> float:
        p = np.convolve(profile.astype(float), np.ones(5) / 5, mode="same")
        top = p.max()
        if top < 0.25 * span:
            self.missed.append(what)
            return float(guess)
        # Strongest line in the window; the one nearest the guess when tied.
        strong = np.flatnonzero(p >= 0.8 * top)
        i = int(strong[np.argmin(np.abs(strong - win))])
        lo = hi = i
        while lo > 0 and p[lo - 1] >= 0.5 * top:
            lo -= 1
        while hi < len(p) - 1 and p[hi + 1] >= 0.5 * top:
            hi += 1
        idx = np.arange(lo, hi + 1)
        centre = float((idx * p[lo : hi + 1]).sum() / p[lo : hi + 1].sum())
        return round(guess - win + centre)

    def x(self, x: float, y0: float, y1: float, win: int = 14) -> float:
        """Centre of the vertical wall near `x`, measured between y0 and y1."""
        x, y0, y1 = int(round(x)), int(min(y0, y1)), int(max(y0, y1))
        prof = self.ink[y0:y1, x - win : x + win + 1].sum(axis=0)
        return self._snap(prof, x, win, y1 - y0, f"x={x} y={y0}..{y1}")

    def y(self, y: float, x0: float, x1: float, win: int = 14) -> float:
        """Centre of the horizontal wall near `y`, measured between x0 and x1."""
        y, x0, x1 = int(round(y)), int(min(x0, x1)), int(max(x0, x1))
        prof = self.ink[y - win : y + win + 1, x0:x1].sum(axis=1)
        return self._snap(prof, y, win, x1 - x0, f"y={y} x={x0}..{x1}")

    # -- door openings --------------------------------------------------------

    def gaps(self, a, b, lo: float = 26, hi: float = 105, band: int = 5, trim: float = 2):
        """Openings in the wall drawn from `a` to `b` (axis-aligned in this
        image): stretches of `lo`..`hi` pixels with no line. Returns a list of
        (start, end) points along the wall."""
        (x0, y0), (x1, y1) = a, b
        horizontal = abs(x1 - x0) >= abs(y1 - y0)
        if horizontal:
            s, e, c = sorted((int(round(x0)), int(round(x1)))) + [int(round((y0 + y1) / 2))]
            wall = self.ink[c - band : c + band + 1, s:e].any(axis=0)
        else:
            s, e, c = sorted((int(round(y0)), int(round(y1)))) + [int(round((x0 + x1) / 2))]
            wall = self.ink[s:e, c - band : c + band + 1].any(axis=1)
        out = []
        n = len(wall)
        i = 0
        while i < n:
            if wall[i]:
                i += 1
                continue
            j = i
            while j < n and not wall[j]:
                j += 1
            # A gap must have wall (or the wall's end) on both sides.
            if lo <= j - i <= hi and i > trim and j < n - trim:
                p, q = s + i, s + j
                out.append(((p, c), (q, c)) if horizontal else ((c, p), (c, q)))
            i = j
        return out


class Tracer:
    """Collects the rooms of one floor and finds their doors on the image.

    Rooms are polygons in sheet pixels. Walls that are axis-aligned on the
    sheet, or in the rotated `wing` frame, are searched for door openings.
    """

    def __init__(self, image: PlanImage, wing=None):
        from render import Room  # local import: render needs Pillow fonts only

        self._Room = Room
        self.image = image
        self.wing = wing
        self.wing_image = image.rotated(wing) if wing is not None else None
        self.rooms = []
        self.doors = []

    def room(self, poly, kind="room", label=None):
        self.rooms.append(self._Room([(float(x), float(y)) for x, y in poly], kind, label))

    def door(self, a, b):
        self.doors.append((tuple(a), tuple(b)))

    def find_doors(self, skip=(), near: float = 30, rooms=None, **kw):
        """Add the openings found along every room wall (or only the walls of
        `rooms`). `skip` lists points (sheet pixels) where a detected opening
        is not a door."""
        found = []
        for room in self.rooms if rooms is None else rooms:
            pts = room.poly
            for a, b in zip(pts, pts[1:] + pts[:1]):
                if abs(a[0] - b[0]) < 1.5 or abs(a[1] - b[1]) < 1.5:
                    found += self.image.gaps(a, b, **kw)
                elif self.wing is not None:
                    la, lb = self.wing.local(a), self.wing.local(b)
                    if abs(la[0] - lb[0]) < 1.5 or abs(la[1] - lb[1]) < 1.5:
                        found += [
                            (self.wing(*p), self.wing(*q))
                            for p, q in self.wing_image.gaps(la, lb, **kw)
                        ]

        def mid(d):
            return ((d[0][0] + d[1][0]) / 2, (d[0][1] + d[1][1]) / 2)

        def close(p, q):
            return abs(p[0] - q[0]) < near and abs(p[1] - q[1]) < near

        for d in found:
            m = mid(d)
            if any(close(m, s) for s in skip) or any(close(m, mid(e)) for e in self.doors):
                continue
            self.doors.append(d)
