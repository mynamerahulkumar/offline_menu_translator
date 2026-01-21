import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// User model from access_list.csv
class AuthUser {
  final String userid;
  final String password;
  final int accessLevel;

  AuthUser({
    required this.userid,
    required this.password,
    required this.accessLevel,
  });
}

/// Authentication service that validates credentials against bundled CSV.
/// Works fully offline - no network required.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();
  List<AuthUser> _users = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize by loading access list from bundled CSV asset
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final csvString = await rootBundle.loadString(
        'assets/access/access_list.csv',
      );
      _users = _parseCSV(csvString);
      _isInitialized = true;
      debugPrint('AuthService: Loaded ${_users.length} users from access list');
    } catch (e) {
      debugPrint('AuthService: Failed to load access list - $e');
      rethrow;
    }
  }

  /// Parse CSV content into user list
  List<AuthUser> _parseCSV(String csv) {
    final lines = csv.split('\n');
    final users = <AuthUser>[];

    // Skip header row (userid,password,access_level)
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split(',');
      if (parts.length >= 3) {
        users.add(
          AuthUser(
            userid: parts[0].trim(),
            password: parts[1].trim(),
            accessLevel: int.tryParse(parts[2].trim()) ?? 1,
          ),
        );
      }
    }

    return users;
  }

  /// Validate credentials against CSV and store login state
  /// Returns the user's access level on success, null on failure
  Future<int?> login(String userid, String password) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Find matching user
    final user = _users.cast<AuthUser?>().firstWhere(
      (u) => u!.userid == userid && u.password == password,
      orElse: () => null,
    );

    if (user == null) {
      return null; // Invalid credentials
    }

    // Store login state in secure storage
    await _storage.write(key: 'current_user', value: user.userid);
    await _storage.write(
      key: 'access_level',
      value: user.accessLevel.toString(),
    );
    await _storage.write(key: 'is_logged_in', value: 'true');

    debugPrint(
      'AuthService: User ${user.userid} logged in with access level ${user.accessLevel}',
    );
    return user.accessLevel;
  }

  /// Check if user is already logged in
  Future<bool> isLoggedIn() async {
    final value = await _storage.read(key: 'is_logged_in');
    return value == 'true';
  }

  /// Get current logged in user's ID
  Future<String?> getCurrentUser() async {
    return await _storage.read(key: 'current_user');
  }

  /// Get current user's access level (1 = full access for now)
  Future<int> getAccessLevel() async {
    final level = await _storage.read(key: 'access_level');
    return int.tryParse(level ?? '1') ?? 1;
  }

  /// Check if user has required access level
  Future<bool> hasAccess(int requiredLevel) async {
    final userLevel = await getAccessLevel();
    return userLevel >= requiredLevel;
  }

  /// Logout current user
  Future<void> logout() async {
    await _storage.delete(key: 'is_logged_in');
    await _storage.delete(key: 'current_user');
    await _storage.delete(key: 'access_level');
    debugPrint('AuthService: User logged out');
  }
}
