import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wwu_maps_app/features/path-planning/domain/models/graph_node.dart';
import 'package:wwu_maps_app/features/path-planning/domain/path_planning_repository.dart';
import 'package:wwu_maps_app/features/path-planning/presentation/cubit/path_planning_state.dart';

class PathPlanningCubit extends Cubit<PathPlanningState> {
  PathPlanningCubit(this._repository) : super(const PathPlanningIdle());

  final PathPlanningRepository _repository;

  Map<String, GraphNode> get nodes => _repository.nodes;

  void showShortestPath(String startId, String endId) {
    final result = _repository.findShortestPath(startId, endId);
    if (result.found) {
      emit(PathPlanningResult(result));
    } else {
      emit(PathPlanningNotFound(startId, endId));
    }
  }

  void clear() => emit(const PathPlanningIdle());
}
