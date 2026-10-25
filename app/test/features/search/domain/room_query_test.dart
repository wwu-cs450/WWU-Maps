import 'package:flutter_test/flutter_test.dart';
import 'package:wwu_maps_app/features/search/domain/models/room_query.dart';

void main() {
  group('RoomQuery.parse', () {
    test('reads a room number', () {
      expect(RoomQuery.parse('101'), const RoomQuery(roomNumber: '101'));
    });

    test('ignores spaces before and after the room number', () {
      expect(RoomQuery.parse(' 101 '), const RoomQuery(roomNumber: '101'));
    });

    test('returns null when nothing was typed', () {
      expect(RoomQuery.parse(''), isNull);
    });

    test('returns null when only spaces were typed', () {
      expect(RoomQuery.parse('   '), isNull);
    });
  });
}
