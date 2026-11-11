import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:wwu_maps_app/features/map/domain/models/floor_plan.dart';
import 'package:wwu_maps_app/features/map/presentation/helpers/local_metres.dart';

/// Depth of one step, in metres.
const _treadDepth = 0.3;

/// Rectangles whose sides differ by less than this factor count as square,
/// so their long side says nothing about which way the stairs run.
const _squareAspect = 1.15;

/// Width of the gap between the two flights, as a share of the stairwell's
/// width.
const _wellFraction = 0.05;

/// Narrowest stairwell, in metres, that holds two flights side by side.
/// Anything narrower gets a single flight across its whole width.
const _minSwitchbackWidth = 2.0;

/// How close (in metres) points must be to count as the same wall. Stored
/// coordinates are rounded, so walls that should line up can be off by a
/// millimetre or so.
const _wallTolerance = 0.05;

/// Depth of the landing left at a stairwell's entrance, in metres, and the
/// most of the stairwell's length it may take.
const _entranceLanding = 1.5;
const _maxLandingFraction = 0.25;

/// The most of the stairwell's length a landing may take when it grows to
/// clear a door in a side wall.
const _maxDoorLandingFraction = 0.5;

/// How much bigger than the stairs' rectangle a stairwell must be to count
/// as irregular: its leftover part then serves as the landing.
const _irregularFraction = 1.05;

/// Shortest run of steps worth drawing, in metres.
const _minFlightLength = 0.6;

/// How far apart (in radians) two walls' directions may be and still count
/// as parallel or perpendicular.
const _wallAngleTolerance = 1 * math.pi / 180;

/// The tread lines for the stairwell bounded by [outline] (a closed ring;
/// the first point is not repeated), as pairs of points. [doors] are the
/// doors in the stairwell's walls, which shape the landing.
///
/// Draws two side-by-side flights with a narrow gap, or one full-width
/// flight when the stairwell is too narrow. Stairs fill the largest
/// wall-aligned rectangle inside the outline. Rectangular stairwells keep a
/// landing near their entrance doors; irregular stairwells use their
/// leftover area as a landing.
List<FloorSegment> stairTreads(
  List<LatLng> outline, {
  List<FloorSegment> doors = const [],
}) {
  if (outline.length < 3) {
    return const [];
  }

  final frame = LocalMetres(outline.first);
  final points = [for (final p in outline) frame.project(p)];

  final direction = _wallDirection(points);
  if (direction == null) {
    return const [];
  }
  var along = direction;
  var across = math.Point(-direction.y, direction.x);
  final inner = _largestInnerRectangle(points, along, across);
  if (inner == null) {
    return const [];
  }
  var (start, end, left, right) = inner;
  final innerLength = end - start;
  final innerWidth = right - left;
  final bool turn;
  if (math.max(innerLength, innerWidth) <
      _squareAspect * math.min(innerLength, innerWidth)) {
    // A square-ish rectangle has no clear long side. Run the flights toward
    // the rest of the stairwell instead (e.g. the passage the stairs lead
    // into), measured as how far the stairwell reaches past the rectangle.
    final (uMin, uMax) = _extent(points, along);
    final (vMin, vMax) = _extent(points, across);
    turn = (vMax - right) + (left - vMin) > (uMax - end) + (start - uMin);
  } else {
    turn = innerWidth > innerLength;
  }
  if (turn) {
    // Run the flights along the other side of the rectangle.
    (along, across) = (across, along);
    (start, end, left, right) = (left, right, start, end);
  }
  math.Point<double> at(double s, double t) => along * s + across * t;

  // Leave the landing at the entrance end of a rectangular stairwell.
  final irregular =
      _area(points).abs() > _irregularFraction * (end - start) * (right - left);
  // Each door in the stairwell's walls, as how far along the stairs its two
  // ends are.
  double alongOf(math.Point<double> p) => p.x * along.x + p.y * along.y;
  final entrances = [
    for (final (a, b) in doors)
      if (_onBoundary(frame.project(a), points) &&
          _onBoundary(frame.project(b), points))
        (alongOf(frame.project(a)), alongOf(frame.project(b))),
  ];
  if (!irregular && entrances.isNotEmpty) {
    final length = end - start;
    var landing = math.min(_entranceLanding, length * _maxLandingFraction);
    // Average position of the doors along the stairs.
    final entrance =
        entrances.map((d) => (d.$1 + d.$2) / 2).reduce((a, b) => a + b) /
        entrances.length;
    final atStart = entrance - start < end - entrance;
    // A door in a side wall opens onto the landing, so the landing must
    // reach past it rather than leave steps in the doorway.
    for (final (a, b) in entrances) {
      final reach = atStart ? math.max(a, b) - start : end - math.min(a, b);
      if (reach < length / 2) {
        landing = math.max(landing, reach);
      }
    }
    landing = math.min(landing, length * _maxDoorLandingFraction);
    if (atStart) {
      start += landing;
    } else {
      end -= landing;
    }
  }

  final length = end - start;
  final width = right - left;
  if (length < _minFlightLength) {
    return const [];
  }

  // Two flights side by side with a gap (the stairwell's well) between them,
  // or one flight if there is no room for two.
  final middle = (left + right) / 2;
  final gap = width * _wellFraction / 2;
  final flights = width < _minSwitchbackWidth
      ? [(left, right)]
      : [(left, middle - gap), (middle + gap, right)];

  final count = math.max(2, (length / _treadDepth).round());
  final stepLength = length / count;
  final drawn = <(math.Point<double>, math.Point<double>)>[
    for (final (side0, side1) in flights) ...[
      for (var i = 0; i <= count; i++)
        (at(start + stepLength * i, side0), at(start + stepLength * i, side1)),
      (at(start, side0), at(end, side0)),
      (at(start, side1), at(end, side1)),
    ],
  ];

  // The rectangle fits inside straight-walled stairwells, but a slanted wall
  // could cut into it: leave out any line that would cross the walls.
  bool within(math.Point<double> p) =>
      _inside(p, points) || _onBoundary(p, points);

  return [
    for (final (p, q) in drawn)
      if (within(p) && within(q)) (frame.unproject(p), frame.unproject(q)),
  ];
}

