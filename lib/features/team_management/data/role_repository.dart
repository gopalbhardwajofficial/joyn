import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/api_service.dart';
import '../models/team_member_model.dart';

class RoleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<RoleModel>> getRoles() async {
    final db = await _dbHelper.database;

    // 1. Fetch real-time roles from cloud API
    try {
      final res = await ApiService.fetchRoles().timeout(const Duration(seconds: 4));
      if (res['success'] == true && res['roles'] is List) {
        final cloudRoles = (res['roles'] as List)
            .map((r) => RoleModel.fromJson(r as Map<String, dynamic>))
            .toList();

        for (final cr in cloudRoles) {
          await db.insert(
            'roles',
            cr.toDb(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        if (cloudRoles.isNotEmpty) return cloudRoles;
      }
    } catch (e) {
      debugPrint('Error fetching cloud roles: $e');
    }

    // 2. Offline fallback to local SQLite
    final List<Map<String, dynamic>> maps = await db.query(
      'roles',
      orderBy: 'createdAt ASC',
    );
    return maps.map((map) => RoleModel.fromDb(map)).toList();
  }

  Future<void> insertRole(RoleModel role) async {
    final db = await _dbHelper.database;
    await db.insert(
      'roles',
      role.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Sync to cloud
    ApiService.createRole(role.toJson()).catchError((e) {
      debugPrint('Failed to sync role to cloud: $e');
      return {'success': false};
    });
  }

  Future<void> updateRole(RoleModel role) async {
    final db = await _dbHelper.database;
    await db.update(
      'roles',
      role.toDb(),
      where: 'id = ?',
      whereArgs: [role.id],
    );

    // Sync to cloud
    ApiService.updateRole(role.id, role.toJson()).catchError((e) {
      debugPrint('Failed to update role in cloud: $e');
      return {'success': false};
    });
  }

  Future<void> deleteRole(String id) async {
    final db = await _dbHelper.database;
    await db.delete('roles', where: 'id = ?', whereArgs: [id]);

    // Sync to cloud
    ApiService.deleteRole(id).catchError((e) {
      debugPrint('Failed to delete role in cloud: $e');
      return {'success': false};
    });
  }

  Future<void> deleteAllRoles() async {
    final db = await _dbHelper.database;
    await db.delete('roles');
  }
}