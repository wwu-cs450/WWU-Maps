# Indoor floor plans

Each floor of Kretschmar Hall / Chan Shun Pavilion (KRH-CSP) is one GeoJSON file with real latitude/longitude coordinates. The app draws these files as map layers (on top of the OpenStreetMap layer). **The GeoJSON files are the only source of truth**: to change a floor, edit its `.geojson`.

- Files: `app/assets/maps/KRH-CSP/KRH-CSP_Floor{1,2,3}.geojson`, each listed in `app/pubspec.yaml`.
- Why GeoJSON: the app can only display a picture of a floor. With geometry, it draws crisp walls at any zoom and knows where each room and door is, which room search and indoor routing will need. The floors also sit in the right place on the real map, and we can label the rooms directly with their room numbers and any other metadata needed for future features.

## How we got here

The GeoJSON was traced once from the plan images using Claude Code. After that, we edit the GeoJSON directly.

1. **Plan images.** We started from three PNG floor plans, now in `reference/KRH-CSP_Floor{1,2,3}.png`, each 10200 × 6600 px. They are blurry, badly upscaled and have no geographic coordinates. Each floor's image has its own position and scale.
2. **Tracing.** A Python script per floor (written by Claude) described the walls, rooms, doors and stairs in pixels on the image.
3. **Export.** A script placed each traced floor on the map (see below) and wrote the GeoJSON. It also redrew every door at a standard width (1.0 m, or 1.8 m for double doors), because door swings and tags blur the openings in the images.
4. **Hand edits.** From then on, every change goes into the GeoJSON directly.

### Placing the plans on the map

Each floor was lined up with the building outlines in OpenStreetMap. The fit uses only scale, rotation and offset, so the plan's shape is not distorted.

