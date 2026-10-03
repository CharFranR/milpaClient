enum RegisterRole {

  buyer(1),

  producer(2);

  const RegisterRole(this.roleId);

  /// Valor entero exacto que espera el backend en el campo `role`.
  final int roleId;
}

class RegisterUserRequest {
  const RegisterUserRequest({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.phoneNumber,
    required this.password,
    required this.confirmPassword,
    this.address = '',
    this.department = '',
    this.municipality = '',
  });

  final String email;
  final String firstName;
  final String lastName;

  /// Se serializa como entero (1 o 2), nunca como string.
  final RegisterRole role;

  final String address;
  final String department;
  final String municipality;

  final String phoneNumber;
  final String password;
  final String confirmPassword;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role.roleId,
      'password': password,
      'confirm_password': confirmPassword,
      'phone_number': phoneNumber,
    };

    if (address.isNotEmpty) json['address'] = address;
    if (department.isNotEmpty) json['department'] = department;
    if (municipality.isNotEmpty) json['municipality'] = municipality;

    return json;
  }
}
