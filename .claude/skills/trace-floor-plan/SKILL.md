---
name: trace-floor-plan
description: Turn a building floor plan image (a PNG, typically a blurry or badly upscaled export from AutoCAD) into a georeferenced GeoJSON floor the WWU Maps app can draw. Use when adding a new building or floor to the indoor map from an image of its floor plan.
---

# Trace a floor plan

This skill turns a floor plan image (a PNG with no coordinates) into `app/assets/maps/<BUILDING>/<BUILDING>_Floor<N>.geojson`. You describe the floor in a Python script in sheet pixels, check it against the image, place it on the map with control points, then export it once. This is how the KRH-CSP floors were made.

Read [docs/FLOOR_PLANS.md](../../../docs/FLOOR_PLANS.md) first. It defines the GeoJSON format the app reads (`level`, `unit`, `opening`, `area`) and how the app draws it.

## Ground rules

- **Export each floor once.** After the export, the GeoJSON is the source of truth and people edit it by hand. Never pass `--force` to overwrite an existing floor unless the user explicitly asks; it erases their edits.
- **Plan images live in the repository's top-level `reference/`** as `<BUILDING>_Floor<N>.png`. If the user gives you one somewhere else, copy it there.
- **Floor scripts live in `examples/`** as `<building>_floor<N>.py`, next to the KRH-CSP ones. Once exported, a script stays as another example; commit it with its GeoJSON.
- **Don't guess what the plan doesn't show.** Leave a room's `label` as `None` rather than invent a number, and tell the user what you left out.
- **A cut in the image is not a cut in the building.** Sheets often stop at a match line, or draw a link between buildings or wings faintly or not at all. If part of a floor looks cut off from the rest, check the other floors and ask the user before tracing it as separate. KRH-CSP floor 2 looked split between CSP and KRH, but the two are joined by a connector.

## Setup

```sh
python3 -m pip install -r .claude/skills/trace-floor-plan/requirements.txt
```

Below, `$SKILL` means `.claude/skills/trace-floor-plan`. The scripts find the repository root on their own, so they can be run from any folder.

## Files

| File | What it does |
| --- | --- |
| `scripts/render.py` | The floor data model (`Floor`, `Room`, `Frame` for rotated wings) and shape helpers (`rect`, `hdoor`, `vdoor`, `flight`). |
| `scripts/plan_image.py` | `PlanImage` snaps a rough wall position onto the line drawn in the image. `Tracer` collects rooms and finds door openings along their walls. |
| `scripts/preview.py` | Makes small views of the plan image, or of the trace blended over it, with a grid labelled in sheet pixels. |
| `scripts/export_geojson.py` | Fits the plan to the control points, standardises doors and writes the GeoJSON. |
| `scripts/paths.py` | Repository paths (`image_path`, `geojson_path`). |
| `examples/krh_csp_floor1.py` | **The template.** Snapped walls, a 45° wing, doors found in the image, room numbers from a list. Copy this one. |
| `examples/krh_csp_floor2.py` | Same style, another layout. |
| `examples/krh_csp_floor3.py` | Older style, traced by eye without snapping, with hand-drawn stair treads the app no longer needs. Don't copy it. |

## Workflow

### 1. Read the plan image

Plan images are around 10200 × 6600 px, far too big to look at whole. Use `preview.py`, which crops, scales down and draws a grid labelled in sheet pixels:

```sh
python3 $SKILL/scripts/preview.py reference/<BUILDING>_Floor<N>.png
python3 $SKILL/scripts/preview.py reference/<BUILDING>_Floor<N>.png --crop X0 Y0 X1 Y1
```

These write `<name>_plan_overview.png` (the whole building, grid every 500 px) and `<name>_plan_crop.png` (the region, grid every 100 px) into `$SKILL/out/`. Look at them with your image-reading tool.

From the overview, work out:
- which parts are square to the sheet and which wings are rotated, and by how much;
- the rough scale: a single door is about 0.9 m wide, a corridor about 2–3 m. KRH-CSP sheets were about 47–52 px per metre;
- what the line colours mean (on KRH-CSP, red was walls and blue was furniture, fixtures and outdoor features).

