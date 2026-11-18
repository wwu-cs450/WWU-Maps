import 'package:wwu_maps_app/features/map/domain/floor_plan_repository.dart';
import 'package:wwu_maps_app/features/map/domain/models/floor_unit.dart';
import 'package:wwu_maps_app/features/search/domain/models/room_query.dart';
import 'package:wwu_maps_app/features/search/domain/room_repository.dart';

/// Knows which rooms exist from the room numbers drawn on the floor plans.
///
/// Only units of type [UnitType.room] with a name count, so stairs,
/// elevators and unlabelled rooms can't be searched for.
class FloorPlanRoomRepository implements RoomRepository {
  FloorPlanRoomRepository(
    this._floorPlans, {
    this.building = 'KRH-CSP',
    this.levels = const [1, 2, 3],
  });

  final FloorPlanRepository _floorPlans;

  /// The building whose floors are searched, e.g. `KRH-CSP`.
  final String building;

  /// The floors of [building] that are searched.
  final List<int> levels;

  /// Room numbers in upper case, loaded on the first search.
  Future<Set<String>>? _rooms;

  @override
  Future<bool> roomExists(RoomQuery query) async {
    final rooms = await (_rooms ??= _loadRooms());
    return rooms.contains(query.roomNumber.toUpperCase());
  }

  Future<Set<String>> _loadRooms() async {
    try {
      final plans = await Future.wait([
        for (final level in levels) _floorPlans.floorPlan(building, level),
      ]);
      return {
        for (final plan in plans)
          for (final unit in plan.units)
            if (unit.type == UnitType.room && unit.name != null)
              unit.name!.toUpperCase(),
      };
    } catch (_) {
      // Forget the failure so the next search tries loading again.
      _rooms = null;
      rethrow;
    }
  }
}
