import 'package:equatable/equatable.dart';

class PathResult extends Equatable {
  const PathResult({
    required this.nodeIds,
    required this.totalDistance,
    this.found = true,
  });

  final List<String> nodeIds;
  final double totalDistance;
  final bool found;

  @override
  List<Object?> get props => [nodeIds, totalDistance, found];
}
