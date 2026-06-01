import 'package:flutter/foundation.dart';

import '../models/facility_item.dart';
import '../models/managed_room.dart';
import '../services/owner_room_service.dart';

class OwnerRoomProvider extends ChangeNotifier {
  OwnerRoomProvider({OwnerRoomService service = const OwnerRoomService()})
    : _service = service;

  final OwnerRoomService _service;
  final Map<int, List<ManagedRoomType>> _roomTypes = {};
  final Map<int, List<ManagedRoom>> _rooms = {};
  final Map<int, List<ManagedRoomPhoto>> _photos = {};
  final Map<int, List<FacilityItem>> _facilities = {};

  List<ManagedRoomType> roomTypesFor(int branchId) =>
      _roomTypes[branchId] ?? const [];
  List<ManagedRoom> roomsFor(int roomTypeId) => _rooms[roomTypeId] ?? const [];
  List<ManagedRoomPhoto> photosFor(int roomTypeId) =>
      _photos[roomTypeId] ?? const [];
  List<FacilityItem> facilitiesFor(int roomTypeId) =>
      _facilities[roomTypeId] ?? const [];

  Future<List<ManagedRoomType>> fetchRoomTypes(int branchId) async {
    final items = await _service.fetchRoomTypes(branchId);
    _roomTypes[branchId] = items;
    notifyListeners();
    return items;
  }

  Future<ManagedRoomType> createRoomType({
    required int branchId,
    required String name,
    required String description,
    required int price,
    required int roomSize,
    required bool isActive,
    required List<int> facilityIds,
  }) async {
    final item = await _service.createRoomType(
      branchId: branchId,
      name: name,
      description: description,
      price: price,
      roomSize: roomSize,
      isActive: isActive,
      facilityIds: facilityIds,
    );
    await fetchRoomTypes(branchId);
    return item;
  }

  Future<ManagedRoomType> updateRoomType({
    required int id,
    required int branchId,
    required String name,
    required String description,
    required int price,
    required int roomSize,
    required bool isActive,
    required List<int> facilityIds,
  }) async {
    final item = await _service.updateRoomType(
      id: id,
      branchId: branchId,
      name: name,
      description: description,
      price: price,
      roomSize: roomSize,
      isActive: isActive,
      facilityIds: facilityIds,
    );
    await fetchRoomTypes(branchId);
    return item;
  }

  Future<void> deleteRoomType(int branchId, int id) async {
    await _service.deleteRoomType(id);
    await fetchRoomTypes(branchId);
  }

  Future<List<ManagedRoom>> fetchRooms(int roomTypeId) async {
    final items = await _service.fetchRooms(roomTypeId);
    _rooms[roomTypeId] = items;
    notifyListeners();
    return items;
  }

  Future<List<FacilityItem>> fetchRoomTypeFacilities(int roomTypeId) async {
    final items = await _service.fetchRoomTypeFacilities(roomTypeId);
    _facilities[roomTypeId] = items;
    notifyListeners();
    return items;
  }

  Future<ManagedRoom> createRoom({
    required int roomTypeId,
    required int number,
    required bool isActive,
    required bool isFilled,
  }) async {
    final item = await _service.createRoom(
      roomTypeId: roomTypeId,
      number: number,
      isActive: isActive,
      isFilled: isFilled,
    );
    await fetchRooms(roomTypeId);
    return item;
  }

  Future<ManagedRoom> updateRoom({
    required int id,
    required int roomTypeId,
    required int number,
    required bool isActive,
    required bool isFilled,
  }) async {
    final item = await _service.updateRoom(
      id: id,
      roomTypeId: roomTypeId,
      number: number,
      isActive: isActive,
      isFilled: isFilled,
    );
    await fetchRooms(roomTypeId);
    return item;
  }

  Future<void> deleteRoom(int roomTypeId, int id) async {
    await _service.deleteRoom(id);
    await fetchRooms(roomTypeId);
  }

  Future<void> uploadRoomTypePhoto({
    required int roomTypeId,
    required List<int> bytes,
    required String filename,
  }) async {
    await _service.uploadRoomTypePhoto(
      roomTypeId: roomTypeId,
      bytes: bytes,
      filename: filename,
    );
    await fetchRoomTypePhotos(roomTypeId);
  }

  Future<List<ManagedRoomPhoto>> fetchRoomTypePhotos(int roomTypeId) async {
    final items = await _service.fetchRoomTypePhotos(roomTypeId);
    _photos[roomTypeId] = items;
    notifyListeners();
    return items;
  }

  Future<void> deleteRoomTypePhoto(int roomTypeId, int id) async {
    await _service.deleteRoomTypePhoto(id);
    await fetchRoomTypePhotos(roomTypeId);
  }

  Future<void> updateRoomTypePhotoOrder(
    int roomTypeId,
    int id,
    int order,
  ) async {
    await _service.updateRoomTypePhotoOrder(id, order);
    await fetchRoomTypePhotos(roomTypeId);
  }
}
