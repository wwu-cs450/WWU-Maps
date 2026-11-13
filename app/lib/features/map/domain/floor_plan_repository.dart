import 'package:wwu_maps_app/features/map/domain/models/floor_plan.dart';

abstract interface class FloorPlanRepository {
  /// The plan of floor [level] of [building] (a code such as `KRH-CSP`).
  Future<FloorPlan> floorPlan(String building, int level);
}
