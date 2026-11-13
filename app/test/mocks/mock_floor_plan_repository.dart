import 'package:latlong2/latlong.dart';
import 'package:wwu_maps_app/features/map/domain/floor_plan_repository.dart';
import 'package:wwu_maps_app/features/map/domain/models/floor_plan.dart';
import 'package:wwu_maps_app/features/map/domain/models/floor_unit.dart';

/// A [FloorPlanRepository] that returns a one-room plan for any floor.
class MockFloorPlanRepository implements FloorPlanRepository {
  final requests = <(String, int)>[];

  @override
  Future<FloorPlan> floorPlan(String building, int level) async {
    requests.add((building, level));
    const a = LatLng(46.0461, -118.3905);
    const b = LatLng(46.0461, -118.3900);
    const c = LatLng(46.0464, -118.3900);
    const d = LatLng(46.0464, -118.3905);
    return FloorPlan(
      building: building,
      level: level,
      outline: const [a, b, c, d],
      units: const [
        FloorUnit(type: UnitType.room, outline: [a, b, c], name: '301'),
      ],
    );
  }
}
