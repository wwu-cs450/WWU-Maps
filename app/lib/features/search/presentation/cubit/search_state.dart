import 'package:equatable/equatable.dart';

import 'package:wwu_maps_app/features/search/domain/models/room_query.dart';

sealed class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

/// Nothing has been searched for yet.
final class SearchIdle extends SearchState {
  const SearchIdle();
}

/// The user submitted a destination.
final class SearchSubmitted extends SearchState {
  const SearchSubmitted(this.query);

  final RoomQuery query;

  @override
  List<Object?> get props => [query];
}
