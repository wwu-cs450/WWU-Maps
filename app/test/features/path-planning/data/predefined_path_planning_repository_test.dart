import 'package:flutter_test/flutter_test.dart';
import 'package:wwu_maps_app/features/path-planning/data/predefined_path_planning_repository.dart';

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
  });
}
