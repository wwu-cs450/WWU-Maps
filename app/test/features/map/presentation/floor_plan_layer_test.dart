import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:wwu_maps_app/features/map/presentation/floor_plan_layer.dart';
import 'package:wwu_maps_app/features/map/presentation/helpers/local_centroid_calculator.dart';

import '../bundled_floors.dart';

void main() {
  group('FloorPlanLayer.wallSegments', () {
    const a = LatLng(46, -118);
    const b = LatLng(46, -117.999);
    const c = LatLng(46.001, -117.999);
    const d = LatLng(46.001, -118);

    test('draws every wall when there are no doors', () {
      expect(FloorPlanLayer.wallSegments(const [a, b, c, d], const []), const [
        (a, b),
        (b, c),
        (c, d),
        (d, a),
      ]);
    });

    test('leaves a gap where a door lies along a wall', () {
      const doorStart = LatLng(46, -117.9998);
      const doorEnd = LatLng(46, -117.9994);
      final walls = FloorPlanLayer.wallSegments(
        const [a, b, c, d],
        const [
          (doorEnd, doorStart), // Direction doesn't matter.
        ],
      );

      expect(walls, hasLength(5));
      final (start1, end1) = walls[0];
      final (start2, end2) = walls[1];
      expect(start1, a);
      expect(end1.longitude, closeTo(doorStart.longitude, 1e-12));
      expect(start2.longitude, closeTo(doorEnd.longitude, 1e-12));
      expect(end2, b);
      expect(walls.sublist(2), const [(b, c), (c, d), (d, a)]);
    });

    test('ignores doors on other walls', () {
      const elsewhere = (LatLng(46.0005, -118.01), LatLng(46.0005, -118.009));
      expect(
        FloorPlanLayer.wallSegments(const [a, b, c, d], const [elsewhere]),
        hasLength(4),
      );
    });

    for (final level in bundledFloors) {
      test('cuts every door on bundled floor $level into some wall', () {
        final plan = bundledFloor(level);
        final rings = [
          plan.outline,
          for (final unit in plan.units) unit.outline,
        ];

        for (final door in plan.doors) {
          expect(
            rings.any(
              (ring) =>
                  FloorPlanLayer.wallSegments(ring, [door]).length >
                  FloorPlanLayer.wallSegments(ring, const []).length,
            ),
            isTrue,
            reason: '$door',
          );
        }
      });
    }
  });

  group('LocalCentroidCalculator.centroid', () {
    test('finds the centre of a rectangle', () {
      final c = LocalCentroidCalculator.centroid(const [
        LatLng(46, -118),
        LatLng(46, -117.998),
        LatLng(46.001, -117.998),
        LatLng(46.001, -118),
      ]);

      expect(c.latitude, closeTo(46.0005, 1e-9));
      expect(c.longitude, closeTo(-117.999, 1e-9));
    });

    for (final level in bundledFloors) {
      test('puts every room label on bundled floor $level inside its room', () {
        final plan = bundledFloor(level);
        const distance = Distance();

        for (final unit in plan.units.where((unit) => unit.name != null)) {
          final points = unit.outline;
          final lat = points.map((p) => p.latitude).reduce((a, b) => a + b);
          final lng = points.map((p) => p.longitude).reduce((a, b) => a + b);
          final average = LatLng(lat / points.length, lng / points.length);
          final bounds = (
            minLat: points
                .map((p) => p.latitude)
                .reduce((a, b) => a < b ? a : b),
            maxLat: points
                .map((p) => p.latitude)
                .reduce((a, b) => a > b ? a : b),
            minLng: points
                .map((p) => p.longitude)
                .reduce((a, b) => a < b ? a : b),
            maxLng: points
                .map((p) => p.longitude)
                .reduce((a, b) => a > b ? a : b),
          );

          final label = LocalCentroidCalculator.centroid(points);

          expect(
            label.latitude,
            inInclusiveRange(bounds.minLat, bounds.maxLat),
            reason: unit.name,
          );
          expect(
            label.longitude,
            inInclusiveRange(bounds.minLng, bounds.maxLng),
            reason: unit.name,
          );
          // Centroid and vertex average differ for irregular rooms, but only
          // by a few metres, never by tens of metres.
          expect(distance(label, average), lessThan(5), reason: unit.name);
        }
      });
    }
  });
}