/// The signed area of [polygon] (shoelace formula).
double _area(List<math.Point<double>> polygon) {
  var twice = 0.0;
  for (var i = 0; i < polygon.length; i++) {
    final a = polygon[i];
    final b = polygon[(i + 1) % polygon.length];
    twice += a.x * b.y - b.x * a.y;
  }
  return twice / 2;
}

/// Whether [point] lies on one of [polygon]'s edges, within
/// [_wallTolerance].
bool _onBoundary(math.Point<double> point, List<math.Point<double>> polygon) {
  for (var i = 0; i < polygon.length; i++) {
    final a = polygon[i];
    final e = polygon[(i + 1) % polygon.length] - a;
    final lengthSquared = e.x * e.x + e.y * e.y;
    if (lengthSquared == 0) {
      continue;
    }
    final w = point - a;
    final t = (w.x * e.x + w.y * e.y) / lengthSquared;
    if (t < -1e-9 || t > 1 + 1e-9) {
      continue;
    }
    if ((w.x * e.y - w.y * e.x).abs() / math.sqrt(lengthSquared) <
        _wallTolerance) {
      return true;
    }
  }
  return false;
}

/// Finds the largest rectangle aligned to [u] and [v] inside [polygon].
(double, double, double, double)? _largestInnerRectangle(
  List<math.Point<double>> polygon,
  math.Point<double> u,
  math.Point<double> v,
) {
  List<double> distinct(Iterable<double> values) {
    final sorted = values.toList()..sort();
    return [
      for (var i = 0; i < sorted.length; i++)
        if (i == 0 || sorted[i] - sorted[i - 1] > _wallTolerance) sorted[i],
    ];
  }

  double dot(math.Point<double> p, math.Point<double> axis) =>
      p.x * axis.x + p.y * axis.y;
  final us = distinct(polygon.map((p) => dot(p, u)));
  final vs = distinct(polygon.map((p) => dot(p, v)));

  // inside[i][k]: whether the cell between us[i]..us[i+1] and
  // vs[k]..vs[k+1] is inside the polygon (tested at its centre).
  final inside = [
    for (var i = 0; i + 1 < us.length; i++)
      [
        for (var k = 0; k + 1 < vs.length; k++)
          _inside(
            u * ((us[i] + us[i + 1]) / 2) + v * ((vs[k] + vs[k + 1]) / 2),
            polygon,
          ),
      ],
  ];

  (double, double, double, double)? best;
  var bestArea = 0.0;
  for (var i0 = 0; i0 < inside.length; i0++) {
    for (var k0 = 0; k0 < vs.length - 1; k0++) {
      // Grow to the right one column at a time, keeping the tallest run of
      // inside cells starting at k0 that every column so far shares.
      var k1Limit = vs.length - 1;
      for (var i1 = i0; i1 < inside.length && k1Limit > k0; i1++) {
        var k = k0;
        while (k < k1Limit && inside[i1][k]) {
          k++;
        }
        k1Limit = k;
        if (k1Limit == k0) {
          break;
        }
        final area = (us[i1 + 1] - us[i0]) * (vs[k1Limit] - vs[k0]);
        if (area > bestArea) {
          bestArea = area;
          best = (us[i0], us[i1 + 1], vs[k0], vs[k1Limit]);
        }
      }
    }
  }
  return best;
}

/// Returns the stairwell's dominant wall direction as a unit vector.
math.Point<double>? _wallDirection(List<math.Point<double>> points) {
  // Each edge's direction, folded into [0, 90 degrees), and length.
  final edges = <(double, double)>[];
  for (var i = 0; i < points.length; i++) {
    final edge = points[(i + 1) % points.length] - points[i];
    final length = edge.magnitude;
    if (length > 0) {
      edges.add((math.atan2(edge.y, edge.x) % (math.pi / 2), length));
    }
  }

  double? best;
  var bestLength = 0.0;
  for (final (angle, _) in edges) {
    var length = 0.0;
    for (final (other, otherLength) in edges) {
      // Distance between the folded angles, wrapping around at 90 degrees.
      final difference = (angle - other).abs() % (math.pi / 2);
      if (math.min(difference, math.pi / 2 - difference) <
          _wallAngleTolerance) {
        length += otherLength;
      }
    }
    if (length > bestLength) {
      bestLength = length;
      best = angle;
    }
  }
  return best == null ? null : math.Point(math.cos(best), math.sin(best));
}

/// Returns the lowest and highest values of [points] projected onto [axis].
(double, double) _extent(
  List<math.Point<double>> points,
  math.Point<double> axis,
) {
  var low = double.infinity;
  var high = double.negativeInfinity;
  for (final p in points) {
    final d = p.x * axis.x + p.y * axis.y;
    low = math.min(low, d);
    high = math.max(high, d);
  }
  return (low, high);
}

/// Even-odd point-in-polygon test; pair with [_onBoundary] for boundaries.
bool _inside(math.Point<double> point, List<math.Point<double>> polygon) {
  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final a = polygon[i];
    final b = polygon[j];
    if ((a.y > point.y) != (b.y > point.y) &&
        point.x < a.x + (point.y - a.y) * (b.x - a.x) / (b.y - a.y)) {
      inside = !inside;
    }
  }
  return inside;
}
