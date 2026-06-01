import 'package:flutter/material.dart';

class OccupancyItem {
  const OccupancyItem({
    required this.name,
    required this.type,
    required this.typeColor,
    required this.rooms,
  });

  final String name;
  final String type;
  final Color typeColor;
  final List<RoomOccupancy> rooms;
}

class RoomOccupancy {
  const RoomOccupancy({
    required this.name,
    required this.total,
    required this.filled,
  });

  final String name;
  final int total;
  final int filled;
}
