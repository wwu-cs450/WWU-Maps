import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

/// What kind of [FloorUnit] it is.
enum UnitType { room, stairs, elevator }

/// One enclosed space on a floor: a room, stairwell or elevator.
class FloorUnit extends Equatable {
  const FloorUnit({required this.type, required this.outline, this.name});

  final UnitType type;

  /// The unit's walls, as a closed ring (first point not repeated).
  final List<LatLng> outline;

  /// Label shown on the map, e.g. a room number.
  final String? name;

  @override
  List<Object?> get props => [type, outline, name];
}
