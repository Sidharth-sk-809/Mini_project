import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_role.dart';

class SessionService {
  SessionService._();

  static const _kToken = 'api_token';
  static const _kUserId = 'user_id';
  static const _kName = 'user_name';
  static const _kEmail = 'user_email';
  static const _kRole = 'user_role';
  static const _kLocation = 'user_location';

  static String? token;
  static int? userId;
  static String? name;
  static String? email;
  static UserRole? role;
  static String location = 'Edappally, Kochi';

  static bool get isLoggedIn => (token ?? '').isNotEmpty;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_kToken);
    userId = prefs.getInt(_kUserId);
    name = prefs.getString(_kName);
    email = prefs.getString(_kEmail);
    role = userRoleFromFirestore(prefs.getString(_kRole));
    location = prefs.getString(_kLocation) ?? 'Edappally, Kochi';
  }

  static Future<void> save({
    required String accessToken,
    required int id,
    required String userName,
    required String userEmail,
    required UserRole userRole,
    required String userLocation,
  }) async {
    token = accessToken;
    userId = id;
    name = userName;
    email = userEmail;
    role = userRole;
    location = userLocation;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, accessToken);
    await prefs.setInt(_kUserId, id);
    await prefs.setString(_kName, userName);
    await prefs.setString(_kEmail, userEmail);
    await prefs.setString(_kRole, userRole.firestoreValue);
    await prefs.setString(_kLocation, userLocation);
  }

  static Future<void> updateLocation(String userLocation) async {
    location = userLocation;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocation, userLocation);
  }

  static Future<void> clear() async {
    token = null;
    userId = null;
    name = null;
    email = null;
    role = null;
    location = 'Edappally, Kochi';

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUserId);
    await prefs.remove(_kName);
    await prefs.remove(_kEmail);
    await prefs.remove(_kRole);
    await prefs.remove(_kLocation);
  }
}
