import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:wwu_maps_app/features/map/data/asset_floor_plan_repository.dart';
import 'package:wwu_maps_app/features/map/domain/models/floor_unit.dart';

import '../bundled_floors.dart';

void main() {
  group('parseFloorPlanGeoJson', () {
    const square = '[[[0,0],[1,0],[1,1],[0,1],[0,0]]]';

    String collection(List<String> features) =>
        '{"type":"FeatureCollection","features":[${features.join(',')}]}';

    String feature(String properties, String geometry) =>
        '{"type":"Feature","properties":$properties,"geometry":$geometry}';

    final level = feature(
      '{"feature_type":"level","category":"floor","name":"Floor 3",'
          '"building":"KRH-CSP","ordinal":3}',
      '{"type":"Polygon","coordinates":$square}',
    );

    test('reads the level, units and doors', () {
      final plan = AssetFloorPlanRepository.parseFloorPlanGeoJson(
        collection([
          level,
          feature(
            '{"feature_type":"unit","category":"elevator","name":"Elev."}',
            '{"type":"Polygon","coordinates":$square}',
          ),
          feature(
            '{"feature_type":"opening","category":"door","name":null}',
            '{"type":"LineString","coordinates":[[0,0],[0.5,0]]}',
          ),
        ]),
      );

      const ring = [LatLng(0, 0), LatLng(0, 1), LatLng(1, 1), LatLng(1, 0)];
      expect(plan.building, 'KRH-CSP');
      expect(plan.level, 3);
      // GeoJSON is [lng, lat]; the closing point is dropped.
      expect(plan.outline, ring);
      expect(plan.units, [
        const FloorUnit(type: UnitType.elevator, outline: ring, name: 'Elev.'),
      ]);
      expect(plan.doors, [(const LatLng(0, 0), const LatLng(0, 0.5))]);
    });

    test('skips features it does not draw', () {
      final plan = AssetFloorPlanRepository.parseFloorPlanGeoJson(
        collection([
          level,
          feature(
            '{"feature_type":"unit","category":"auditorium","name":"X"}',
            '{"type":"Polygon","coordinates":$square}',
          ),
          // Older exports stored stair treads; the app now draws its own.
          feature(
            '{"feature_type":"detail","category":"stair_tread","name":null}',
            '{"type":"LineString","coordinates":[[0,1],[1,1]]}',
          ),
          feature(
            '{"feature_type":"area","category":"terrace","name":null}',
            '{"type":"Polygon","coordinates":$square}',
          ),
          feature(
            '{"feature_type":"amenity","category":"restroom"}',
            '{"type":"Point","coordinates":[0,0]}',
          ),
        ]),
      );

      expect(plan.units, isEmpty);
    });

    test('rejects a file without a level', () {
      expect(
        () => AssetFloorPlanRepository.parseFloorPlanGeoJson(collection([])),
        throwsFormatException,
      );
    });

    // Floor: (units, doors, stairwells).
    const expected = {1: (50, 73, 5), 2: (62, 69, 4), 3: (52, 53, 4)};
    for (final level in bundledFloors) {
      test('reads the bundled KRH-CSP floor $level plan', () {
        final plan = bundledFloor(level);
        final (units, doors, stairwells) = expected[level]!;

        expect(plan.building, 'KRH-CSP');
        expect(plan.level, level);
        expect(plan.units, hasLength(units));
        expect(plan.doors, hasLength(doors));
        expect(
          plan.units.where((unit) => unit.type == UnitType.stairs),
          hasLength(stairwells),
        );
        expect(
          plan.units.where((unit) => unit.type == UnitType.elevator),
          hasLength(1),
        );
      });
    }
  });
}
