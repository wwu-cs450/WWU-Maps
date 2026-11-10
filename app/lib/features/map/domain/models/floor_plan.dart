import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:wwu_maps_app/features/map/domain/models/floor_unit.dart';

/// A straight line on the floor plan, e.g. a door.
typedef FloorSegment = (LatLng, LatLng);

/// The drawing of one floor of a building.
class FloorPlan extends Equatable {
  const FloorPlan({
    required this.building,
    required this.level,
    required this.outline,
    this.units = const [],
    this.doors = const [],
    this.terraces = const [],
  });

  /// Building code, e.g. `KRH-CSP`.
  final String building;

  /// Floor number, e.g. 3 for the third floor.
  final int level;

  /// The building's exterior walls on this floor. Whatever the [units] don't
  /// cover is corridor.
  final List<LatLng> outline;

  final List<FloorUnit> units;

  /// Door openings in the unit walls.
  final List<FloorSegment> doors;

  /// Outdoor decks next to the building, as closed rings.
  final List<List<LatLng>> terraces;

  @override
  List<Object?> get props => [building, level, outline, units, doors, terraces];
}
