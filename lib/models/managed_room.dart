import '../core/api_config.dart';

class ManagedRoomType {
  const ManagedRoomType({
    required this.id,
    required this.branchId,
    required this.name,
    required this.description,
    required this.price,
    required this.roomSize,
    required this.isActive,
    required this.roomsCount,
    required this.availableRoomsCount,
    required this.facilityIds,
  });

  factory ManagedRoomType.fromJson(Map<String, dynamic> json) {
    final facilities = json['facilities'];
    return ManagedRoomType(
      id: _intValue(json['id']),
      branchId: _intValue(json['branch_id']),
      name: '${json['name'] ?? ''}',
      description: '${json['description'] ?? ''}',
      price: _intValue(json['price']),
      roomSize: _intValue(json['room_size']),
      isActive: _boolValue(json['is_active'], fallback: true),
      roomsCount: _intValue(json['rooms_count']),
      availableRoomsCount: _intValue(json['available_rooms_count']),
      facilityIds: facilities is List
          ? facilities
                .whereType<Map>()
                .map((item) => _intValue(item['id']))
                .where((id) => id > 0)
                .toList()
          : const [],
    );
  }

  final int id;
  final int branchId;
  final String name;
  final String description;
  final int price;
  final int roomSize;
  final bool isActive;
  final int roomsCount;
  final int availableRoomsCount;
  final List<int> facilityIds;

  int get filledRoomsCount => roomsCount - availableRoomsCount;

  static int _intValue(dynamic value) {
    if (value is int) return value;
    return double.tryParse('$value')?.round() ?? 0;
  }

  static bool _boolValue(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value == null) return fallback;
    final text = '$value'.toLowerCase();
    if (text == '1' || text == 'true') return true;
    if (text == '0' || text == 'false') return false;
    return fallback;
  }
}

class ManagedRoom {
  const ManagedRoom({
    required this.id,
    required this.roomTypeId,
    required this.number,
    required this.isActive,
    required this.isFilled,
  });

  factory ManagedRoom.fromJson(Map<String, dynamic> json) {
    return ManagedRoom(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      roomTypeId: json['room_type_id'] is int
          ? json['room_type_id'] as int
          : int.tryParse('${json['room_type_id']}') ?? 0,
      number: '${json['number'] ?? ''}',
      isActive: _boolValue(json['is_active'], fallback: true),
      isFilled: _boolValue(json['is_filled'], fallback: false),
    );
  }

  final int id;
  final int roomTypeId;
  final String number;
  final bool isActive;
  final bool isFilled;

  static bool _boolValue(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value == null) return fallback;
    final text = '$value'.toLowerCase();
    if (text == '1' || text == 'true') return true;
    if (text == '0' || text == 'false') return false;
    return fallback;
  }
}

class ManagedRoomPhoto {
  const ManagedRoomPhoto({
    required this.id,
    required this.url,
    required this.order,
  });

  factory ManagedRoomPhoto.fromJson(Map<String, dynamic> json) {
    return ManagedRoomPhoto(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      url: ApiConfig.storageUrl('${json['photo_url'] ?? json['photo'] ?? ''}'),
      order: json['order'] is int
          ? json['order'] as int
          : int.tryParse('${json['order']}') ?? 0,
    );
  }

  final int id;
  final String url;
  final int order;
}
