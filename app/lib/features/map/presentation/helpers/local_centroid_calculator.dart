import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Places a polygon's label at its area-weighted centroid.
///
/// flutter_map's own centroid calculator works on raw coordinates, where the
/// products of longitudes and latitudes (about -118 x 46 here) cancel out
/// catastrophically for room-sized polygons: labels landed tens of metres to
/// kilometres away from their rooms. [centroid] works with small offsets
/// instead, which keeps the full precision.
@immutable
final class LocalCentroidCalculator implements PolygonLabelPlacementCalculator {
  const LocalCentroidCalculator();

  @override
  LatLng call(Polygon polygon) => centroid(polygon.points);

  /// The area-weighted centroid of the ring [points] (first point not
  /// repeated). Falls back to the average of the points for a degenerate ring.
  static LatLng centroid(List<LatLng> points) {
    final origin = points.first;
    var area = 0.0;
    var cx = 0.0;
    var cy = 0.0;
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final q = points[(i + 1) % points.length];
      final x0 = p.longitude - origin.longitude;
      final y0 = p.latitude - origin.latitude;
      final x1 = q.longitude - origin.longitude;
      final y1 = q.latitude - origin.latitude;
      final cross = x0 * y1 - x1 * y0;
      area += cross;
      cx += (x0 + x1) * cross;
      cy += (y0 + y1) * cross;
    }
    if (area == 0) {
      final n = points.length;
      return LatLng(
        points.map((p) => p.latitude).reduce((a, b) => a + b) / n,
        points.map((p) => p.longitude).reduce((a, b) => a + b) / n,
      );
    }
    return LatLng(
      origin.latitude + cy / (3 * area),
      origin.longitude + cx / (3 * area),
    );
  }
}
