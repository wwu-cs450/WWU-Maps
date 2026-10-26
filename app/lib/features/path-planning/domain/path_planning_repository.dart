import 'models/graph_node.dart';
import 'models/path_result.dart';

abstract interface class PathPlanningRepository {
  Map<String, GraphNode> get nodes;

  PathResult findShortestPath(String startId, String endId);
}
