import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wwu_maps_app/features/search/domain/models/room_query.dart';
import 'package:wwu_maps_app/features/search/domain/room_repository.dart';
import 'package:wwu_maps_app/features/search/presentation/cubit/search_state.dart';

/// Holds the destination the user searched for.
class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._repository) : super(const SearchIdle());

  final RoomRepository _repository;

  /// Submits the text from the search bar. Blank text is ignored.
  Future<void> submit(String text) async {
    final query = RoomQuery.parse(text);
    if (query == null) {
      return;
    }
    final exists = await _repository.roomExists(query);
    if (isClosed) {
      return;
    }
    emit(exists ? SearchSubmitted(query) : SearchRoomNotFound(query));
  }

  /// Hides the "room not found" message once the user edits the search.
  void clearNotFound() {
    if (state is SearchRoomNotFound) {
      emit(const SearchIdle());
    }
  }
}
