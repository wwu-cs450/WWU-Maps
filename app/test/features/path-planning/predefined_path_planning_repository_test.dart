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
      expect(repository.nodes.containsKey('hall_301'), isTrue);
      expect(repository.nodes.containsKey('r_301'), isTrue);
      expect(repository.nodes.containsKey('r_302'), isTrue);
      expect(repository.nodes.length, equals(3));

      for (final node in repository.nodes.values) {
        expect(node.buildingName, 'KRH-CSP');
        expect(node.floorLevel, 3);
        expect(node.location.latitude.isFinite, isTrue);
        expect(node.location.longitude.isFinite, isTrue);
      }
    });

    test('finds the optimal room-to-room path via the hallway', () {
      final result = repository.findShortestPath('r_301', 'r_302');

      expect(result.found, isTrue);
      expect(result.nodeIds, ['r_301', 'hall_301', 'r_302']);
      expect(result.totalDistance, closeTo(16.0, 0.0001));
      expect(result.routePoints.map((point) => point.nodeId), [
        'r_301',
        'hall_301',
        'r_302',
      ]);
    });

    test('returns a not found result for missing nodes', () {
      final result = repository.findShortestPath('missing', 'r_301');

      expect(result.found, isFalse);
      expect(result.nodeIds, isEmpty);
      expect(result.totalDistance, 0);
    });

    test('returns one point for a same-node route', () {
      final result = repository.findShortestPath('r_301', 'r_301');

      expect(result.found, isTrue);
      expect(result.nodeIds, ['r_301']);
      expect(result.routePoints, hasLength(1));
      expect(result.totalDistance, 0);
    });
  });

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
