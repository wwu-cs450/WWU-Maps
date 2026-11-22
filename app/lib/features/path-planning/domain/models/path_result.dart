import 'package:equatable/equatable.dart';
import 'package:wwu_maps_app/features/path-planning/domain/models/route_point.dart';

class PathResult extends Equatable {
  const PathResult({
    required this.nodeIds,
    required this.totalDistance,
    this.routePoints = const [],
    this.found = true,
  });

  final List<String> nodeIds;
  final double totalDistance;
  final List<RoutePoint> routePoints;
  final bool found;

  @override
  List<Object?> get props => [nodeIds, totalDistance, routePoints, found];
}
