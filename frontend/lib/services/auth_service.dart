import '../models/user_role.dart';
import 'api_client.dart';
import 'session_service.dart';

class AuthService {
  AuthService._();

  static Future<UserRole> signIn({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post(
      '/api/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    final role = userRoleFromFirestore(response['role']);
    await SessionService.save(
      accessToken: (response['access_token'] ?? '').toString(),
      id: _toInt(response['user_id']),
      userName: (response['name'] ?? 'User').toString(),
      userEmail: (response['email'] ?? email).toString(),
      userRole: role,
      userLocation: (response['location'] ?? 'Edappally, Kochi').toString(),
    );

    return role;
  }

  static Future<UserRole> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final response = await ApiClient.post(
      '/api/auth/signup',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'role': role.firestoreValue,
      },
    );

    final parsedRole = userRoleFromFirestore(response['role']);
    await SessionService.save(
      accessToken: (response['access_token'] ?? '').toString(),
      id: _toInt(response['user_id']),
      userName: (response['name'] ?? name).toString(),
      userEmail: (response['email'] ?? email).toString(),
      userRole: parsedRole,
      userLocation: (response['location'] ?? 'Edappally, Kochi').toString(),
    );

    return parsedRole;
  }

  static Future<UserRole> getCurrentUserRole() async {
    if (!SessionService.isLoggedIn) {
      return UserRole.customer;
    }

    final response = await ApiClient.get('/api/auth/me', auth: true);
    final role = userRoleFromFirestore(response['role']);
    await SessionService.save(
      accessToken: (response['access_token'] ?? SessionService.token ?? '').toString(),
      id: _toInt(response['user_id']),
      userName: (response['name'] ?? SessionService.name ?? 'User').toString(),
      userEmail: (response['email'] ?? SessionService.email ?? '').toString(),
      userRole: role,
      userLocation: (response['location'] ?? SessionService.location).toString(),
    );
    return role;
  }

  static Future<void> updateLocation(String location) async {
    final response = await ApiClient.put(
      '/api/users/me/location',
      auth: true,
      body: {'location': location},
    );
    await SessionService.updateLocation(
      (response['location'] ?? location).toString(),
    );
  }

  static Future<void> signOut() async {
    await SessionService.clear();
  }

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
