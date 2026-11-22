import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

/// One displayable point from the optimal Dijkstra route.
class RoutePoint extends Equatable {
  const RoutePoint({
    required this.nodeId,
    required this.location,
    required this.buildingName,
    required this.floorLevel,
  });

  final String nodeId;
  final LatLng location;
  final String buildingName;
  final int floorLevel;

  @override
  List<Object?> get props => [nodeId, location, buildingName, floorLevel];
}
