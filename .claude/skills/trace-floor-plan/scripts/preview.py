"""Images for checking a trace against its plan image, small enough to look at.

Plan images are about 10200 x 6600 px, too big to view whole, so every image this
writes is cut to a region and scaled down, with a grid labelled in sheet
pixels so positions can be read straight off it.

Usage:
    preview.py FLOOR_SCRIPT [--crop X0 Y0 X1 Y1] [--grid STEP] [--out DIR]
    preview.py IMAGE.png     [--crop X0 Y0 X1 Y1] [--grid STEP] [--out DIR]

With a floor script, writes into DIR (default: the skill's out/ folder):
    <BUILDING>_Floor<N>_overview.png  the trace over the plan image, whole building
    <BUILDING>_Floor<N>_crop.png      the same for the --crop region only
Walls that don't sit on the image's lines show up doubled.

With a plan image (before any trace exists), writes <name>_plan_overview.png
and <name>_plan_crop.png of the image alone, for reading wall positions.

--grid sets the grid spacing in sheet px (default: 500 for the overview,
100 for a crop). Images are at most 1600 px wide.

Needs Pillow (and numpy for floors that snap to their image).
"""

from __future__ import annotations

import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(__file__))

from PIL import Image, ImageDraw, ImageFont  # noqa: E402

from paths import OUT_DIR  # noqa: E402

Image.MAX_IMAGE_PIXELS = None

MAX_WIDTH = 1600
GRID = (200, 120, 255)  # grid and labels: a violet not used by plans or trace


def flatten(path: str) -> Image.Image:
    """The image on a white background, as RGB."""
    im = Image.open(path).convert("RGBA")
    flat = Image.new("RGBA", im.size, (255, 255, 255, 255))
    flat.alpha_composite(im)
    return flat.convert("RGB")


def view(sheet: Image.Image, box, grid: int, out_path: str) -> None:
    """Saves `box` of `sheet`, scaled to MAX_WIDTH, with a grid every `grid`
    sheet px labelled in sheet coordinates."""
    x0, y0, x1, y1 = (int(v) for v in box)
    x0, y0 = max(0, x0), max(0, y0)
    x1, y1 = min(sheet.width, x1), min(sheet.height, y1)
    if x1 <= x0 or y1 <= y0:
        sys.exit(f"crop {box} is outside the {sheet.width} x {sheet.height} sheet")
    k = min(1.0, MAX_WIDTH / (x1 - x0))
    im = sheet.crop((x0, y0, x1, y1)).resize(
        (max(1, round((x1 - x0) * k)), max(1, round((y1 - y0) * k))), Image.LANCZOS
    )
    d = ImageDraw.Draw(im)
    font = ImageFont.load_default(size=12)
    for x in range(-(-x0 // grid) * grid, x1, grid):
        px = (x - x0) * k
        d.line([(px, 0), (px, im.height)], fill=GRID, width=1)
        d.text((px + 2, 2), str(x), fill=GRID, font=font)
    for y in range(-(-y0 // grid) * grid, y1, grid):
        py = (y - y0) * k
        d.line([(0, py), (im.width, py)], fill=GRID, width=1)
        d.text((2, py + 2), str(y), fill=GRID, font=font)
    im.save(out_path, optimize=True)
    print(f"wrote {out_path}  (sheet {x0},{y0} to {x1},{y1}, {k:.3f} image px per sheet px)")


def ink_bounds(sheet: Image.Image, margin: int = 150):
    """The box around everything drawn on the sheet."""
    box = sheet.convert("L").point(lambda v: 255 if v < 200 else 0).getbbox()
    if box is None:
        return (0, 0, sheet.width, sheet.height)
    return (box[0] - margin, box[1] - margin, box[2] + margin, box[3] + margin)


def main() -> None:
    args = sys.argv[1:]

    def option(name, count):
        if name not in args:
            return None
        i = args.index(name)
        values = args[i + 1 : i + 1 + count]
        del args[i : i + 1 + count]
        if len(values) != count:
            sys.exit(__doc__)
        return values

    crop = option("--crop", 4)
    grid = option("--grid", 1)
    out_dir = (option("--out", 1) or [OUT_DIR])[0]
    if len(args) != 1:
        sys.exit(__doc__)
    target = args[0]
    os.makedirs(out_dir, exist_ok=True)

    if target.lower().endswith(".png"):
        sheet = flatten(target)
        base = os.path.join(out_dir, os.path.splitext(os.path.basename(target))[0] + "_plan")
        overview_box = ink_bounds(sheet)
    else:
        from export_geojson import load_floor_module
        from render import render

        module = load_floor_module(target)
        base = os.path.join(out_dir, f"{module.BUILDING}_Floor{module.LEVEL}")
        image_path = getattr(module, "IMAGE", None)
        image = flatten(image_path) if image_path else None
        size = image.size if image else (10200, 6600)

        with tempfile.TemporaryDirectory() as tmp:
            trace_path = os.path.join(tmp, "trace.png")
            render(module.floor, trace_path, size=size)
            trace = flatten(trace_path)
        sheet = Image.blend(image, trace, 0.5) if image else trace

        xs, ys = zip(*module.floor.footprint)
        overview_box = (min(xs) - 150, min(ys) - 150, max(xs) + 150, max(ys) + 150)

    view(sheet, overview_box, int(grid[0]) if grid else 500, base + "_overview.png")
    if crop:
        view(sheet, [float(v) for v in crop], int(grid[0]) if grid else 100, base + "_crop.png")


if __name__ == "__main__":
    main()