- **Control points:** corners of the plan, matched to corners of the OSM outlines [way 141026343](https://www.openstreetmap.org/way/141026343) (Kretschmar Hall) and [way 141026336](https://www.openstreetmap.org/way/141026336) (Chan Shun Pavilion). The images differ in position and scale, so each floor has its own control points.
- **Transform:** a similarity transform (uniform scale, rotation and offset) fitted to the control points. The fit was done in Web Mercator, the projection the map tiles use. Web Mercator keeps angles, so walls that meet at right angles still do on the map.
- **Result:** WGS84 coordinates in the standard GeoJSON order, `[longitude, latitude]`, rounded to 8 decimals (about 1 mm). The floors line up with the OSM outlines and with each other. The app does not transform coordinates when it runs.

Everything that we figured out from trial and error in the process of getting Claude Code to convert PNG floor plans to GeoJSON is packaged as the [`trace-floor-plan`](../.claude/skills/trace-floor-plan/SKILL.md) skill in `.claude/skills/`. The KRH-CSP floor scripts are kept in its `examples/` folder only as examples: exporting them again would overwrite every hand edit.

## The file format

Each file holds one floor as a GeoJSON `FeatureCollection`. Files are named `<BUILDING>_Floor<N>.geojson` and stored in `app/assets/maps/<BUILDING>/`. The schema is a cut-down version of Apple's [Indoor Mapping Data Format (IMDF)](https://register.apple.com/resources/imdf/).

Every feature has three properties: `feature_type`, `category` and `name`. On a unit, `name` is the label drawn on the map (for example a room number) or `null`; on the `level` it is the floor's name (e.g. `"Floor 3"`), which the app doesn't draw. A unit may also have an `alt_name`, a descriptive name such as `"CS Lab"` or `"Men's restroom"` (stored for later, e.g. search; the app doesn't use it yet).

| `feature_type` | Geometry | `category` | What it is |
| --- | --- | --- | --- |
| `level` | Polygon | `floor` | The floor's exterior walls. Also has `building` (e.g. `"KRH-CSP"`) and `ordinal` (the floor number). Exactly 1 per floor (file). |
| `unit` | Polygon | `room`, `stairs`, `elevator` | One enclosed space |
| `opening` | LineString (2 points) | `door` | A door |

Example door:

```json
{
  "type": "Feature",
  "properties": { "feature_type": "opening", "category": "door", "name": null },
  "geometry": {
    "type": "LineString",
    "coordinates": [[-118.39098785, 46.04608927], [-118.39098802, 46.04609825]]
  }
}
```

Decisions behind the format:

- **Corridors are not features.** Any part of the `level` polygon that no `unit` covers is drawn as corridor, so nobody has to trace hallway shapes.
- **Doors are lines on top of walls, not holes in polygons.** A door is a two-point line lying exactly on a unit's edge or the level's edge. The app cuts the wall where a door lies on it, so rooms stay simple closed polygons.
- **Stairs are only an outline of the stairwell.** The app works out where to draw the steps (see below).
- **Only the outer ring of a polygon is read.** Holes are ignored.
- **Unknown values are skipped.** A unit with an unknown `category`, or a feature with an unknown `feature_type`, is left out without an error. A file with no `level` feature fails to load.

## How the app draws it

The code follows the usual layers from [ARCHITECTURE.md](ARCHITECTURE.md):

| Layer | File | Job |
| --- | --- | --- |
| Domain | `domain/floor_plan_repository.dart`, `domain/models/floor_plan.dart`, `domain/models/floor_unit.dart` | `FloorPlanRepository.floorPlan(building, level)` returns a `FloorPlan`: the outline, units and doors. |
| Data | `data/asset_floor_plan_repository.dart` | Loads `assets/maps/<building>/<building>_Floor<level>.geojson` and parses it into a `FloorPlan`. |
| Presentation | `presentation/floor_plan_layer.dart` | `FloorPlanLayer`, a widget that draws a `FloorPlan` as a flutter_map layer. |

All paths are under `app/lib/features/map/`. For now `MapPage` always loads KRH-CSP floor 3, because there is no floor picker yet.

`FloorPlanLayer` draws, from bottom to top:

1. The `level` polygon, filled as corridor.
2. Units, filled by type, with their `name` as a label.
3. Stair treads, then the unit walls, then the exterior walls.

Line widths are in screen pixels, so the plan looks the same at every zoom. The colours are constants at the top of `floor_plan_layer.dart`.

Helpers it uses (the files are in `presentation/helpers/`):

- **`FloorPlanLayer.wallSegments`** splits each wall into pieces and leaves a gap where a door lies on it. A door counts as being on a wall if both of its ends are within 5 cm of the wall.
- **`stairTreads`** (`stair_treads.dart`) draws steps inside each `stairs` unit. It finds the largest rectangle that fits inside the stairwell with its sides along the walls, and draws a step every 0.3 m. Stairwells at least 2 m wide get two flights side by side; narrower ones get one flight. In a rectangular stairwell, a landing is left at the end nearest the doors; it grows to clear a door in a side wall, up to half the stairwell's length. In an irregular stairwell, the space left over beside the rectangle serves as the landing.
- **`LocalCentroidCalculator`** (`local_centroid_calculator.dart`) places room labels. flutter_map's built-in calculator loses precision on small polygons this far from (0, 0), and labels ended up metres to kilometres away from their rooms.
- **`LocalMetres`** (`local_metres.dart`) converts coordinates to flat metres around a nearby point, so the geometry code can measure distances and angles in metres.

## Editing a floor

Use [QGIS](https://qgis.org) or [geojson.io](https://geojson.io) to view and change geometry. Renaming rooms or editing metadata only needs a text editor: change the unit's `name`.

When you edit:

- Keep exactly one `level` feature per file.
- Put both ends of a door on the wall it opens. Use vertex and segment snapping so they land on the line. A door more than 5 cm off the wall won't cut a gap in it.
- Where rooms share a wall, snap their corners together, so the walls are drawn as a single line.
- `name` is a string (`"210"`, not `210`). Use `null` for an unlabelled room.
- Save in EPSG:4326 (WGS84). In QGIS: *Export → Save Features As…*, format GeoJSON, CRS EPSG:4326, and `COORDINATE_PRECISION` 8. That keeps the precision the same and the git diffs small.
- Run `flutter test` in `app/`. The tests parse every floor from its real asset file and check that every door cuts a gap in a wall, every stairwell gets steps, and every room label lands inside its room.

## Adding a building

A new building starts from its plan images, like KRH-CSP did. There are two ways to turn a plan image into GeoJSON, and both end in the same file format:

- **Trace by hand in QGIS.** Place the plan image on the map with QGIS's Georeferencer (*Layer → Georeferencer*, *Helmert* transform so the plan isn't distorted), then draw the features over it. Simplest for one or two buildings or irregular layouts.
- **Have an AI agent trace it with the Python tools,** the way KRH-CSP was made. In Claude Code, ask it to add the building's floor plans from the plan images and use the [`trace-floor-plan`](../.claude/skills/trace-floor-plan/SKILL.md) skill. With another tool, point it at that `SKILL.md`.

Either way, put the plan image in `reference/<BUILDING>_Floor<N>.png`, then:

1. Save the GeoJSON as `app/assets/maps/<BUILDING>/<BUILDING>_Floor<N>.geojson`.
2. Add the file to `assets:` in `app/pubspec.yaml`. Files are listed one by one, so a new file is not picked up until it is added there.
3. Load it with `floorPlan('<BUILDING>', N)`.
4. From then on, the GeoJSON is the source of truth. Edit it as described in [Editing a floor](#editing-a-floor).
