"""One-time export of a traced floor plan to georeferenced GeoJSON.

After the export, the GeoJSON file is the floor's source of truth: edit it in
QGIS (or any GeoJSON editor) and the app draws it directly. The Python tracing
is only the starting point, so this script refuses to overwrite an existing
file unless --force is given, to avoid wiping edits.

The floor module (e.g. examples/krh_csp_floor1.py) must define:
    BUILDING        building code, e.g. "KRH-CSP"
    LEVEL           floor number, e.g. 1
    floor           a render.Floor in sheet pixels
    CONTROL_POINTS  [((x, y), (lat, lng)), ...]: points on the sheet matched to
                    the same points on the map (building corners from
                    OpenStreetMap). Three or more, spread over the building.

Placing the plan on the map: a similarity transform (scale, rotation, offset)
is fitted to the control points by least squares. The fit is done in Web
Mercator, which is conformal, so the plan stays undistorted. The script prints
how far the worst control point ends up from its target; more than about a
metre usually means a mismatched point.

Feature schema (loosely after Apple's IMDF; every feature has `feature_type`,
`category` and `name`), documented in docs/FLOOR_PLANS.md:
    level    Polygon     the floor outline, also the corridor area;
                         extra properties `building` and `ordinal`
    unit     Polygon     category room | stairs | elevator
    opening  LineString  category door; drawn as a gap in the unit outlines

Usage:
    python3 .claude/skills/trace-floor-plan/scripts/export_geojson.py FLOOR_SCRIPT [--force]

Writes app/assets/maps/<BUILDING>/<BUILDING>_Floor<LEVEL>.geojson. Remember to
list the new file under `assets:` in app/pubspec.yaml.
"""

from __future__ import annotations

import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))

EARTH_R = 6378137.0

from paths import REPO, geojson_path  # noqa: E402


def load_floor_module(path: str):
    """Imports a floor description (a .py file) and reports walls that could
    not be snapped to the image."""
    import importlib.util

    from plan_image import PlanImage, Tracer

    name = os.path.splitext(os.path.basename(path))[0]
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    missing = [n for n in ("BUILDING", "LEVEL", "floor", "CONTROL_POINTS") if not hasattr(module, n)]
    if missing:
        sys.exit(f"{path} does not define {', '.join(missing)}")

    missed = []
    for value in vars(module).values():
        if isinstance(value, PlanImage):
            missed += value.missed
        elif isinstance(value, Tracer) and value.wing_image is not None:
            missed += value.wing_image.missed
    if missed:
        print("walls with no line to snap to:", sorted(set(missed)))
    return module


def mercator(lat: float, lng: float) -> tuple[float, float]:
    """(lat, lng) -> EPSG:3857 metres, y pointing north."""
    x = math.radians(lng) * EARTH_R
    y = math.log(math.tan(math.pi / 4 + math.radians(lat) / 2)) * EARTH_R
    return x, y


def unmercator(x: float, y: float) -> tuple[float, float]:
    lng = math.degrees(x / EARTH_R)
    lat = math.degrees(2 * math.atan(math.exp(y / EARTH_R)) - math.pi / 2)
    return lat, lng


def solve(m: list[list[float]], v: list[float]) -> list[float]:
    """Gaussian elimination with partial pivoting for a small square system."""
    n = len(v)
    m = [row[:] + [v[i]] for i, row in enumerate(m)]
    for i in range(n):
        p = max(range(i, n), key=lambda r: abs(m[r][i]))
        m[i], m[p] = m[p], m[i]
        for r in range(i + 1, n):
            f = m[r][i] / m[i][i]
            for c in range(i, n + 1):
                m[r][c] -= f * m[i][c]
    out = [0.0] * n
    for i in reversed(range(n)):
        out[i] = (m[i][n] - sum(m[i][c] * out[c] for c in range(i + 1, n))) / m[i][i]
    return out


def fit_similarity(pairs):
    """Least-squares (a, b, tx, ty) with  X = a*x + b*y + tx,  Y = b*x - a*y + ty
    (sheet y points down, Mercator y points up)."""
    rows, rhs = [], []
    for (x, y), (X, Y) in pairs:
        rows += [[x, y, 1, 0], [-y, x, 0, 1]]
        rhs += [X, Y]
    ata = [[sum(r[i] * r[j] for r in rows) for j in range(4)] for i in range(4)]
    atb = [sum(r[i] * b for r, b in zip(rows, rhs)) for i in range(4)]
    return solve(ata, atb)


