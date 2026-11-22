import 'package:wwu_maps_app/features/path-planning/domain/models/graph_node.dart';
import 'package:wwu_maps_app/features/path-planning/domain/models/path_result.dart';
import 'package:wwu_maps_app/features/path-planning/domain/models/route_point.dart';

/// Finds routes through a graph supplied by a repository.
class PathFinder {
  const PathFinder(this._nodes);

  final Map<String, GraphNode> _nodes;

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
