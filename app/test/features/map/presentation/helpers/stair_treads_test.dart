import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:wwu_maps_app/features/map/domain/models/floor_plan.dart';
import 'package:wwu_maps_app/features/map/domain/models/floor_unit.dart';
import 'package:wwu_maps_app/features/map/presentation/helpers/stair_treads.dart';

import '../../bundled_floors.dart';

void main() {
  group('stairTreads', () {
    const distance = Distance(roundResult: false);
    const metresPerLat = 111320.0;
    const metresPerLng = 111320.0 * 0.69465837; // cos(46 deg)

    // A point x metres east and y metres north of the stairwells' south-west
    // corner.
    LatLng at(double x, double y) =>
        LatLng(46 + y / metresPerLat, -118 + x / metresPerLng);

    // A stairwell 8 m east-west by 4 m north-south.
    final stairwell = [at(0, 0), at(8, 0), at(8, 4), at(0, 4)];

    List<FloorSegment> eastWest(List<FloorSegment> lines) => [
      for (final line in lines)
        if ((line.$1.latitude - line.$2.latitude).abs() < 1e-12) line,
    ];
    List<FloorSegment> northSouth(List<FloorSegment> lines) => [
      for (final line in lines)
        if ((line.$1.longitude - line.$2.longitude).abs() < 1e-12) line,
    ];

    test('draws two flights the full length of the stairwell', () {
      final lines = stairTreads(stairwell);

      // 8 m of steps about 0.3 m deep: 27 steps, so 28 step edges per
      // flight, running across the stairwell (north-south)...
      final steps = northSouth(lines);
      expect(steps, hasLength(56));
      for (final (a, b) in steps) {
        // ...each half the width, less half of the 0.2 m gap.
        expect(distance(a, b), closeTo(1.9, 0.01));
      }
      expect(steps.first.$1.longitude, closeTo(at(0, 0).longitude, 1e-12));
      expect(steps[27].$1.longitude, closeTo(at(8, 0).longitude, 1e-12));

      // ...plus the two long sides of each flight, end to end.
      final sides = eastWest(lines);
      expect(sides, hasLength(4));
      for (final (a, b) in sides) {
        expect(distance(a, b), closeTo(8, 0.05));
      }
    });

    test('leaves a gap between the flights', () {
      final sides = eastWest(stairTreads(stairwell));
      final northings = [
        for (final (a, _) in sides) (a.latitude - 46) * metresPerLat,
      ]..sort();

      expect(northings[0], closeTo(0, 1e-6));
      expect(northings[1], closeTo(1.9, 1e-6));
      expect(northings[2], closeTo(2.1, 1e-6));
      expect(northings[3], closeTo(4, 1e-6));
    });

    test('draws a single flight in a narrow stairwell', () {
      // 6 m east-west by 1.5 m north-south: too narrow for two flights.
      final lines = stairTreads([at(0, 0), at(6, 0), at(6, 1.5), at(0, 1.5)]);

      // 20 steps of 0.3 m: 21 step edges, each the full width...
      final steps = northSouth(lines);
      expect(steps, hasLength(21));
      for (final (a, b) in steps) {
        expect(distance(a, b), closeTo(1.5, 0.01));
      }
      // ...and the flight's two sides along the stairwell's walls.
      final northings = [
        for (final (a, _) in eastWest(lines)) (a.latitude - 46) * metresPerLat,
      ]..sort();
      expect(northings, hasLength(2));
      expect(northings[0], closeTo(0, 1e-6));
      expect(northings[1], closeTo(1.5, 1e-6));
    });

    test('follows a rotated stairwell', () {
      // The same stairwell turned 45 degrees around its first corner.
      LatLng rotated(double x, double y) {
        const c = 0.70710678;
        return at(x * c - y * c, x * c + y * c);
      }

      final lines = stairTreads([
        rotated(0, 0),
        rotated(8, 0),
        rotated(8, 4),
        rotated(0, 4),
      ]);

      expect(lines, hasLength(60));
      final lengths = [for (final (a, b) in lines) distance(a, b)];
      expect(lengths.where((l) => (l - 1.9).abs() < 0.02), hasLength(56));
      expect(lengths.where((l) => (l - 8).abs() < 0.05), hasLength(4));
    });

    test('fills only the largest rectangle of an irregular stairwell', () {
      // The 8 x 4 m stairwell with a 2 x 3 m passage hanging off its south
      // side, at its east end.
      final lines = stairTreads([
        at(0, 0),
        at(6, 0),
        at(6, -3),
        at(8, -3),
        at(8, 4),
        at(0, 4),
      ]);

      // Same stairs as the plain 8 x 4 m stairwell: nothing in the passage.
      expect(lines, hasLength(60));
      for (final (a, b) in lines) {
        for (final p in [a, b]) {
          expect(p.latitude, greaterThanOrEqualTo(at(0, 0).latitude - 1e-12));
        }
      }
    });

    test('runs a square stairwell\'s flights toward its passage', () {
      // A 4 x 4 m square with a 2 x 3 m passage off its south side.
      final lines = stairTreads([
        at(0, 0),
        at(2, 0),
        at(2, -3),
        at(4, -3),
        at(4, 4),
        at(0, 4),
      ]);

      // The flights run north-south: 13 steps (14 east-west step edges) and
      // 2 north-south sides each. Turned the other way, the counts would swap.
      expect(eastWest(lines), hasLength(28));
      expect(northSouth(lines), hasLength(4));
    });

    test('lines the steps up with the walls, not a slanted short edge', () {
      // The square-with-passage stairwell, but the passage's end wall is a
      // few degrees off, as in the real KRH-CSP west stairwell.
      final lines = stairTreads([
        at(0, 0),
        at(2, 0),
        at(2, -3),
        at(4, -3.2),
        at(4, 4),
        at(0, 4),
      ]);

      expect(lines, isNotEmpty);
      expect(eastWest(lines).length + northSouth(lines).length, lines.length);
    });

    test('keeps every line when stored corners are a millimetre off', () {
      // Rounded coordinates leave walls not quite square; lines that touch
      // them must still be drawn.
      final lines = stairTreads([
        at(0, 0),
        at(8, 0.001),
        at(8.001, 4),
        at(-0.001, 4.001),
      ]);

      expect(lines, hasLength(60));
    });

    test('leaves a landing at the end with the door', () {
      // A door in the east end wall.
      final lines = stairTreads(stairwell, doors: [(at(8, 0.5), at(8, 1.5))]);

      // 1.5 m landing: steps run from x = 0 to x = 6.5.
      final xs = [
        for (final (a, _) in northSouth(lines))
          (a.longitude + 118) * metresPerLng,
      ];
      expect(xs.reduce((a, b) => a < b ? a : b), closeTo(0, 1e-6));
      expect(xs.reduce((a, b) => a > b ? a : b), closeTo(6.5, 1e-6));
      for (final (a, b) in eastWest(lines)) {
        expect(distance(a, b), closeTo(6.5, 0.05));
      }
    });

    test(
      'puts the landing at the door end when the door is on a long side',
      () {
        // A door in the south wall, near the west end.
        final lines = stairTreads(stairwell, doors: [(at(0.5, 0), at(1.5, 0))]);

        final xs = [
          for (final (a, _) in northSouth(lines))
            (a.longitude + 118) * metresPerLng,
        ];
        expect(xs.reduce((a, b) => a < b ? a : b), closeTo(1.5, 1e-6));
        expect(xs.reduce((a, b) => a > b ? a : b), closeTo(8, 1e-6));
      },
    );

    test('stretches the landing to clear a door in a long side', () {
      // A door in the south wall reaching 2.2 m from the west end, past the
      // usual 1.5 m landing.
      final lines = stairTreads(stairwell, doors: [(at(0.6, 0), at(2.2, 0))]);

      final xs = [
        for (final (a, _) in northSouth(lines))
          (a.longitude + 118) * metresPerLng,
      ];
      expect(xs.reduce((a, b) => a < b ? a : b), closeTo(2.2, 1e-6));
      expect(xs.reduce((a, b) => a > b ? a : b), closeTo(8, 1e-6));
    });

    test('ignores doors in other rooms\' walls', () {
      final lines = stairTreads(stairwell, doors: [(at(20, 0), at(21, 0))]);

      expect(lines, hasLength(60));
    });

    test('leaves no landing in an irregular stairwell', () {
      // The 8 x 4 m stairwell with a passage off its south side, entered
      // through the passage.
      final lines = stairTreads(
        [at(0, 0), at(6, 0), at(6, -3), at(8, -3), at(8, 4), at(0, 4)],
        doors: [(at(6.5, -3), at(7.5, -3))],
      );

      expect(lines, hasLength(60));
    });

    test('draws nothing in a stairwell too small for steps', () {
      expect(
        stairTreads([at(0, 0), at(0.5, 0), at(0.5, 0.5), at(0, 0.5)]),
        isEmpty,
      );
    });

    for (final level in bundledFloors) {
      test('draws both flights inside each stairwell on bundled floor $level', () {
        final plan = bundledFloor(level);
        final stairwells = plan.units
            .where((unit) => unit.type == UnitType.stairs)
            .toList();

        expect(stairwells, isNotEmpty);
        for (final stairwell in stairwells) {
          final lines = stairTreads(stairwell.outline, doors: plan.doors);
          expect(lines, isNotEmpty);
          final lats = stairwell.outline.map((p) => p.latitude);
          final lngs = stairwell.outline.map((p) => p.longitude);
          // Rounded coordinates can leave a line's end a millimetre or so past
          // a wall; allow 5 cm.
          const slackLat = 0.05 / metresPerLat;
          const slackLng = 0.05 / metresPerLng;
          for (final (a, b) in lines) {
            for (final p in [a, b]) {
              expect(
                p.latitude,
                inInclusiveRange(
                  lats.reduce((x, y) => x < y ? x : y) - slackLat,
                  lats.reduce((x, y) => x > y ? x : y) + slackLat,
                ),
              );
              expect(
                p.longitude,
                inInclusiveRange(
                  lngs.reduce((x, y) => x < y ? x : y) - slackLng,
                  lngs.reduce((x, y) => x > y ? x : y) + slackLng,
                ),
              );
            }
          }
        }
      });
    }
  });
}
