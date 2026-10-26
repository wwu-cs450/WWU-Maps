import 'package:wwu_maps_app/features/path-planning/domain/models/graph_node.dart';
import 'package:wwu_maps_app/features/path-planning/domain/models/node_type.dart';

class GraphRules {
  const GraphRules._();

  static bool canConnect(GraphNode from, GraphNode to) {
    if (from.id == to.id) {
      return false;
    }

    if (from.type == NodeType.stairway && to.type == NodeType.stairway) {
      return true;
    }

    if (from.type == NodeType.hallway || to.type == NodeType.hallway) {
      return true;
    }

    return false;
  }

  static void validateGraph(Map<String, GraphNode> nodes) {
    for (final entry in nodes.entries) {
      final current = entry.value;

      for (final neighborId in current.neighbors.keys) {
        final neighbor = nodes[neighborId];
        if (neighbor == null) {
          throw StateError(
            'Node "${current.id}" references unknown neighbor "$neighborId".',
          );
        }

        if (!canConnect(current, neighbor)) {
          throw StateError(
            'Invalid connection: "${current.id}" (${current.type.name}) cannot '
            'connect directly to "${neighbor.id}" (${neighbor.type.name}).',
          );
        }
      }
    }
  }
}
