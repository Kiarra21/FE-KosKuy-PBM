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
      isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
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
