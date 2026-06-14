import 'package:flutter/material.dart';

import '../core/api_config.dart';
import '../core/app_colors.dart';
import 'branch_item.dart';

class KosItem {
  const KosItem({
    required this.id,
    required this.name,
    required this.type,
    required this.typeColor,
    required this.address,
    required this.areaName,
    required this.area,
    required this.distance,
    required this.price,
    required this.rawPrice,
    required this.imageUrl,
    required this.description,
    required this.facilities,
    required this.availableRooms,
    required this.photos,
    this.averageRating = 0.0,
    this.reviewCount = 0,
  });

  factory KosItem.fromJson(Map<String, dynamic> json) {
    final branch = (json['branch'] as Map?)?.cast<String, dynamic>() ?? {};
    final photos = _photosFromJson(json['photos']);
    final name = '${json['name'] ?? 'KosKuy'}';
    final branchName = '${branch['name'] ?? ''}';
    final rawType =
        '${json['type'] ?? json['gender'] ?? json['category'] ?? json['kos_type'] ?? ''}';
    final type = _resolveType(rawType, '$name $branchName');
    final address = '${branch['address'] ?? json['address'] ?? '-'}';
    final roomSize = json['room_size'] == null ? '-' : '${json['room_size']}m2';
    final facilities = _facilitiesFromJson(json['facilities']);
    return KosItem(
      id: _intValue(json['id']),
      name: name,
      type: type,
      typeColor: type.toLowerCase() == 'putri'
          ? AppColors.pink
          : AppColors.blue,
      address: address,
      areaName: _areaName(address),
      area: roomSize,
      distance: '${json['distance'] ?? '500 m dari Universitas Jember'}',
      price: _rupiah(json['price']),
      rawPrice: _doubleValue(json['price'] ?? json['room_types_min_price']),
      imageUrl: photos.isNotEmpty
          ? ApiConfig.storageUrl(photos.first)
          : 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=600&q=80',
      description:
          '${json['description'] ?? branch['description'] ?? 'Kamar nyaman dengan fasilitas kos yang siap digunakan.'}',
      facilities: facilities,
      availableRooms: _intValue(json['available_rooms_count']),
      photos: photos,
    );
  }

  factory KosItem.fromBranch(BranchItem branch) {
    final name = branch.name;
    final type = _resolveType('', name);
    final available = branch.totalRooms - branch.totalGuests;
    return KosItem(
      id: branch.id,
      name: name,
      type: type,
      typeColor: type.toLowerCase() == 'putri'
          ? AppColors.pink
          : AppColors.blue,
      address: branch.address,
      areaName: _areaName(branch.address),
      area: branch.minRoomSize > 0 ? '${branch.minRoomSize}m2' : '-',
      distance: branch.phone != '-' ? branch.phone : '-',
      price: branch.minPrice > 0 ? _rupiah(branch.minPrice) : '-',
      rawPrice: branch.minPrice,
      imageUrl: branch.photos.isNotEmpty ? branch.photos.first : '',
      description: branch.description,
      facilities: branch.facilities,
      availableRooms: available,
      photos: branch.photos,
      averageRating: branch.averageRating,
      reviewCount: branch.reviewCount,
    );
  }

  final String name;
  final int id;
  final String type;
  final Color typeColor;
  final String address;
  final String areaName;
  final String area;
  final String distance;
  final String price;
  final double rawPrice;
  final String imageUrl;
  final String description;
  final List<String> facilities;
  final int availableRooms;
  final List<String> photos;
  final double averageRating;
  final int reviewCount;

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

  static String _resolveType(String rawType, String source) {
    final normalizedType = rawType.toLowerCase();
    final normalizedSource = source.toLowerCase();
    if (normalizedType.contains('putri') ||
        normalizedSource.contains('putri')) {
      return 'Putri';
    }
    if (normalizedType.contains('putra') ||
        normalizedSource.contains('putra')) {
      return 'Putra';
    }
    return 'Putra';
  }

  static String _areaName(String address) {
    final parts = address.split(',');
    final first = parts.first.trim();
    if (first.isEmpty || first == '-') return '-';
    final noIndex = first.toLowerCase().indexOf(' no');
    return noIndex > 0 ? first.substring(0, noIndex).trim() : first;
  }

  static String _rupiah(dynamic value) {
    final number = value is num
        ? value.round()
        : double.tryParse('$value')?.round() ?? 0;
    final text = number.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < text.length; index++) {
      final remaining = text.length - index;
      buffer.write(text[index]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    return 'Rp$buffer';
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
        .toList();
  }
}
