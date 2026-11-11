import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// A flat coordinate frame in metres around [origin], so that distances and
/// angles between nearby points are true.
final class LocalMetres {
  LocalMetres(this.origin)
    : _metresPerLng = _metresPerLat * math.cos(origin.latitudeInRad);

  /// The point the frame is measured from: east is +x and north is +y.
  final LatLng origin;

  static const _metresPerLat = 111320.0;
  final double _metresPerLng;

  /// [p] as metres east (x) and north (y) of [origin].
  math.Point<double> project(LatLng p) => math.Point(
    (p.longitude - origin.longitude) * _metresPerLng,
    (p.latitude - origin.latitude) * _metresPerLat,
  );

  /// The point [p] metres east (x) and north (y) of [origin].
  LatLng unproject(math.Point<double> p) => LatLng(
    origin.latitude + p.y / _metresPerLat,
    origin.longitude + p.x / _metresPerLng,
  );
}
