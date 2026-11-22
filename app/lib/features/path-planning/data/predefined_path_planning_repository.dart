import 'package:latlong2/latlong.dart';
import 'package:wwu_maps_app/features/path-planning/domain/graph_rules.dart';
import 'package:wwu_maps_app/features/path-planning/domain/models/graph_node.dart';
import 'package:wwu_maps_app/features/path-planning/domain/models/node_type.dart';
import 'package:wwu_maps_app/features/path-planning/domain/models/path_result.dart';
import 'package:wwu_maps_app/features/path-planning/domain/models/route_point.dart';
import 'package:wwu_maps_app/features/path-planning/domain/path_planning_repository.dart';

class PredefinedPathPlanningRepository implements PathPlanningRepository {
  PredefinedPathPlanningRepository() {
    GraphRules.validateGraph(nodes);
  }

  final Map<String, GraphNode> _nodes = {
    'r_301': GraphNode(
      id: 'r_301',
      type: NodeType.room,
      location: const LatLng(46.04610361, -118.39008493),
      buildingName: 'KRH-CSP',
      floorLevel: 3,
      neighbors: {'hall_301': 8.0},
    ),
    'hall_301': GraphNode(
      id: 'hall_301',
      type: NodeType.hallway,
      location: const LatLng(46.04611900, -118.39016000),
      buildingName: 'KRH-CSP',
      floorLevel: 3,
      neighbors: {'r_301': 8.0, 'r_302': 8.0},
    ),
    'r_302': GraphNode(
      id: 'r_302',
      type: NodeType.room,
      location: const LatLng(46.04613468, -118.39008584),
      buildingName: 'KRH-CSP',
      floorLevel: 3,
      neighbors: {'hall_301': 8.0},
    ),
  };

  @override
  Map<String, GraphNode> get nodes => Map.unmodifiable(_nodes);

  @override
  PathResult findShortestPath(String startId, String endId) {
    final start = _nodes[startId];
    final end = _nodes[endId];

    if (start == null || end == null) {
      return const PathResult(nodeIds: [], totalDistance: 0, found: false);
    }

    if (startId == endId) {
      return PathResult(
        nodeIds: [startId],
        totalDistance: 0,
        routePoints: [_routePoint(start)],
        found: true,
      );
    }

    final distances = <String, double>{
      for (final nodeId in _nodes.keys) nodeId: double.infinity,
    };
    final previous = <String, String?>{
      for (final nodeId in _nodes.keys) nodeId: null,
    };
    final visited = <String>{};

    distances[startId] = 0;

    while (true) {
      final current = distances.entries
          .where((entry) => !visited.contains(entry.key))
          .fold<MapEntry<String, double>?>(null, (best, entry) {
            if (best == null || entry.value < best.value) {
              return entry;
            }
            return best;
          });

      if (current == null) {
        break;
      }

      final currentId = current.key;
      if (currentId == endId) {
        break;
      }

      visited.add(currentId);
      final node = _nodes[currentId]!;

      for (final neighborEntry in node.neighbors.entries) {
        final neighborId = neighborEntry.key;
        if (visited.contains(neighborId)) {
          continue;
        }

        final candidateDistance = current.value + neighborEntry.value;
        if (candidateDistance < (distances[neighborId] ?? double.infinity)) {
          distances[neighborId] = candidateDistance;
          previous[neighborId] = currentId;
        }
      }
    }

    final endDistance = distances[endId];
    if (endDistance == null || !endDistance.isFinite) {
      return const PathResult(nodeIds: [], totalDistance: 0, found: false);
    }

    final path = <String>[];
    String? cursor = endId;
    while (cursor != null) {
      path.add(cursor);
      cursor = previous[cursor];
    }

    final nodeIds = path.reversed.toList();
    final routePoints = nodeIds
        .map((nodeId) => _routePoint(_nodes[nodeId]!))
        .toList(growable: false);

    return PathResult(
      nodeIds: nodeIds,
      totalDistance: endDistance,
      routePoints: routePoints,
      found: true,
    );
  }

  static RoutePoint _routePoint(GraphNode node) => RoutePoint(
    nodeId: node.id,
    location: node.location,
    buildingName: node.buildingName,
    floorLevel: node.floorLevel,
  );
}
