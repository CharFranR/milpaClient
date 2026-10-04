import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/models/auth_models.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/auth/user_repository.dart';

const User defaultFakeUser = User(
  id: 'user-1',
  email: 'oscar@milpa.com',
  firstName: 'Oscar',
  lastName: 'Reyes',
  phoneNumber: '+505 8888 1234',
  role: 2,
  department: 'Masaya',
  municipality: 'Masate',
);

class FakeUserRepository extends UserRepository {
  FakeUserRepository({this.current})
    : super(apiClient: ApiClient(), tokenStore: TokenStore());

  User? current;
  Object? fetchError;
  Object? updateError;
  int fetchCalls = 0;
  int updateCalls = 0;
  final Map<String, String> lastUpdate = <String, String>{};
  double? lastUpdatedLatitude;
  double? lastUpdatedLongitude;

  @override
  Future<User> fetchCurrent() async {
    fetchCalls++;
    if (fetchError != null) throw fetchError!;
    return current ?? defaultFakeUser;
  }

  @override
  Future<User> updateCurrent({
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? address,
    String? department,
    String? municipality,
    double? latitude,
    double? longitude,
  }) async {
    updateCalls++;
    lastUpdatedLatitude = latitude;
    lastUpdatedLongitude = longitude;
    if (email != null) lastUpdate['email'] = email;
    if (firstName != null) lastUpdate['firstName'] = firstName;
    if (lastName != null) lastUpdate['lastName'] = lastName;
    if (phoneNumber != null) lastUpdate['phoneNumber'] = phoneNumber;
    if (address != null) lastUpdate['address'] = address;
    if (department != null) lastUpdate['department'] = department;
    if (municipality != null) lastUpdate['municipality'] = municipality;
    if (updateError != null) throw updateError!;

    final User base = current ?? defaultFakeUser;
    final User updated = User(
      id: base.id,
      email: email ?? base.email,
      firstName: firstName ?? base.firstName,
      lastName: lastName ?? base.lastName,
      phoneNumber: phoneNumber ?? base.phoneNumber,
      role: base.role,
      department: department ?? base.department,
      municipality: municipality ?? base.municipality,
      addressLine: address ?? base.addressLine,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
    );
    current = updated;
    return updated;
  }
}
