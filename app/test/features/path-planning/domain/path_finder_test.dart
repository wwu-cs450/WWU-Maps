import 'package:flutter_test/flutter_test.dart';
import 'package:wwu_maps_app/features/path-planning/data/predefined_path_planning_repository.dart';
import 'package:wwu_maps_app/features/path-planning/domain/path_finder.dart';

void main() {
  group('PathFinder', () {
    late PathFinder pathFinder;

    setUp(() {
      pathFinder = PathFinder(PredefinedPathPlanningRepository().nodes);
    });

    test('finds the optimal room-to-room path via the hallway', () {
      final result = pathFinder.findShortestPath('r_301', 'r_302');

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
      final result = pathFinder.findShortestPath('missing', 'r_301');

      expect(result.found, isFalse);
      expect(result.nodeIds, isEmpty);
      expect(result.totalDistance, 0);
    });

    test('returns one point for a same-node route', () {
      final result = pathFinder.findShortestPath('r_301', 'r_301');

      expect(result.found, isTrue);
      expect(result.nodeIds, ['r_301']);
      expect(result.routePoints, hasLength(1));
      expect(result.totalDistance, 0);
    });
  });
}
