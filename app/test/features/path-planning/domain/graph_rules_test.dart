import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:wwu_maps_app/features/path-planning/domain/graph_rules.dart';
import 'package:wwu_maps_app/features/path-planning/domain/models/graph_node.dart';
import 'package:wwu_maps_app/features/path-planning/domain/models/node_type.dart';

void main() {
  group('GraphRules', () {
    test('rejects direct room-to-room connections', () {
      final graph = <String, GraphNode>{
        'room_a': GraphNode(
          id: 'room_a',
          type: NodeType.room,
          location: const LatLng(46.0461, -118.3905),
          buildingName: 'Science Center',
          floorLevel: 1,
          neighbors: {'room_b': 12.0},
        ),
        'room_b': GraphNode(
          id: 'room_b',
          type: NodeType.room,
          location: const LatLng(46.0462, -118.3904),
          buildingName: 'Science Center',
          floorLevel: 1,
          neighbors: {'room_a': 12.0},
        ),
      };

      expect(() => GraphRules.validateGraph(graph), throwsA(isA<StateError>()));
    });

    test('allows direct stairway-to-stairway connections', () {
      final graph = <String, GraphNode>{
        'stair_a': GraphNode(
          id: 'stair_a',
          type: NodeType.stairway,
          location: const LatLng(46.0461, -118.3905),
          buildingName: 'Science Center',
          floorLevel: 1,
          neighbors: {'stair_b': 20.0},
        ),
        'stair_b': GraphNode(
          id: 'stair_b',
          type: NodeType.stairway,
          location: const LatLng(46.0462, -118.3904),
          buildingName: 'Science Center',
          floorLevel: 2,
          neighbors: {'stair_a': 20.0},
        ),
      };

      expect(() => GraphRules.validateGraph(graph), returnsNormally);
    });
  });
}
