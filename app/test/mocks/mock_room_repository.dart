import 'package:wwu_maps_app/features/search/domain/models/room_query.dart';
import 'package:wwu_maps_app/features/search/domain/room_repository.dart';

/// A [RoomRepository] that knows only the rooms the test gives it.
class MockRoomRepository implements RoomRepository {
  MockRoomRepository([this.rooms = const {'101', '214'}]);

  final Set<String> rooms;

  @override
  Future<bool> roomExists(RoomQuery query) async =>
      rooms.contains(query.roomNumber);
}