Then crop region by region (about 1000 × 1000 px each) to read wall positions off the grid.

### 2. Write the floor script

Copy `examples/krh_csp_floor1.py` to `examples/<building>_floor<N>.py`. Keep its imports, set `BUILDING`, `LEVEL` and `IMAGE = image_path(BUILDING, LEVEL)`, and replace everything else. Trace in this order:

1. Exterior walls, which form the `footprint`.
2. Corridor walls.
3. Rooms, as polygons that share the wall coordinates. Use `"stairs"` and `"elevator"` for those units. Corridors are not rooms; whatever no room covers is drawn as corridor.
4. Doors (see below).
5. Room labels, if the plan or a room list gives them.

**Room numbers from a list.** A room list such as `KRH-CSP_Rooms.csv` gives numbers but not positions. Match each number to a room by the number printed on the image, its neighbours' numbers, or its size and use. Collect them in a `LABELS = {room index: "number"}` table, as `krh_csp_floor1.py` does. Ask the user about numbers you can't place and about big rooms the image leaves unnumbered. On KRH-CSP floor 1, the user had to say that the large lecture hall jutting out to the south is 107.

Name every wall coordinate (`X0 = X(...)`, `HALL_N = Y(...)`) and build rooms from the names. Shared walls then line up exactly, which the app needs to draw them as one line.

**Snapping walls.** Positions read by eye are only good to about 10 px. Give each wall a rough position and let `PlanImage` move it onto the drawn line:

```python
image = PlanImage(IMAGE)
X, Y = image.x, image.y
X0 = X(2992, 3700, 4400)   # vertical wall near x=2992, looked for between y=3700 and 4400
TOP = Y(3677, 3050, 3550)  # horizontal wall near y=3677, looked for between x=3050 and 3550
```

Pick the search range on a stretch of the wall with no doors, door swings or labels across it. A wall that finds no line keeps its rough position and is reported as `walls with no line to snap to` when you preview or export. Fix every one of those, either with a better range or a better rough position.

**Rotated wings.** Give each wing that isn't square to the sheet its own `Frame(origin, angle_deg)`, with (u, v) along and across it. `Tracer(image, wing)` provides `t.wing_image.x` / `.y` to snap walls in that frame. Build that wing's rooms with `wing.rect(...)` or `wing(u, v)`.

**Doors.** Door swings and door tags in plan images hide many openings, so:
1. Add the doors you can see by hand to `t.doors`, with `hdoor`, `vdoor`, or a helper like `wdoor` for a wing.
2. Then call `t.find_doors()`, which adds the clean gaps it finds along room walls. Leave out false finds with `find_doors(skip=[(x, y), ...])`.

A door must lie on a wall of a room or of the footprint. The exporter redraws every door at 1.0 m, or 1.8 m when the gap in the image is at least 1.4 m, centred where it was found. So the door's position matters, not its exact width.

### 3. Check it against the image, and repeat

```sh
python3 $SKILL/scripts/preview.py $SKILL/examples/<building>_floor<N>.py
python3 $SKILL/scripts/preview.py $SKILL/examples/<building>_floor<N>.py --crop X0 Y0 X1 Y1
```

This blends the trace over the plan image. The trace has tan rooms, a pale corridor and a thick brown exterior; doors show as gaps in the outlines. Where the trace sits on the image's lines, they merge. Where it doesn't, the walls show doubled.

Go over the whole building in crops, not just the overview. For each region, check for:
- doubled walls, which mean a rough position was off or snapped to the wrong line;
- rooms that are missing or merged into one;
- doors that are missing, or that land on the wrong wall;
- rooms that overlap, or that leave gaps where there should be a shared wall;
- small diagonal corners, mostly where a wing meets the main block or a connector meets a wall. A short slanted wall is easy to miss and square off. On KRH-CSP floor 2, the connector's west wall turns diagonally into the main wing.

Fix the script and preview again until every region is clean.

### 4. Find the control points

The exporter places the plan using control points: three or more corners of the building on the sheet, each paired with the same corner's `(lat, lng)`.

