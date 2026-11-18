import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:wwu_maps_app/features/map/domain/floor_plan_repository.dart';
import 'package:wwu_maps_app/features/map/domain/models/floor_plan.dart';
import 'package:wwu_maps_app/features/map/domain/models/floor_unit.dart';
import 'package:wwu_maps_app/features/search/data/floor_plan_room_repository.dart';
import 'package:wwu_maps_app/features/search/domain/models/room_query.dart';

import '../../map/bundled_floors.dart';

const _outline = [
  LatLng(46.0461, -118.3905),
  LatLng(46.0461, -118.3900),
  LatLng(46.0464, -118.3900),
];

FloorUnit _unit(UnitType type, String? name) =>
    FloorUnit(type: type, outline: _outline, name: name);

/// A [FloorPlanRepository] whose floors hold the units the test gives it.
class _FakeFloorPlanRepository implements FloorPlanRepository {
  _FakeFloorPlanRepository(this.unitsByLevel);

  final Map<int, List<FloorUnit>> unitsByLevel;
  final requests = <(String, int)>[];

  /// When true, every load throws.
  bool fail = false;

  @override
  Future<FloorPlan> floorPlan(String building, int level) async {
    requests.add((building, level));
    if (fail) {
      throw StateError('could not load floor $level');
    }
    return FloorPlan(
      building: building,
      level: level,
      outline: _outline,
      units: unitsByLevel[level] ?? const [],
    );
  }
}

/// A [FloorPlanRepository] that reads the GeoJSON floors bundled with the app.
class _BundledFloorPlanRepository implements FloorPlanRepository {
  @override
  Future<FloorPlan> floorPlan(String building, int level) async =>
      bundledFloor(level);
}

void main() {
  group('FloorPlanRoomRepository', () {
    late _FakeFloorPlanRepository floorPlans;
    late FloorPlanRoomRepository repository;

    Future<bool> exists(String roomNumber) =>
        repository.roomExists(RoomQuery(roomNumber: roomNumber));

    setUp(() {
      floorPlans = _FakeFloorPlanRepository({
        1: [_unit(UnitType.room, '101'), _unit(UnitType.room, null)],
        2: [_unit(UnitType.room, '214'), _unit(UnitType.stairs, 'S1')],
        3: [_unit(UnitType.room, '327B'), _unit(UnitType.elevator, 'Elev.')],
      });
      repository = FloorPlanRoomRepository(floorPlans);
    });

    test('finds named rooms on every floor', () async {
      expect(await exists('101'), isTrue);
      expect(await exists('214'), isTrue);
      expect(await exists('327B'), isTrue);
    });

    test('does not find a room that is not on any floor', () async {
      expect(await exists('999'), isFalse);
    });

    test('ignores stairs and elevators', () async {
      expect(await exists('S1'), isFalse);
      expect(await exists('Elev.'), isFalse);
    });

    test('ignores case', () async {
      expect(await exists('327b'), isTrue);
    });

    test('loads KRH-CSP floors 1 to 3 once, however many searches', () async {
      await exists('101');
      await exists('999');
      await exists('214');

      expect(floorPlans.requests, [
        ('KRH-CSP', 1),
        ('KRH-CSP', 2),
        ('KRH-CSP', 3),
      ]);
    });

    test('loads only the building and floors it is given', () async {
      repository = FloorPlanRoomRepository(
        floorPlans,
        building: 'OTHER',
        levels: const [2],
      );

      expect(await exists('214'), isTrue);
      expect(await exists('101'), isFalse);
      expect(floorPlans.requests, [('OTHER', 2)]);
    });

    test('tries loading again after a failed load', () async {
      floorPlans.fail = true;
      await expectLater(exists('101'), throwsStateError);

      floorPlans.fail = false;
      expect(await exists('101'), isTrue);
    });

    test('knows the rooms on the bundled KRH-CSP floors', () async {
      repository = FloorPlanRoomRepository(_BundledFloorPlanRepository());

      for (final room in ['101', '214', '327', '327B', '348']) {
        expect(await exists(room), isTrue, reason: 'room $room');
      }
      expect(await exists('999'), isFalse);
      expect(await exists('Elev.'), isFalse);
    });
  });
}
