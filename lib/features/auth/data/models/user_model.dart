class UserModel {
  final String id;
  final String? email;
  final String? name;
  final String? phone;
  final String? storeName;
  /// `merchant` or `b2b_client` (the backend's `vendor.role`); `vendor` for
  /// a freshly registered account, whose JWT is signed with that legacy role.
  final String role;

  UserModel({
    required this.id,
    this.email,
    this.name,
    this.phone,
    this.storeName,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {required String role}) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String?,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      storeName: json['storeName'] as String? ?? json['store_name'] as String?,
      role: role,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'phone': phone,
        'storeName': storeName,
        'role': role,
      };
}
