import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:wwu_maps_app/features/path-planning/data/predefined_path_planning_repository.dart';
import 'package:wwu_maps_app/features/path-planning/domain/graph_rules.dart';
import 'package:wwu_maps_app/features/path-planning/domain/models/graph_node.dart';
import 'package:wwu_maps_app/features/path-planning/domain/models/node_type.dart';

void main() {
  group('PredefinedPathPlanningRepository', () {
    late PredefinedPathPlanningRepository repository;

    setUp(() {
      repository = PredefinedPathPlanningRepository();
    });

    test('loads the predefined graph and contains the expected nodes', () {
      expect(repository.nodes.containsKey('hall_1'), isTrue);
      expect(repository.nodes.containsKey('r_101'), isTrue);
      expect(repository.nodes.containsKey('stair_2'), isTrue);
      expect(repository.nodes.length, equals(8));
    });

    test('finds the shortest room-to-room path via hallway nodes', () {
      final result = repository.findShortestPath('r_101', 'r_201');

      expect(result.found, isTrue);
      expect(
        result.nodeIds,
        ['r_101', 'hall_1', 'stair_1', 'stair_2', 'hall_2', 'r_201'],
      );
      expect(result.totalDistance, closeTo(82.0, 0.0001));
    });

    test('finds the shortest path from entrance to room', () {
      final result = repository.findShortestPath('entrance_1', 'r_201');

      expect(result.found, isTrue);
      expect(
        result.nodeIds,
        ['entrance_1', 'hall_1', 'stair_1', 'stair_2', 'hall_2', 'r_201'],
      );
      expect(result.totalDistance, closeTo(80.0, 0.0001));
    });

    test('returns a not found result for missing nodes', () {
      final result = repository.findShortestPath('missing', 'r_101');

      expect(result.found, isFalse);
      expect(result.nodeIds, isEmpty);
      expect(result.totalDistance, 0);
    });
  });

  group('GraphRules', () {
    test('rejects direct room-to-room connections', () {
      final graph = <String, GraphNode>{
        'room_a': GraphNode(
          id: 'room_a',
          type: NodeType.room,
          gps: const LatLng(46.0, -118.0),
          buildingName: 'Science Center',
          floorLevel: 1,
          neighbors: {'room_b': 12.0},
        ),
        'room_b': GraphNode(
          id: 'room_b',
          type: NodeType.room,
          gps: const LatLng(46.0, -118.1),
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
          gps: const LatLng(46.0, -118.2),
          buildingName: 'Science Center',
          floorLevel: 1,
          neighbors: {'stair_b': 20.0},
        ),
        'stair_b': GraphNode(
          id: 'stair_b',
          type: NodeType.stairway,
          gps: const LatLng(46.0, -118.3),
          buildingName: 'Science Center',
          floorLevel: 2,
          neighbors: {'stair_a': 20.0},
        ),
      };

      expect(() => GraphRules.validateGraph(graph), returnsNormally);
    });
  });
}
