import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:wwu_maps_app/features/path-planning/domain/models/graph_node.dart';
import 'package:wwu_maps_app/features/path-planning/domain/models/path_result.dart';
import 'package:wwu_maps_app/features/path-planning/presentation/debug_config.dart';

class ProposedPathLayer extends StatelessWidget {
  const ProposedPathLayer({
    required this.building,
    required this.floorLevel,
    required this.nodes,
    this.path,
    super.key,
  });

  final String building;
  final int floorLevel;
  final Map<String, GraphNode> nodes;
  final PathResult? path;

  @visibleForTesting
  static List<List<LatLng>> segmentsForCurrentFloor(
    PathResult? path,
    String building,
    int floorLevel,
  ) {
    if (path == null || !path.found) {
      return const [];
    }

    final segments = <List<LatLng>>[];
    var current = <LatLng>[];

    for (var i = 0; i < path.routePoints.length - 1; i++) {
      final start = path.routePoints[i];
      final end = path.routePoints[i + 1];
      final bothOnCurrentFloor =
          start.buildingName == building &&
          start.floorLevel == floorLevel &&
          end.buildingName == building &&
          end.floorLevel == floorLevel;

      if (!bothOnCurrentFloor) {
        if (current.length > 1) {
          segments.add(List<LatLng>.unmodifiable(current));
        }
        current = <LatLng>[];
        continue;
      }

      if (current.isEmpty) {
        current = <LatLng>[start.location, end.location];
      } else {
        current.add(end.location);
      }
    }

    if (current.length > 1) {
      segments.add(List<LatLng>.unmodifiable(current));
    }
    return List<List<LatLng>>.unmodifiable(segments);
  }

  @override
  Widget build(BuildContext context) {
    final segments = segmentsForCurrentFloor(path, building, floorLevel);

    final markers = <Marker>[];
    if (showPathPlanningDebugNodes) {
      for (final node in nodes.values) {
        if (node.buildingName != building || node.floorLevel != floorLevel) {
          continue;
        }
        markers.add(
          Marker(
            point: node.location,
            width: 118,
            height: 38,
            child: Semantics(
              label: 'Path node ${node.id}',
              child: Container(
                key: ValueKey('path-node-${node.id}'),
                alignment: Alignment.topCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.deepOrange, width: 1.5),
                  ),
                  child: Text(
                    node.id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Stack(
      children: [
        if (segments.isNotEmpty)
          PolylineLayer(
            key: ValueKey('proposed-path-$building-$floorLevel'),
            polylines: [
              for (final segment in segments)
                Polyline(
                  points: segment,
                  color: const Color(0xFF2979FF),
                  strokeWidth: 5,
                ),
            ],
          ),
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
      ],
    );
  }
}
