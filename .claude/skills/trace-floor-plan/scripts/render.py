"""Shared renderer for the programmatic floor plans.

A floor is described as plain data (see examples/krh_csp_floor1.py): a building
footprint polygon, a list of rooms (polygons), door openings and stair treads.
This module holds that data model and its geometry helpers, and draws a floor
as a PNG for checking a trace against its image (see preview.py).

All coordinates are pixels on the full-size sheet (10200 x 6600 by default),
the same frame as the floor's plan image.

Only Pillow is needed:  python3 -m pip install pillow
"""

from __future__ import annotations

import math
import os
from dataclasses import dataclass, field

from PIL import Image, ImageDraw, ImageFont

Point = tuple[float, float]

# Palette, matched to the look of the in-app indoor map.
BACKGROUND = (255, 255, 255, 255)
CORRIDOR = (243, 239, 231)
ROOM_FILL = (221, 208, 184)
ROOM_STROKE = (176, 160, 130)
STAIR_FILL = (205, 191, 164)
ELEVATOR_FILL = (205, 191, 164)
TREAD = (150, 134, 106)
EXTERIOR = (140, 124, 98)
TERRACE_FILL = (236, 232, 224)
TERRACE_LINE = (205, 196, 180)
LABEL = (92, 78, 58)

ROOM_STROKE_W = 7
EXTERIOR_W = 16
TREAD_W = 4
DOOR_W = ROOM_STROKE_W + 6

FILLS = {
    "room": ROOM_FILL,
    "stairs": STAIR_FILL,
    "elevator": ELEVATOR_FILL,
}


@dataclass
class Room:
    poly: list[Point]
    kind: str = "room"  # room | stairs | elevator
    label: str | None = None


@dataclass
class Floor:
    footprint: list[Point]
    rooms: list[Room] = field(default_factory=list)
    doors: list[tuple[Point, Point]] = field(default_factory=list)
    treads: list[tuple[Point, Point]] = field(default_factory=list)
    terraces: list[list[Point]] = field(default_factory=list)


# ---------------------------------------------------------------------------
# Geometry helpers used by the floor descriptions.


def rect(x0: float, y0: float, x1: float, y1: float) -> list[Point]:
    return [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]


class Frame:
    """A rotated local coordinate frame (for wings not aligned to the sheet).

    Local (u, v) maps to sheet (x, y) = origin + u * U + v * V, where U points
    along `angle_deg` (measured clockwise from +x, as on screen) and V is U
    turned 90 degrees clockwise.
    """

    def __init__(self, origin: Point, angle_deg: float):
        a = math.radians(angle_deg)
        self.origin = origin
        self.U = (math.cos(a), math.sin(a))
        self.V = (-math.sin(a), math.cos(a))

    def __call__(self, u: float, v: float) -> Point:
        ox, oy = self.origin
        return (
            ox + u * self.U[0] + v * self.V[0],
            oy + u * self.U[1] + v * self.V[1],
        )

    def local(self, p: Point) -> Point:
        """Sheet (x, y) back to this frame's (u, v)."""
        x, y = p[0] - self.origin[0], p[1] - self.origin[1]
        return (x * self.U[0] + y * self.U[1], x * self.V[0] + y * self.V[1])

    def rect(self, u0, v0, u1, v1) -> list[Point]:
        return [self(u0, v0), self(u1, v0), self(u1, v1), self(u0, v1)]

    def u_at_y(self, v: float, y: float) -> float:
        """The u where the local line v = const crosses sheet row y."""
        oy = self.origin[1]
        return (y - oy - v * self.V[1]) / self.U[1]

    def u_at_x(self, v: float, x: float) -> float:
        """The u where the local line v = const crosses sheet column x."""
        ox = self.origin[0]
        return (x - ox - v * self.V[0]) / self.U[0]


def flight(a: Point, b: Point, c: Point, d: Point, n: int):
    """Tread lines for one stair flight.

    The flight is the quad a-b-c-d; the first tread runs a->b, the last d->c,
    and `n` treads are spaced evenly between them (outline included).
    """
    lines = [(a, b), (b, c), (c, d), (d, a)]
    for i in range(1, n):
        t = i / n
        p = (a[0] + (d[0] - a[0]) * t, a[1] + (d[1] - a[1]) * t)
        q = (b[0] + (c[0] - b[0]) * t, b[1] + (c[1] - b[1]) * t)
        lines.append((p, q))
    return lines