1. Find the building's outline in OpenStreetMap. Search by name with Overpass, or ask the user for the way ID. Then fetch its corners:

   ```
   https://api.openstreetmap.org/api/0.6/way/<id>/full.json
   ```

   Its nodes have `lat` and `lon`. A building may be several ways; KRH-CSP was 141026343 and 141026336.
2. Match corners that are clearly the same point on both: outer corners of wings, the ends of long walls. Spread them over the whole building.
3. Leave out corners where OSM disagrees with the plan. On KRH-CSP, OSM's outline included a terrace.
4. Put the pairs in `CONTROL_POINTS = [((x, y), (lat, lng)), ...]`, using the named wall coordinates for `(x, y)`.

If a floor shares corners with a floor that's already exported, reuse that floor's `(lat, lng)` for those corners, so the floors line up with each other. Floors 1 and 2 of KRH-CSP did this with floor 3's points.

### 5. Export

```sh
python3 $SKILL/scripts/export_geojson.py $SKILL/examples/<building>_floor<N>.py
```

It first checks the shape. It refuses to export if the footprint crosses itself, or if a room reaches outside the footprint. That usually means a footprint point is in the wrong order or was snapped to the wrong wall.

It then prints the fit, for example `46.72 sheet px per metre, rotation 0.79 deg, worst control point off by 0.48 m`. Check that:
- the scale is believable;
- the worst control point is under about 1 m. More than that usually means one pair is matched to the wrong corner. Drop or fix it, then export again with `--force`; that is fine for a file you only just created.

### 6. Hook it into the app and report

1. Add the file under `assets:` in `app/pubspec.yaml`. Files are listed one by one.
2. Run `flutter test` in `app/`. `app/test/features/map/data/floor_plan_geojson_test.dart` checks exact unit and door counts for some floors, such as 52 units and 54 doors on KRH-CSP floor 3. If you change those counts on purpose, update the test too.
3. Tell the user what to check and what is missing: rooms without numbers, walls placed by eye, simplifications you made (such as a tiered hall drawn as one room), and the control point error. Suggest they look at the floor in the app or in QGIS against the map.

## Changing a floor that's already exported

Once a floor has been exported, the GeoJSON is the source of truth. Make later fixes in that file, not by exporting again. That includes new room numbers, moved walls, and door widths for floors exported before doors were standardised.

- **Check what is already there first.** For example, look at the units' `name`s before adding room numbers. KRH-CSP floor 3 already had them.
- **Load the JSON, change only the features you mean to change, and write it back in the file's own format.** KRH-CSP floor 3 is `json.dumps(data, indent=4)` with no trailing newline. Newer exports have one feature per line and a trailing newline. Look at the file before you write it, and keep the diff to the lines you changed.
- **Use the exporter's helpers on map coordinates with care.** `standard_doors` and its 3 px tolerances assume sheet pixels. To use it on an exported file, project the coordinates to local metres, scale them to about 50 units per metre, run it, then convert back. At 1 unit per metre the tolerances act as 3 m and it merges neighbouring doors.
- **Afterwards**, check that the feature count and the units' names are unchanged, unless you meant to change them, and run the app tests.

## Before you trust the tools on a new plan image

They were tuned on KRH-CSP's images:

- **Line detection.** `_ink` in `plan_image.py` counts a pixel as part of a line when any colour channel is below 165. A grey background, faint lines or dark hatching may need a different threshold. If many walls fail to snap, check this first: crop the image and compare.
- **Pixel tolerances** assume about 47–52 px per metre. They are `win` (how far `PlanImage.x`/`y` search, ±14 px), `lo`/`hi` in `PlanImage.gaps` (door gaps of 26–105 px), and the 3 px wall tolerances and door merging in `export_geojson.py`. Scale them for images at a very different resolution.
- **Only straight walls snap:** walls that run horizontally or vertically on the sheet, or in a rotated `Frame`. Place curved or slanted walls by eye, as polygon points.
- **Each floor's image has its own position and scale**, even within one building. Never reuse sheet coordinates between floors; reuse only the `(lat, lng)` of shared corners.
