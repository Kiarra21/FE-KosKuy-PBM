class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.address,
    this.profilePicture,
    this.isActive = true,
    this.branchId,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      name: '${json['name'] ?? ''}',
      email: '${json['email'] ?? ''}',
      role: '${json['role'] ?? ''}',
      phone: json['phone'] == null ? null : '${json['phone']}',
      address: json['address'] == null ? null : '${json['address']}',
      profilePicture: json['profile_picture'] == null
          ? null
          : '${json['profile_picture']}',
      isActive: _boolValue(json['is_active'], fallback: true),
      branchId: json['branch_id'] is int
          ? json['branch_id'] as int
          : int.tryParse('${json['branch_id'] ?? ''}'),
    );
  }

  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? address;
  final String? profilePicture;
  final bool isActive;
  final int? branchId;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'address': address,
      'profile_picture': profilePicture,
      'is_active': isActive,
      'branch_id': branchId,
    };
  }
}

bool _boolValue(dynamic value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = '${value ?? ''}'.trim().toLowerCase();
  if (text.isEmpty || text == 'null') return fallback;
  if (text == 'true' || text == '1' || text == 'yes' || text == 'aktif') {
    return true;
  }
  if (text == 'false' ||
      text == '0' ||
      text == 'no' ||
      text == 'nonaktif' ||
      text == 'inactive') {
    return false;
  }
  return fallback;
}
