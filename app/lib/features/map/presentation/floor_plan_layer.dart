import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:wwu_maps_app/features/map/domain/models/floor_plan.dart';
import 'package:wwu_maps_app/features/map/domain/models/floor_unit.dart';
import 'package:wwu_maps_app/features/map/presentation/helpers/local_centroid_calculator.dart';
import 'package:wwu_maps_app/features/map/presentation/helpers/local_metres.dart';
import 'package:wwu_maps_app/features/map/presentation/helpers/stair_treads.dart';

/// Draws a [FloorPlan] with corridor and unit fills, stair treads, and walls;
/// doors are represented by gaps in the walls.
class FloorPlanLayer extends StatelessWidget {
  const new({required this.plan, super.key});

  /// The plan to draw.
  final FloorPlan plan;

  // Indoor map palette
  static const _corridor = Color(0xFFF3EFE7);
  static const _roomFill = Color(0xFFDDD0B8);
  static const _roomStroke = Color(0xFFB0A082);
  static const _stairFill = Color(0xFFCDBFA4);
  static const _tread = Color(0xFF7D6D52);
  static const _exterior = Color(0xFF8C7C62);
  static const _label = Color(0xFF5C4E3A);

  // Line widths in screen pixels, so the plan reads the same at every zoom.
  static const _roomStrokeWidth = 1.0;
  static const _treadWidth = 0.75;
  static const _exteriorWidth = 2.5;

  /// How far (in metres) a door may sit from a wall and still count as being
  /// in it. Doors are traced exactly on the wall lines, so this only absorbs
  /// rounding.
  static const _doorTolerance = 0.05;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      PolygonLayer(
        key: ValueKey('floor-plan-${plan.building}-${plan.level}'),
        polygons: [
          Polygon(points: plan.outline, color: _corridor),
          for (final unit in plan.units)
            Polygon(
              points: unit.outline,
              color: _fillFor(unit.type),
              label: unit.name,
              labelPlacementCalculator: const LocalCentroidCalculator(),
              rotateLabel: true,
              labelStyle: const TextStyle(
                color: _label,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      PolylineLayer(
        polylines: [
          for (final unit in plan.units)
            if (unit.type == UnitType.stairs)
              for (final line in stairTreads(unit.outline, doors: plan.doors))
                _segment(line, _tread, _treadWidth),
          for (final unit in plan.units)
            for (final wall in wallSegments(unit.outline, plan.doors))
              _segment(wall, _roomStroke, _roomStrokeWidth),
          for (final wall in wallSegments(plan.outline, plan.doors))
            _segment(wall, _exterior, _exteriorWidth),
        ],
      ),
    ],
  );

  static Color _fillFor(UnitType type) => switch (type) {
    UnitType.room => _roomFill,
    UnitType.stairs || UnitType.elevator => _stairFill,
  };

  static Polyline<Object> _segment(
    FloorSegment segment,
    Color color,
    double width,
  ) => Polyline(
    points: [segment.$1, segment.$2],
    color: color,
    strokeWidth: width,
  );

  /// Returns [outline]'s wall segments, leaving gaps for [doors].
  @visibleForTesting
  static List<FloorSegment> wallSegments(
    List<LatLng> outline,
    List<FloorSegment> doors,
  ) {
    // Work in metres, so distances are isotropic.
    final frame = LocalMetres(outline.first);
    LatLng lerp(LatLng a, LatLng b, double t) => LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );

    final localDoors = [
      for (final (p, q) in doors) (frame.project(p), frame.project(q)),
    ];
    final walls = <FloorSegment>[];

    for (var i = 0; i < outline.length; i++) {
      final a = outline[i];
      final b = outline[(i + 1) % outline.length];
      final la = frame.project(a);
      final edge = frame.project(b) - la;
      final lengthSquared = edge.x * edge.x + edge.y * edge.y;
      if (lengthSquared == 0) {
        continue;
      }
      final length = math.sqrt(lengthSquared);

      // Each door on this wall, as a [start, end] fraction along it.
      final gaps = <(double, double)>[];
      for (final (p, q) in localDoors) {
        final dp = p - la;
        final dq = q - la;
        final offP = (edge.x * dp.y - edge.y * dp.x).abs() / length;
        final offQ = (edge.x * dq.y - edge.y * dq.x).abs() / length;
        if (offP > _doorTolerance || offQ > _doorTolerance) {
          continue;
        }
        final tp = (dp.x * edge.x + dp.y * edge.y) / lengthSquared;
        final tq = (dq.x * edge.x + dq.y * edge.y) / lengthSquared;
        final start = math.max(0.0, math.min(tp, tq));
        final end = math.min(1.0, math.max(tp, tq));
        if (end > start) {
          gaps.add((start, end));
        }
      }
      gaps.sort((x, y) => x.$1.compareTo(y.$1));

      var from = 0.0;
      for (final (start, end) in gaps) {
        if (start > from) {
          walls.add((lerp(a, b, from), lerp(a, b, start)));
        }
        from = math.max(from, end);
      }
      if (from < 1) {
        walls.add((lerp(a, b, from), b));
      }
    }
    return walls;
  }
}
