import 'package:equatable/equatable.dart';
import 'package:wwu_maps_app/features/path-planning/domain/models/path_result.dart';

sealed class PathPlanningState extends Equatable {
  const PathPlanningState();

  @override
  List<Object?> get props => [];
}

final class PathPlanningIdle extends PathPlanningState {
  const PathPlanningIdle();
}

final class PathPlanningResult extends PathPlanningState {
  const PathPlanningResult(this.result);

  final PathResult result;

  @override
  List<Object?> get props => [result];
}

final class PathPlanningNotFound extends PathPlanningState {
  const PathPlanningNotFound(this.startId, this.endId);

  final String startId;
  final String endId;

  @override
  List<Object?> get props => [startId, endId];
}
