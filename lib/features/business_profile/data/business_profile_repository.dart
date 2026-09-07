import '../../../core/database/database_helper.dart';
import '../models/business_profile_model.dart';

class BusinessProfileRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<BusinessProfileModel?> getBusinessProfile() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'business_profile',
      orderBy: 'updatedAt DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return BusinessProfileModel.fromDb(maps.first);
  }

  Future<void> saveBusinessProfile(BusinessProfileModel profile) async {
    final db = await _dbHelper.database;

    final existingProfile = await getBusinessProfile();

    if (existingProfile != null && existingProfile.id != null) {
      await db.update(
        'business_profile',
        profile.toDb(),
        where: 'id = ?',
        whereArgs: [existingProfile.id],
      );
    } else {
      await db.insert('business_profile', profile.toDb());
    }
  }

  Future<void> deleteBusinessProfile() async {
    final db = await _dbHelper.database;
    await db.delete('business_profile');
  }
}