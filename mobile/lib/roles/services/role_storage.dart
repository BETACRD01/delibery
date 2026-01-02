// lib/role_switch/services/role_storage.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/roles.dart';

class RoleStorage {
  static const _key = 'app_active_role';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<AppRole?> getRole() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return null;
    return parseRole(raw);
  }

  Future<void> setRole(AppRole role) async {
    await _storage.write(key: _key, value: roleToApi(role));
  }

  Future<void> clearRole() async {
    await _storage.delete(key: _key);
  }
}
