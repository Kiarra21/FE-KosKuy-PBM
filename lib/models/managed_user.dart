class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    required this.address,
    required this.branchId,
    required this.isActive,
  });

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    return ManagedUser(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      name: '${json['name'] ?? ''}',
      email: '${json['email'] ?? ''}',
      role: '${json['role'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      address: '${json['address'] ?? ''}',
      branchId: _nullableInt(json['branch_id']),
      isActive: _boolValue(json['is_active'], fallback: true),
    );
  }

  final int id;
  final String name;
  final String email;
  final String role;
  final String phone;
  final String address;
  final int? branchId;
  final bool isActive;

  static int? _nullableInt(dynamic value) {
    if (value == null || '$value'.isEmpty) return null;
    if (value is int) return value;
    return int.tryParse('$value');
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
