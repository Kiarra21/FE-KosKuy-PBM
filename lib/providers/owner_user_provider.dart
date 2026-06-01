import 'package:flutter/foundation.dart';

import '../models/managed_user.dart';
import '../services/owner_user_service.dart';

class OwnerUserProvider extends ChangeNotifier {
  OwnerUserProvider({OwnerUserService service = const OwnerUserService()})
    : _service = service;

  final OwnerUserService _service;
  List<ManagedUser> _users = const [];
  List<ManagedUser> _customers = const [];

  List<ManagedUser> get users => _users;
  List<ManagedUser> get customers => _customers;

  Future<List<ManagedUser>> fetchUsers({
    String? role,
    String? search,
    bool? isActive,
  }) async {
    final items = await _service.fetchUsers(
      role: role,
      search: search,
      isActive: isActive,
    );
    if (role == null && search == null && isActive == null) {
      _users = items;
      notifyListeners();
    }
    return items;
  }

  Future<List<ManagedUser>> fetchCustomers({
    String? search,
    bool? isActive,
  }) async {
    final items = await _service.fetchCustomers(
      search: search,
      isActive: isActive,
    );
    _customers = items;
    notifyListeners();
    return items;
  }

  Future<ManagedUser> createUser({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
    required String phone,
    required String address,
    required bool isActive,
    int? branchId,
  }) async {
    final item = await _service.createUser(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      role: role,
      phone: phone,
      address: address,
      isActive: isActive,
      branchId: branchId,
    );
    await fetchUsers();
    return item;
  }

  Future<ManagedUser> updateUser({
    required int id,
    required String name,
    required String email,
    required String role,
    required String phone,
    required String address,
    required bool isActive,
    String? password,
    int? branchId,
  }) async {
    final item = await _service.updateUser(
      id: id,
      name: name,
      email: email,
      role: role,
      phone: phone,
      address: address,
      isActive: isActive,
      password: password,
      branchId: branchId,
    );
    await fetchUsers();
    return item;
  }

  Future<void> deleteUser(int id) async {
    await _service.deleteUser(id);
    await fetchUsers();
  }

  Future<void> updateCustomerStatus(int id, bool isActive) async {
    await _service.updateCustomerStatus(id, isActive);
    await fetchCustomers();
  }

  Future<ManagedUser> fetchCustomer(int id) {
    return _service.fetchCustomer(id);
  }

  Future<void> assignAdminToBranch({
    required int branchId,
    required int userId,
  }) async {
    await _service.assignAdminToBranch(branchId: branchId, userId: userId);
    notifyListeners();
  }

  Future<List<ManagedUser>> fetchBranchAdmins(int branchId) {
    return _service.fetchBranchAdmins(branchId);
  }

  Future<List<ManagedUser>> fetchAvailableBranchAdmins(int branchId) {
    return _service.fetchAvailableBranchAdmins(branchId);
  }

  Future<void> detachAdminFromBranch({
    required int branchId,
    required int userId,
  }) async {
    await _service.detachAdminFromBranch(branchId: branchId, userId: userId);
    notifyListeners();
  }
}
