import 'package:wwu_maps_app/features/search/domain/models/room_query.dart';

abstract interface class RoomRepository {
  /// Whether the room the user searched for exists.
  Future<bool> roomExists(RoomQuery query);
}
