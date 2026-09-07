import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/team_member_model.dart';

class TeamMemberRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<TeamMemberModel>> getTeamMembers() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'team_members',
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => TeamMemberModel.fromDb(map)).toList();
  }

  Future<void> insertTeamMember(TeamMemberModel member) async {
    final db = await _dbHelper.database;
    await db.insert(
      'team_members',
      member.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTeamMember(TeamMemberModel member) async {
    final db = await _dbHelper.database;
    await db.update(
      'team_members',
      member.toDb(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<void> deleteTeamMember(String id) async {
    final db = await _dbHelper.database;
    await db.delete('team_members', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleMemberActive(String id, bool isActive) async {
    final db = await _dbHelper.database;
    await db.update(
      'team_members',
      {'isActive': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllTeamMembers() async {
    final db = await _dbHelper.database;
    await db.delete('team_members');
  }
}