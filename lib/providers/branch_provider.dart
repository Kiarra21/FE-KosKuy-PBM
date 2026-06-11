import 'package:flutter/foundation.dart';

import '../models/branch_item.dart';
import '../models/branch_photo_item.dart';
import '../models/facility_item.dart';
import '../services/auth_service.dart';
import '../services/branch_service.dart';

class BranchProvider extends ChangeNotifier {
  BranchProvider({BranchService service = const BranchService()})
    : _service = service;

  final BranchService _service;
  List<BranchItem> _branches = const [];
  List<FacilityItem> _facilities = const [];
  final Map<int, BranchItem> _details = {};
  bool _loading = false;
  String? _errorMessage;

  List<BranchItem> get branches => _branches;
  List<FacilityItem> get facilities => _facilities;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  BranchItem? detailFor(int id) => _details[id];

  Future<void> fetchBranches({int page = 1}) async {
    await _load(() async {
      _branches = await _service.fetchBranches(page: page);
    }, 'Tidak bisa memuat data cabang.');
  }

  Future<BranchItem> fetchBranch(int id) async {
    final detail = await _service.fetchBranch(id);
    _details[id] = detail;
    notifyListeners();
    return detail;
  }

  Future<BranchItem> createBranch({
    required String name,
    required String description,
    required String address,
    required String longitude,
    required String latitude,
    required String phone,
    required List<int> qrisBytes,
    required String qrisFilename,
    bool isActive = true,
  }) async {
    final item = await _service.createBranch(
      name: name,
      description: description,
      address: address,
      longitude: longitude,
      latitude: latitude,
      phone: phone,
      qrisBytes: qrisBytes,
      qrisFilename: qrisFilename,
      isActive: isActive,
    );
    await fetchBranches();
    return item;
  }

  Future<BranchItem> updateBranch({
    required int id,
    required String name,
    required String description,
    required String address,
    required String longitude,
    required String latitude,
    required String phone,
    List<int>? qrisBytes,
    String? qrisFilename,
    required bool isActive,
  }) async {
    final item = await _service.updateBranch(
      id: id,
      name: name,
      description: description,
      address: address,
      longitude: longitude,
      latitude: latitude,
      phone: phone,
      qrisBytes: qrisBytes,
      qrisFilename: qrisFilename,
      isActive: isActive,
    );
    _details[id] = item;
    await fetchBranches();
    return item;
  }

  Future<void> deleteBranch(int id) async {
    await _service.deleteBranch(id);
    _details.remove(id);
    await fetchBranches();
  }

  Future<void> uploadBranchPhoto({
    required int branchId,
    required List<int> photoBytes,
    required String filename,
    int? order,
  }) async {
    await _service.uploadBranchPhoto(
      branchId: branchId,
      photoBytes: photoBytes,
      filename: filename,
      order: order,
    );
    await fetchBranch(branchId);
  }

  Future<List<BranchPhotoItem>> fetchBranchPhotoItems(int id) {
    return _service.fetchBranchPhotoItems(id);
  }

  Future<void> deleteBranchPhoto(int branchId, int photoId) async {
    await _service.deleteBranchPhoto(photoId);
    await fetchBranch(branchId);
  }

  Future<void> updateBranchPhotoOrder(
    int branchId,
    int photoId,
    int order,
  ) async {
    await _service.updateBranchPhotoOrder(photoId, order);
    await fetchBranch(branchId);
  }

  Future<void> fetchFacilities({int page = 1}) async {
    await _load(() async {
      _facilities = await _service.fetchFacilities(page: page);
    }, 'Tidak bisa memuat fasilitas.');
  }

  Future<FacilityItem> createFacility(String name) async {
    final item = await _service.createFacility(name);
    await fetchFacilities();
    return item;
  }

  Future<FacilityItem> updateFacility(int id, String name) async {
    final item = await _service.updateFacility(id, name);
    await fetchFacilities();
    return item;
  }

  Future<void> deleteFacility(int id) async {
    await _service.deleteFacility(id);
    await fetchFacilities();
  }

  Future<List<FacilityItem>> fetchBranchFacilities(int branchId) {
    return _service.fetchBranchFacilities(branchId);
  }

  Future<void> syncBranchFacilities(int branchId, List<int> facilityIds) {
    return _service.syncBranchFacilities(branchId, facilityIds);
  }

  Future<void> _load(
    Future<void> Function() action,
    String fallbackMessage,
  ) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = fallbackMessage;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
