import 'package:equatable/equatable.dart';

/// A destination the user typed in the search bar, such as "101".
class RoomQuery extends Equatable {
  const RoomQuery({required this.roomNumber, this.buildingCode});

  final String roomNumber;

  /// The building the room is in, such as "KRH". Null when the user typed
  /// only a room number.
  final String? buildingCode;

  /// Turns raw search text into a [RoomQuery].
  ///
  /// Ignores spaces before and after the text, so " 101 " gives room 101.
  /// Returns null if nothing but spaces was typed.
  static RoomQuery? parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return RoomQuery(roomNumber: trimmed);
  }

  @override
  List<Object?> get props => [roomNumber, buildingCode];
}