def hdoor(y: float, x0: float, x1: float):
    return ((x0, y), (x1, y))


def vdoor(x: float, y0: float, y1: float):
    return ((x, y0), (x, y1))


# ---------------------------------------------------------------------------
# Rendering.


def _font(size: int) -> ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "C:/Windows/Fonts/arialbd.ttf",
    ]
    for path in candidates:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default(size=size)


def _centroid(poly: list[Point]) -> Point:
    # Area-weighted polygon centroid.
    a = cx = cy = 0.0
    for (x0, y0), (x1, y1) in zip(poly, poly[1:] + poly[:1]):
        cross = x0 * y1 - x1 * y0
        a += cross
        cx += (x0 + x1) * cross
        cy += (y0 + y1) * cross
    if abs(a) < 1e-9:
        xs, ys = zip(*poly)
        return (sum(xs) / len(xs), sum(ys) / len(ys))
    return (cx / (3 * a), cy / (3 * a))


def render(
    floor: Floor,
    out_path: str,
    size: tuple[int, int] = (10200, 6600),
    scale: int = 2,
    margin: int = 120,
) -> None:
    """Draw `floor` and save it as an RGBA PNG of `size` pixels.

    Only the area around the building is drawn (supersampled by `scale` for
    smooth edges); the rest of the sheet is plain background.
    """
    pts = list(floor.footprint)
    for t in floor.terraces:
        pts += t
    xs, ys = zip(*pts)
    bx0 = max(0, int(min(xs)) - margin)
    by0 = max(0, int(min(ys)) - margin)
    bx1 = min(size[0], int(max(xs)) + margin)
    by1 = min(size[1], int(max(ys)) + margin)

    s = scale
    W, H = (bx1 - bx0) * s, (by1 - by0) * s
    img = Image.new("RGB", (W, H), BACKGROUND[:3])
    d = ImageDraw.Draw(img)

    def P(p: Point) -> tuple[float, float]:
        return ((p[0] - bx0) * s, (p[1] - by0) * s)

    def poly(points):
        return [P(p) for p in points]

    def outline(points, color, width):
        pp = poly(points)
        d.line(pp + pp[:1], fill=color, width=int(width * s), joint="curve")

    # Terraces (outdoor decks) underneath everything, with a paving grid.
    for t in floor.terraces:
        d.polygon(poly(t), fill=TERRACE_FILL)
        txs, tys = zip(*t)
        step = 50
        mask = Image.new("L", (W, H), 0)
        ImageDraw.Draw(mask).polygon(poly(t), fill=255)
        grid = Image.new("RGB", (W, H), TERRACE_FILL)
        g = ImageDraw.Draw(grid)
        for x in range(int(min(txs)), int(max(txs)) + 1, step):
            g.line([P((x, min(tys))), P((x, max(tys)))], fill=TERRACE_LINE, width=3 * s)
        for y in range(int(min(tys)), int(max(tys)) + 1, step):
            g.line([P((min(txs), y)), P((max(txs), y))], fill=TERRACE_LINE, width=3 * s)
        img.paste(grid, (0, 0), mask)
        outline(t, TERRACE_LINE, 6)

    # Building floor (what is left over becomes corridor / lobby).
    d.polygon(poly(floor.footprint), fill=CORRIDOR)

    for room in floor.rooms:
        d.polygon(poly(room.poly), fill=FILLS[room.kind])
    for room in floor.rooms:
        outline(room.poly, ROOM_STROKE, ROOM_STROKE_W)

    for a, b in floor.treads:
        d.line([P(a), P(b)], fill=TREAD, width=TREAD_W * s)

    # Door openings: a light gap in the room outline.
    for a, b in floor.doors:
        d.line([P(a), P(b)], fill=CORRIDOR, width=DOOR_W * s)

    outline(floor.footprint, EXTERIOR, EXTERIOR_W)

    font = _font(40 * s)
    for room in floor.rooms:
        if not room.label:
            continue
        cx, cy = P(_centroid(room.poly))
        d.text((cx, cy), room.label, fill=LABEL, font=font, anchor="mm")

    img = img.resize((bx1 - bx0, by1 - by0), Image.LANCZOS)
    sheet = Image.new("RGBA", size, BACKGROUND)
    sheet.paste(img, (bx0, by0))
    sheet.save(out_path, optimize=True)


