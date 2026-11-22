import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:wwu_maps_app/features/path-planning/domain/models/node_type.dart';

class GraphNode extends Equatable {
  GraphNode({
    required this.id,
    required this.type,
    required this.location,
    required this.buildingName,
    required this.floorLevel,
    Map<String, double>? neighbors,
  }) : neighbors = Map.unmodifiable(neighbors ?? const <String, double>{});

  final String id;
  final NodeType type;
  final LatLng location;
  final String buildingName;
  final int floorLevel;

  /// Adjacent node IDs and the distance in meters to each one.
  final Map<String, double> neighbors;

  GraphNode copyWith({
    String? id,
    NodeType? type,
    LatLng? location,
    String? buildingName,
    int? floorLevel,
    Map<String, double>? neighbors,
  }) {
    return GraphNode(
      id: id ?? this.id,
      type: type ?? this.type,
      location: location ?? this.location,
      buildingName: buildingName ?? this.buildingName,
      floorLevel: floorLevel ?? this.floorLevel,
      neighbors: neighbors ?? this.neighbors,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    location,
    buildingName,
    floorLevel,
    neighbors,
  ];
}
