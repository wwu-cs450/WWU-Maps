import 'package:wwu_maps_app/features/path-planning/domain/models/graph_node.dart';

/// Provides the graph used for path planning.
abstract interface class PathPlanningRepository {
  Map<String, GraphNode> get nodes;
}