# Door widths in metres. The images show door openings only roughly (swings and
# tags blur them), so every door is redrawn at a standard width, centred where
# it was found: wider openings are double doors.
SINGLE_DOOR = 1.0
DOUBLE_DOOR = 1.8
DOUBLE_FROM = 1.4  # openings at least this wide on the image are double doors
WALL_END = 0.15  # keep doors this far from the end of their wall


def standard_doors(floor, px_per_m: float):
    """`floor.doors` at the standard widths, each kept on its wall."""
    edges = []
    for poly in [floor.footprint] + [r.poly for r in floor.rooms]:
        edges += list(zip(poly, poly[1:] + poly[:1]))

    # One opening that a door tag on the image split in two becomes one door.
    doors = []
    for a, b in floor.doors:
        for i, (c, d) in enumerate(doors):
            u = ((b[0] - a[0]) / math.dist(a, b), (b[1] - a[1]) / math.dist(a, b))
            if abs(u[0] * (d[1] - c[1]) - u[1] * (d[0] - c[0])) > 0.1 * math.dist(c, d):
                continue  # not parallel
            if abs((c[0] - a[0]) * u[1] - (c[1] - a[1]) * u[0]) > 3:
                continue  # not on the same wall
            ts = sorted((x[0] - a[0]) * u[0] + (x[1] - a[1]) * u[1] for x in (a, b, c, d))
            span = sorted([(0.0, math.dist(a, b)), tuple(sorted(
                (x[0] - a[0]) * u[0] + (x[1] - a[1]) * u[1] for x in (c, d)))])
            if span[1][0] - span[0][1] < 0.1 * px_per_m:
                doors[i] = (
                    (a[0] + u[0] * ts[0], a[1] + u[1] * ts[0]),
                    (a[0] + u[0] * ts[-1], a[1] + u[1] * ts[-1]),
                )
                break
        else:
            doors.append((a, b))

    out = []
    for a, b in doors:
        mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
        found = math.dist(a, b) / px_per_m
        width = (DOUBLE_DOOR if found >= DOUBLE_FROM else SINGLE_DOOR) * px_per_m

        # The shortest wall the door lies on bounds where it can go.
        best = None
        for p, q in edges:
            length = math.dist(p, q)
            if length < 1e-6:
                continue
            ux, uy = (q[0] - p[0]) / length, (q[1] - p[1]) / length
            t = (mid[0] - p[0]) * ux + (mid[1] - p[1]) * uy
            off = abs((mid[0] - p[0]) * uy - (mid[1] - p[1]) * ux)
            if off < 3 and -1 <= t <= length + 1 and (best is None or length < best[0]):
                best = (length, p, (ux, uy), t)
        if best is None:
            sys.exit(f"door at {mid} is not on any wall")
        length, p, (ux, uy), t = best
        room = WALL_END * px_per_m
        width = min(width, length - 2 * room)
        t = min(max(t, room + width / 2), length - room - width / 2)
        out.append((
            (p[0] + ux * (t - width / 2), p[1] + uy * (t - width / 2)),
            (p[0] + ux * (t + width / 2), p[1] + uy * (t + width / 2)),
        ))
    return out


def _crosses(p, q, r, s) -> bool:
    """Whether segments pq and rs cross at a point inside both."""
    def side(a, b, c):
        return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])

    d1, d2 = side(r, s, p), side(r, s, q)
    d3, d4 = side(p, q, r), side(p, q, s)
    return d1 * d2 < 0 and d3 * d4 < 0


def _on_or_inside(pt, poly, tol: float = 1.0) -> bool:
    """Point in polygon, counting points within `tol` px of an edge as inside."""
    x, y = pt
    inside = False
    for (x0, y0), (x1, y1) in zip(poly, poly[1:] + poly[:1]):
        length = math.dist((x0, y0), (x1, y1))
        if length > 1e-9:
            t = ((x - x0) * (x1 - x0) + (y - y0) * (y1 - y0)) / length**2
            t = min(max(t, 0.0), 1.0)
            if math.dist(pt, (x0 + t * (x1 - x0), y0 + t * (y1 - y0))) <= tol:
                return True
        if (y0 > y) != (y1 > y) and x < x0 + (y - y0) * (x1 - x0) / (y1 - y0):
            inside = not inside
    return inside


