import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wwu_maps_app/features/search/domain/models/room_query.dart';
import 'package:wwu_maps_app/features/search/presentation/cubit/search_state.dart';

/// Holds the destination the user searched for.
class SearchCubit extends Cubit<SearchState> {
  SearchCubit() : super(const SearchIdle());

  /// Submits the text from the search bar. Blank text is ignored.
  void submit(String text) {
    final query = RoomQuery.parse(text);
    if (query == null) {
      return;
    }
    emit(SearchSubmitted(query));
  }
}
