import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wwu_maps_app/features/search/domain/models/room_query.dart';
import 'package:wwu_maps_app/features/search/presentation/cubit/search_cubit.dart';
import 'package:wwu_maps_app/features/search/presentation/cubit/search_state.dart';

import '../../../mocks/mock_room_repository.dart';

void main() {
  SearchCubit buildCubit() => SearchCubit(MockRoomRepository({'101', '214'}));

  test('starts out idle', () {
    expect(buildCubit().state, const SearchIdle());
  });

  blocTest<SearchCubit, SearchState>(
    'emits the submitted room without surrounding spaces',
    build: buildCubit,
    act: (cubit) => cubit.submit(' 101 '),
    expect: () => [const SearchSubmitted(RoomQuery(roomNumber: '101'))],
  );

  blocTest<SearchCubit, SearchState>(
    'ignores blank text',
    build: buildCubit,
    act: (cubit) => cubit.submit('   '),
    expect: () => <SearchState>[],
  );

  blocTest<SearchCubit, SearchState>(
    'emits each new search',
    build: buildCubit,
    act: (cubit) async {
      await cubit.submit('101');
      await cubit.submit('214');
    },
    expect: () => [
      const SearchSubmitted(RoomQuery(roomNumber: '101')),
      const SearchSubmitted(RoomQuery(roomNumber: '214')),
    ],
  );

  blocTest<SearchCubit, SearchState>(
    'says when the room does not exist',
    build: buildCubit,
    act: (cubit) => cubit.submit('999'),
    expect: () => [const SearchRoomNotFound(RoomQuery(roomNumber: '999'))],
  );

  blocTest<SearchCubit, SearchState>(
    'clears the not found message',
    build: buildCubit,
    seed: () => const SearchRoomNotFound(RoomQuery(roomNumber: '999')),
    act: (cubit) => cubit.clearNotFound(),
    expect: () => [const SearchIdle()],
  );

  blocTest<SearchCubit, SearchState>(
    'keeps a found room when clearing the not found message',
    build: buildCubit,
    seed: () => const SearchSubmitted(RoomQuery(roomNumber: '101')),
    act: (cubit) => cubit.clearNotFound(),
    expect: () => <SearchState>[],
  );
}
