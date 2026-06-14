import '../core/api_config.dart';

class BranchItem {
  const BranchItem({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.longitude,
    required this.latitude,
    required this.phone,
    required this.qrisCodeUrl,
    required this.isActive,
    required this.photos,
    required this.totalRooms,
    required this.totalGuests,
    required this.minPrice,
    required this.minRoomSize,
    required this.facilities,
    this.averageRating = 0.0,
    this.reviewCount = 0,
  });

  factory BranchItem.fromJson(Map<String, dynamic> json) {
    final qris =
        '${json['qris_code_url'] ?? json['qris_code'] ?? json['qris'] ?? ''}';
    return BranchItem(
      id: _intValue(json['id']),
      name: '${json['name'] ?? 'KosKuy'}',
      description: '${json['description'] ?? ''}',
      address: '${json['address'] ?? '-'}',
      longitude: '${json['longitude'] ?? ''}',
      latitude: '${json['latitude'] ?? ''}',
      phone: '${json['phone'] ?? '-'}',
      qrisCodeUrl: qris.isEmpty ? '' : ApiConfig.storageUrl(qris),
      isActive: _boolValue(json['is_active'], fallback: true),
      photos: _photosFromJson(json['photos']),
      totalRooms: _intValue(json['total_rooms'] ?? json['rooms_count']),
      totalGuests: _intValue(json['total_guests'] ?? json['guests_count']),
      // Laravel withMin/loadMin menghasilkan key: room_types_min_price
      minPrice: _doubleValue(json['room_types_min_price']),
      minRoomSize: _intValue(json['room_types_min_room_size']),
      facilities: _facilitiesFromJson(json['facilities']),
      averageRating: _doubleValue(json['reviews_avg_rating']),
      reviewCount: _intValue(json['reviews_count']),
    );
  }

  final int id;
  final String name;
  final String description;
  final String address;
  final String longitude;
  final String latitude;
  final String phone;
  final String qrisCodeUrl;
  final bool isActive;
  final List<String> photos;
  final int totalRooms;
  final int totalGuests;

  /// Harga minimum dari semua tipe kamar cabang ini (0 jika belum ada tipe kamar)
  final double minPrice;

  /// Ukuran kamar minimum (m²) dari semua tipe kamar cabang ini
  final int minRoomSize;
  
  /// Daftar nama fasilitas cabang ini
  final List<String> facilities;

  final double averageRating;
  final int reviewCount;

  BranchItem copyWith({
    List<String>? photos,
    int? totalRooms,
    int? totalGuests,
    double? minPrice,
    int? minRoomSize,
    List<String>? facilities,
    double? averageRating,
    int? reviewCount,
  }) {
    return BranchItem(
      id: id,
      name: name,
      description: description,
      address: address,
      longitude: longitude,
      latitude: latitude,
      phone: phone,
      qrisCodeUrl: qrisCodeUrl,
      isActive: isActive,
      photos: photos ?? this.photos,
      totalRooms: totalRooms ?? this.totalRooms,
      totalGuests: totalGuests ?? this.totalGuests,
      minPrice: minPrice ?? this.minPrice,
      minRoomSize: minRoomSize ?? this.minRoomSize,
      facilities: facilities ?? this.facilities,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  String get locationLabel {
    if (latitude.isEmpty || longitude.isEmpty) return address;
    return '$latitude, $longitude';
  }

  static int _intValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  static double _doubleValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse('$value') ?? 0.0;
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

  static List<String> _photosFromJson(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) {
          if (item is Map) {
            return '${item['photo_url'] ?? item['url'] ?? item['photo'] ?? ''}';
          }
          return '$item';
        })
        .where((item) => item.trim().isNotEmpty)
        .map(ApiConfig.storageUrl)
        .toList();
  }

  static List<String> _facilitiesFromJson(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) {
          if (item is Map) return '${item['name'] ?? ''}';
          return '$item';
        })
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }
}
