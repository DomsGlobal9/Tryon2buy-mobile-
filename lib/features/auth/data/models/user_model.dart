class UserModel {
  final String id;
  final String? email;
  final String? name;
  final String? phone;
  final String? storeName;
  final String? companyName;
  final String? businessType;
  final int drapeCredits;
  final int userTryonCredits;
  final int bgChangeCredits;
  final int blouseChangeCredits;
  final bool isUnlimited;

  /// `merchant` or `b2b_client` (the backend's `vendor.role`); `vendor` for
  /// a freshly registered account, whose JWT is signed with that legacy role.
  final String role;

  UserModel({
    required this.id,
    this.email,
    this.name,
    this.phone,
    this.storeName,
    this.companyName,
    this.businessType,
    this.drapeCredits = 0,
    this.userTryonCredits = 0,
    this.bgChangeCredits = 0,
    this.blouseChangeCredits = 0,
    this.isUnlimited = false,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {required String role}) {
    return UserModel(
      id: (json['id'] ?? json['vendorId'])?.toString() ?? '',
      email: json['email']?.toString(),
      name: json['name']?.toString(),
      phone: (json['mobileNumber'] ?? json['mobile_number'] ?? json['phone'])?.toString(),
      storeName: (json['storeName'] ?? json['store_name'])?.toString(),
      companyName: (json['companyName'] ?? json['company_name'])?.toString(),
      businessType: (json['businessType'] ?? json['business_type'])?.toString(),
      drapeCredits: _asInt(json['drapeCredits'] ?? json['drape_credits']),
      userTryonCredits: _asInt(json['userTryonCredits'] ?? json['user_tryon_credits']),
      bgChangeCredits: _asInt(json['bgChangeCredits'] ?? json['bg_change_credits']),
      blouseChangeCredits: _asInt(json['blouseChangeCredits'] ?? json['blouse_change_credits']),
      isUnlimited: json['isUnlimited'] == true || json['is_unlimited'] == true,
      role: role,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'phone': phone,
        'mobileNumber': phone,
        'storeName': storeName,
        'companyName': companyName,
        'businessType': businessType,
        'drapeCredits': drapeCredits,
        'userTryonCredits': userTryonCredits,
        'bgChangeCredits': bgChangeCredits,
        'blouseChangeCredits': blouseChangeCredits,
        'isUnlimited': isUnlimited,
        'role': role,
      };

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? storeName,
    String? companyName,
    String? businessType,
    int? drapeCredits,
    int? userTryonCredits,
    int? bgChangeCredits,
    int? blouseChangeCredits,
    bool? isUnlimited,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      storeName: storeName ?? this.storeName,
      companyName: companyName ?? this.companyName,
      businessType: businessType ?? this.businessType,
      drapeCredits: drapeCredits ?? this.drapeCredits,
      userTryonCredits: userTryonCredits ?? this.userTryonCredits,
      bgChangeCredits: bgChangeCredits ?? this.bgChangeCredits,
      blouseChangeCredits: blouseChangeCredits ?? this.blouseChangeCredits,
      isUnlimited: isUnlimited ?? this.isUnlimited,
      role: role ?? this.role,
    );
  }

  static int _asInt(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
