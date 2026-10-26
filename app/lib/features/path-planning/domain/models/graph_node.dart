import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import 'node_type.dart';

class GraphNode extends Equatable {
  const GraphNode({
    required this.id,
    required this.type,
    required this.gps,
    required this.buildingName,
    required this.floorLevel,
    Map<String, double>? neighbors,
  }) : neighbors = Map.unmodifiable(neighbors ?? const <String, double>{});

  final String id;
  final NodeType type;
  final LatLng gps;
  final String buildingName;
  final int floorLevel;

  /// Adjacent node IDs and the distance in meters to each one.
  final Map<String, double> neighbors;

  GraphNode copyWith({
    String? id,
    NodeType? type,
    LatLng? gps,
    String? buildingName,
    int? floorLevel,
    Map<String, double>? neighbors,
  }) {
    return GraphNode(
      id: id ?? this.id,
      type: type ?? this.type,
      gps: gps ?? this.gps,
      buildingName: buildingName ?? this.buildingName,
      floorLevel: floorLevel ?? this.floorLevel,
      neighbors: neighbors ?? this.neighbors,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    gps,
    buildingName,
    floorLevel,
    neighbors,
  ];
}