def _hex(color) -> str:
    return "#{:02x}{:02x}{:02x}".format(*color[:3])


def render_svg(floor: Floor, out_path: str, size: tuple[int, int] = (10200, 6600)) -> None:
    """Write `floor` as an SVG in the same sheet coordinates as `render`.

    Each room is its own <polygon> with data-kind (and data-label when set),
    so the app can style or highlight rooms individually.
    """
    from xml.sax.saxutils import escape, quoteattr

    def pts(points) -> str:
        return " ".join(f"{x:.1f},{y:.1f}" for x, y in points)

    def seg(a, b, color, width) -> str:
        return (
            f'<line x1="{a[0]:.1f}" y1="{a[1]:.1f}" x2="{b[0]:.1f}" y2="{b[1]:.1f}" '
            f'stroke="{_hex(color)}" stroke-width="{width}"/>'
        )

    w, h = size
    out = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
        f'viewBox="0 0 {w} {h}">',
        f'<rect width="{w}" height="{h}" fill="{_hex(BACKGROUND)}"/>',
    ]

    # Terraces with a paving grid clipped to their outline.
    for i, t in enumerate(floor.terraces):
        txs, tys = zip(*t)
        out.append(f'<clipPath id="terrace-{i}"><polygon points="{pts(t)}"/></clipPath>')
        out.append(f'<g id="terrace-{i}-fill">')
        out.append(f'<polygon points="{pts(t)}" fill="{_hex(TERRACE_FILL)}"/>')
        out.append(f'<g clip-path="url(#terrace-{i})">')
        for x in range(int(min(txs)), int(max(txs)) + 1, 50):
            out.append(seg((x, min(tys)), (x, max(tys)), TERRACE_LINE, 3))
        for y in range(int(min(tys)), int(max(tys)) + 1, 50):
            out.append(seg((min(txs), y), (max(txs), y), TERRACE_LINE, 3))
        out.append("</g>")
        out.append(
            f'<polygon points="{pts(t)}" fill="none" stroke="{_hex(TERRACE_LINE)}" '
            f'stroke-width="6" stroke-linejoin="round"/>'
        )
        out.append("</g>")

    out.append(f'<polygon id="footprint" points="{pts(floor.footprint)}" fill="{_hex(CORRIDOR)}"/>')

    out.append(
        f'<g id="rooms" stroke="{_hex(ROOM_STROKE)}" stroke-width="{ROOM_STROKE_W}" '
        f'stroke-linejoin="round">'
    )
    for i, room in enumerate(floor.rooms):
        attrs = f'id="room-{i}" data-kind="{room.kind}"'
        if room.label:
            attrs += f" data-label={quoteattr(room.label)}"
        out.append(f'<polygon {attrs} points="{pts(room.poly)}" fill="{_hex(FILLS[room.kind])}"/>')
    out.append("</g>")

    out.append(f'<g id="treads" stroke="{_hex(TREAD)}" stroke-width="{TREAD_W}">')
    for a, b in floor.treads:
        out.append(f'<line x1="{a[0]:.1f}" y1="{a[1]:.1f}" x2="{b[0]:.1f}" y2="{b[1]:.1f}"/>')
    out.append("</g>")

    out.append(f'<g id="doors" stroke="{_hex(CORRIDOR)}" stroke-width="{DOOR_W}">')
    for a, b in floor.doors:
        out.append(f'<line x1="{a[0]:.1f}" y1="{a[1]:.1f}" x2="{b[0]:.1f}" y2="{b[1]:.1f}"/>')
    out.append("</g>")

    out.append(
        f'<polygon id="exterior" points="{pts(floor.footprint)}" fill="none" '
        f'stroke="{_hex(EXTERIOR)}" stroke-width="{EXTERIOR_W}" stroke-linejoin="round"/>'
    )

    out.append(
        f'<g id="labels" fill="{_hex(LABEL)}" font-family="Arial, Helvetica, sans-serif" '
        f'font-weight="bold" font-size="40" text-anchor="middle" dominant-baseline="central">'
    )
    for room in floor.rooms:
        if room.label:
            cx, cy = _centroid(room.poly)
            out.append(f'<text x="{cx:.1f}" y="{cy:.1f}">{escape(room.label)}</text>')
    out.append("</g>")

    out.append("</svg>")
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
