import 'package:wwu_maps_app/features/search/domain/models/room_query.dart';
import 'package:wwu_maps_app/features/search/domain/room_repository.dart';

/// Stands in until the building data lists the real rooms.
class PlaceholderRoomRepository implements RoomRepository {
  const PlaceholderRoomRepository();

  @override
  Future<bool> roomExists(RoomQuery query) async => true;
}
