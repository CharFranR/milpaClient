class User {
  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.role,
    this.department = '',
    this.municipality = '',
    this.addressLine = '',
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String? ?? '',
    email: json['email'] as String? ?? '',
    firstName: json['first_name'] as String? ?? '',
    lastName: json['last_name'] as String? ?? '',
    phoneNumber: json['phone_number'] as String? ?? '',
    role: (json['role'] as num?)?.toInt() ?? 0,
    department: json['department'] as String? ?? '',
    municipality: json['municipality'] as String? ?? '',
    addressLine: (json['address_line'] ?? json['address']) as String? ?? '',
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
  );

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final int role;
  final String department;
  final String municipality;
  final String addressLine;
  final String? createdAt;
  final String? updatedAt;
}

class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.expiresIn,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    accessToken: json['access_token'] as String? ?? '',
    expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
    user: User.fromJson(
      json['user'] as Map<String, dynamic>? ?? <String, dynamic>{},
    ),
  );

  final String accessToken;
  final int expiresIn;
  final User user;
}
