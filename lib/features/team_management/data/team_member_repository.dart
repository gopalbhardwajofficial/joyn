import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/api_service.dart';
import '../models/team_member_model.dart';

class TeamMemberRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<TeamMemberModel>> getTeamMembers() async {
    final db = await _dbHelper.database;

    // 1. Try fetching real-time from cloud API
    try {
      final res = await ApiService.fetchTeamMembers().timeout(const Duration(seconds: 4));
      if (res['success'] == true && res['teamMembers'] is List) {
        final cloudMembers = (res['teamMembers'] as List)
            .map((m) => TeamMemberModel.fromJson(m as Map<String, dynamic>))
            .toList();

        // Sync fresh server truth to SQLite
        await db.delete('team_members');
        for (final cm in cloudMembers) {
          await db.insert(
            'team_members',
            cm.toDb(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        return cloudMembers;
      }
    } catch (e) {
      debugPrint('Error fetching cloud team members: $e');
    }

    // 2. Offline fallback to local SQLite
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

    // Sync to cloud and update local SQLite with the server-generated UUID
    try {
      final res = await ApiService.createTeamMember(member.toJson());
      if (res['success'] == true && res['teamMember'] != null) {
        final serverMap = res['teamMember'] as Map<String, dynamic>;
        final serverMember = TeamMemberModel.fromJson(serverMap);
        if (serverMember.id != member.id) {
          await db.delete('team_members', where: 'id = ?', whereArgs: [member.id]);
          await db.insert(
            'team_members',
            serverMember.toDb(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to sync team member to cloud: $e');
    }
  }

  Future<void> updateTeamMember(TeamMemberModel member) async {
    final db = await _dbHelper.database;
    await db.update(
      'team_members',
      member.toDb(),
      where: 'id = ?',
      whereArgs: [member.id],
    );

    try {
      await ApiService.updateTeamMember(member.id, member.toJson());
    } catch (e) {
      debugPrint('Failed to update team member in cloud: $e');
    }
  }

  Future<void> deleteTeamMember(String id) async {
    final db = await _dbHelper.database;
    await db.delete('team_members', where: 'id = ?', whereArgs: [id]);

    try {
      await ApiService.deleteTeamMember(id);
    } catch (e) {
      debugPrint('Failed to delete team member in cloud: $e');
    }
  }

  Future<void> toggleMemberActive(String id, bool isActive) async {
    final db = await _dbHelper.database;
    await db.update(
      'team_members',
      {'isActive': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );

    try {
      await ApiService.toggleTeamMemberStatus(id, isActive);
    } catch (e) {
      debugPrint('Failed to toggle member status in cloud: $e');
    }
  }

  Future<void> deleteAllTeamMembers() async {
    final db = await _dbHelper.database;
    await db.delete('team_members');
  }
}