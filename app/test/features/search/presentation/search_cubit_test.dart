import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wwu_maps_app/features/search/domain/models/room_query.dart';
import 'package:wwu_maps_app/features/search/presentation/cubit/search_cubit.dart';
import 'package:wwu_maps_app/features/search/presentation/cubit/search_state.dart';

void main() {
  test('starts out idle', () {
    expect(SearchCubit().state, const SearchIdle());
  });

  blocTest<SearchCubit, SearchState>(
    'emits the submitted room without surrounding spaces',
    build: SearchCubit.new,
    act: (cubit) => cubit.submit(' 101 '),
    expect: () => [const SearchSubmitted(RoomQuery(roomNumber: '101'))],
  );

  blocTest<SearchCubit, SearchState>(
    'ignores blank text',
    build: SearchCubit.new,
    act: (cubit) => cubit.submit('   '),
    expect: () => <SearchState>[],
  );

  blocTest<SearchCubit, SearchState>(
    'emits each new search',
    build: SearchCubit.new,
    act: (cubit) {
      cubit.submit('101');
      cubit.submit('214');
    },
    expect: () => [
      const SearchSubmitted(RoomQuery(roomNumber: '101')),
      const SearchSubmitted(RoomQuery(roomNumber: '214')),
    ],
  );
}
