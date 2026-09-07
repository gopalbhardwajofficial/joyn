import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/team_member_model.dart';

class RoleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<RoleModel>> getRoles() async {
    final db = await _dbHelper.database;
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
  }

  Future<void> updateRole(RoleModel role) async {
    final db = await _dbHelper.database;
    await db.update(
      'roles',
      role.toDb(),
      where: 'id = ?',
      whereArgs: [role.id],
    );
  }

  Future<void> deleteRole(String id) async {
    final db = await _dbHelper.database;
    await db.delete('roles', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllRoles() async {
    final db = await _dbHelper.database;
    await db.delete('roles');
  }
}