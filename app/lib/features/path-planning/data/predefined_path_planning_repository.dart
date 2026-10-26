import 'package:latlong2/latlong.dart';

import '../domain/graph_rules.dart';
import '../domain/models/graph_node.dart';
import '../domain/models/node_type.dart';
import '../domain/models/path_result.dart';
import '../domain/path_planning_repository.dart';

class PredefinedPathPlanningRepository implements PathPlanningRepository {
  PredefinedPathPlanningRepository() {
    GraphRules.validateGraph(nodes);
  }

  final Map<String, GraphNode> _nodes = {
    'hall_1': const GraphNode(
      id: 'hall_1',
      type: NodeType.hallway,
      gps: LatLng(46.0486, -118.3672),
      buildingName: 'Science Center',
      floorLevel: 1,
      neighbors: {
        'r_101': 18.0,
        'r_102': 22.0,
        'stair_1': 12.0,
        'entrance_1': 16.0,
      },
    ),
    'r_101': const GraphNode(
      id: 'r_101',
      type: NodeType.room,
      gps: LatLng(46.0487, -118.3670),
      buildingName: 'Science Center',
      floorLevel: 1,
      neighbors: {
        'hall_1': 18.0,
      },
    ),
    'r_102': const GraphNode(
      id: 'r_102',
      type: NodeType.room,
      gps: LatLng(46.0485, -118.3675),
      buildingName: 'Science Center',
      floorLevel: 1,
      neighbors: {
        'hall_1': 22.0,
      },
    ),
    'stair_1': const GraphNode(
      id: 'stair_1',
      type: NodeType.stairway,
      gps: LatLng(46.0486, -118.3679),
      buildingName: 'Science Center',
      floorLevel: 1,
      neighbors: {
        'hall_1': 12.0,
        'stair_2': 18.0,
      },
    ),
    'entrance_1': const GraphNode(
      id: 'entrance_1',
      type: NodeType.entrance,
      gps: LatLng(46.0489, -118.3672),
      buildingName: 'Science Center',
      floorLevel: 1,
      neighbors: {
        'hall_1': 16.0,
      },
    ),
    'hall_2': const GraphNode(
      id: 'hall_2',
      type: NodeType.hallway,
      gps: LatLng(46.0486, -118.3672),
      buildingName: 'Science Center',
      floorLevel: 2,
      neighbors: {
        'stair_2': 14.0,
        'r_201': 20.0,
      },
    ),
    'stair_2': const GraphNode(
      id: 'stair_2',
      type: NodeType.stairway,
      gps: LatLng(46.0486, -118.3679),
      buildingName: 'Science Center',
      floorLevel: 2,
      neighbors: {
        'hall_2': 14.0,
        'stair_1': 18.0,
      },
    ),
    'r_201': const GraphNode(
      id: 'r_201',
      type: NodeType.room,
      gps: LatLng(46.0484, -118.3676),
      buildingName: 'Science Center',
      floorLevel: 2,
      neighbors: {
        'hall_2': 20.0,
      },
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
          } );

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

    if (distances[endId] == null || distances[endId] == double.infinity) {
      return const PathResult(nodeIds: [], totalDistance: 0, found: false);
    }

    final path = <String>[];
    String? cursor = endId;
    while (cursor != null) {
      path.add(cursor);
      cursor = previous[cursor];
    }
    path = path.reversed.toList();

    return PathResult(
      nodeIds: path,
      totalDistance: distances[endId]!,
      found: true,
    );
  }
}