def shape_problems(floor) -> list[str]:
    """Problems with the outline and rooms that would make a broken floor."""
    problems = []
    fp = floor.footprint
    edges = list(zip(fp, fp[1:] + fp[:1]))
    for i, (p, q) in enumerate(edges):
        for j in range(i + 2, len(edges)):
            if i == 0 and j == len(edges) - 1:
                continue  # neighbours through the closing point
            if _crosses(p, q, *edges[j]):
                problems.append(f"footprint edges {p}-{q} and {edges[j][0]}-{edges[j][1]} cross")
    for n, room in enumerate(floor.rooms):
        poly = room.poly
        mids = [((a[0] + b[0]) / 2, (a[1] + b[1]) / 2) for a, b in zip(poly, poly[1:] + poly[:1])]
        outside = [p for p in list(poly) + mids if not _on_or_inside(p, fp)]
        if outside:
            name = room.label or f"room {n}"
            problems.append(f"{name} ({room.kind}) reaches outside the footprint at {outside[0]}")
    return problems


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if len(args) != 1:
        sys.exit(__doc__)
    module = load_floor_module(args[0])
    BUILDING, LEVEL = module.BUILDING, module.LEVEL
    floor, CONTROL_POINTS = module.floor, module.CONTROL_POINTS

    out = geojson_path(BUILDING, LEVEL)
    OUT = os.path.relpath(out, REPO)
    if os.path.exists(out) and "--force" not in sys.argv:
        sys.exit(f"{OUT} already exists and may have been edited; pass --force to overwrite it.")
    os.makedirs(os.path.dirname(out), exist_ok=True)

    problems = shape_problems(floor)
    if problems:
        sys.exit("not exported, the floor's shape is broken:\n  " + "\n  ".join(problems))

    pairs = [(sheet, mercator(*ll)) for sheet, ll in CONTROL_POINTS]
    a, b, tx, ty = fit_similarity(pairs)

    def to_merc(p):
        x, y = p
        return a * x + b * y + tx, b * x - a * y + ty

    k = math.cos(math.radians(CONTROL_POINTS[0][1][0]))  # Mercator -> ground metres
    worst = max(math.dist(to_merc(s), m) * k for s, m in pairs)
    print(
        f"fit: {1 / (math.hypot(a, b) * k):.2f} sheet px per metre, "
        f"rotation {math.degrees(math.atan2(b, a)):.2f} deg, "
        f"worst control point off by {worst:.2f} m"
    )

    px_per_m = 1 / (math.hypot(a, b) * k)
    doors = standard_doors(floor, px_per_m)

    def lnglat(p) -> list[float]:
        lat, lng = unmercator(*to_merc(p))
        return [round(lng, 8), round(lat, 8)]

    def ring(points) -> list[list[float]]:
        coords = [lnglat(p) for p in points]
        # RFC 7946: exterior rings are counterclockwise.
        area = sum(
            x0 * y1 - x1 * y0 for (x0, y0), (x1, y1) in zip(coords, coords[1:] + coords[:1])
        )
        if area < 0:
            coords.reverse()
        return coords + coords[:1]

    def feature(feature_type, category, geometry, name=None, **extra):
        return {
            "type": "Feature",
            "properties": {"feature_type": feature_type, "category": category, "name": name, **extra},
            "geometry": geometry,
        }

    def polygon(points):
        return {"type": "Polygon", "coordinates": [ring(points)]}

    def line(a_, b_):
        return {"type": "LineString", "coordinates": [lnglat(a_), lnglat(b_)]}

    features = [
        feature(
            "level", "floor", polygon(floor.footprint), f"Floor {LEVEL}",
            building=BUILDING, ordinal=LEVEL,
        )
    ]
    features += [feature("unit", r.kind, polygon(r.poly), r.label) for r in floor.rooms]
    features += [feature("opening", "door", line(p, q)) for p, q in doors]
    # Stair treads aren't exported: the app draws them inside `stairs` units.

    # One feature per line keeps diffs readable when the file is edited.
    body = ",\n".join(json.dumps(f, separators=(",", ":")) for f in features)
    with open(out, "w", encoding="utf-8") as f:
        f.write('{"type":"FeatureCollection","features":[\n' + body + "\n]}\n")
    print(f"wrote {len(features)} features to {OUT}")


if __name__ == "__main__":
    main()
