import 'package:latlong2/latlong.dart';
import 'package:wwu_maps_app/features/path-planning/domain/graph_rules.dart';
import 'package:wwu_maps_app/features/path-planning/domain/models/graph_node.dart';
import 'package:wwu_maps_app/features/path-planning/domain/models/node_type.dart';
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
}
