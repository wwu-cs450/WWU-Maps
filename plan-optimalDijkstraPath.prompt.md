# Plan: Show the Optimal Dijkstra Path with GeoJSON-Compatible Mock Data

## Recommendation / TL;DR
Implement one route state layer and one GeoJSON-compatible route model, then connect the mock Dijkstra repository to `MapPage`. Dijkstra returns only the single lowest-cost path; alternate candidate paths are neither returned nor displayed. Existing graph edges remain weighted. Replace graph-only pixel/Offset coordinates with WGS84 `LatLng` locations, retain building/floor metadata, and convert the optimal `nodeIds` sequence into ordered geographic line segments for `flutter_map`. The mock graph will use bundled KRH-CSP geometry. Floor selection is out of scope; routing output will be filtered to the currently displayed floor.

## Steps
1. Normalize graph nodes to `LatLng` plus building/floor metadata. Remove the entrance-only GPS/pixel split and validate all locations and positive finite edge weights.
2. Keep the existing Dijkstra API and `PathResult`. Return one `nodeIds` sequence and one `totalDistance` only. The implementation may use a priority queue, but must not expose alternate routes. Preserve missing/unreachable handling.
3. Replace the Science Center synthetic coordinates or supplement it with mock nodes positioned in real KRH-CSP GeoJSON units. Use room, hallway/corridor, stair, and elevator node types as needed for the demo.
4. Add display-ready route points derived from the single optimal node sequence, grouped or annotated by building/floor.
5. Add one path state/Cubit and repository provider. Provide mock start/end IDs for a same-floor demonstration.
6. Add a `ProposedPathLayer` that renders only segments for `MapPage`'s current building and floor. Render one blue polyline above `FloorPlanLayer` and below location markers.
7. Do not implement floor switching or floor-picker behavior. Cross-floor graph edges may be present, but only the current-floor segment should be drawn.

## Debug node overlay

- Add a single debug configuration variable, such as `showPathPlanningDebugNodes`, defaulting to `false`.
- Keep the variable compile-time safe for release builds, preferably using `kDebugMode` or an explicit `--dart-define=SHOW_PATH_PLANNING_DEBUG_NODES=true` feature flag rather than displaying nodes by default.
- When enabled, overlay every ingested graph node on the active floor in addition to the optimal path.
- Render each node with a stable marker and its `nodeId` text, including start, hallway, room, stairway, and entrance/exit nodes that belong to the current building/floor.
- Filter the debug overlay by the active building and floor so cross-floor nodes are not accidentally placed on the wrong plan.
- Visually distinguish the optimal path from debug markers: keep the blue proposed path primary and use non-production-only neutral/coded node markers.
- Include clear keys or semantics for debug markers so node ingestion can be verified by widget tests.
- Do not expose debug controls or overlays in normal production UI by default.

## Verification
1. Test that weighted Dijkstra chooses the lowest-cost path and returns exactly one route.
2. Test that same-floor mock route points render on the active floor.
3. Test that nodes/segments for another floor are filtered out.
4. Test missing, unreachable, and same-node cases produce no stale route.
5. Run formatting, `flutter analyze`, and `flutter test` in `app/`.
6. Verify the debug overlay is absent when the flag is false.
7. Verify every active-floor node has exactly one marker and readable ID when the flag is true.
8. Verify the optimal path remains unchanged and separate from the node markers.
9. Verify cross-floor nodes are not drawn on the current floor.

## Decisions
- Exactly one optimal path: no multi-path or candidate-path state.
- Weighted edges: used for Dijkstra cost and `totalDistance`.
- Floor selection: excluded and left for a separate task.
- Initial demo scope: current floor only, while the graph may model future cross-floor links.
