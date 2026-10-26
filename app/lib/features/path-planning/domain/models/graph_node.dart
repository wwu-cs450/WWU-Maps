import 'package:equatable/equatable.dart';
import 'package:flutter/rendering.dart';
import 'package:latlong2/latlong.dart';
import 'package:wwu_maps_app/features/path-planning/domain/models/node_type.dart';

class GraphNode extends Equatable {
  GraphNode({
    required this.id,
    required this.type,
    this.gps,
    this.pixelLocation,
    required this.buildingName,
    required this.floorLevel,
    Map<String, double>? neighbors,
  }) : assert(
         type == NodeType.entranceExit ? gps != null : gps == null,
         'Only entrance/exit nodes can have GPS.',
       ),
       assert(
         type == NodeType.entranceExit
             ? pixelLocation == null
             : pixelLocation != null,
         'Only non-entrance/exit nodes can have pixelLocation.',
       ),
       neighbors = Map.unmodifiable(neighbors ?? const <String, double>{});

  final String id;
  final NodeType type;
  final LatLng? gps;
  final Offset? pixelLocation;
  final String buildingName;
  final int floorLevel;

  /// Adjacent node IDs and the distance in meters to each one.
  final Map<String, double> neighbors;

  GraphNode copyWith({
    String? id,
    NodeType? type,
    LatLng? gps,
    Offset? pixelLocation,
    String? buildingName,
    int? floorLevel,
    Map<String, double>? neighbors,
  }) {
    return GraphNode(
      id: id ?? this.id,
      type: type ?? this.type,
      gps: gps ?? this.gps,
      pixelLocation: pixelLocation ?? this.pixelLocation,
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
    pixelLocation,
    buildingName,
    floorLevel,
    neighbors,
  ];
}
