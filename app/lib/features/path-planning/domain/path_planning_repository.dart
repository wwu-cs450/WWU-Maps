import 'package:wwu_maps_app/features/path-planning/domain/models/graph_node.dart';
import 'package:wwu_maps_app/features/path-planning/domain/models/path_result.dart';

abstract interface class PathPlanningRepository {
  Map<String, GraphNode> get nodes;

  PathResult findShortestPath(String startId, String endId);
}
