import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/local_storage_service.dart';
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

    if (maps.isNotEmpty) {
      final local = BusinessProfileModel.fromDb(maps.first);
      if (local.businessName.trim().isNotEmpty && local.businessName.trim() != 'My Business') {
        return local;
      }
    }

    // Fallback: Fetch real business profile from cloud API
    try {
      final res = await ApiService.getBusinessProfile().timeout(const Duration(seconds: 4));
      if (res['success'] == true && res['profile'] != null) {
        final profileMap = Map<String, dynamic>.from(res['profile']);
        final cloudProfile = BusinessProfileModel.fromJson(profileMap);
        await saveBusinessProfile(cloudProfile);
        return cloudProfile;
      }
    } catch (e) {
      debugPrint('Cloud business profile fetch failed: $e');
    }

    if (maps.isNotEmpty) {
      return BusinessProfileModel.fromDb(maps.first);
    }

    // Fallback to LocalStorageService business info
    final storedBizName = LocalStorageService().businessName.trim();
    if (storedBizName.isNotEmpty && storedBizName != 'My Business') {
      return BusinessProfileModel(
        businessName: storedBizName,
        ownerName: LocalStorageService().userName,
        gstNumber: '',
        businessType: 'Retail Business',
        businessCategory: 'General',
        phone1: LocalStorageService().phoneNumber,
        phone2: '',
        email: LocalStorageService().email,
        website: '',
        address: '',
        city: '',
        state: 'Delhi',
        pincode: '',
        country: 'India',
        description: '',
        booksStartDate: '01/04/2026',
        showGstOnCard: true,
        showBusinessTypeOnCard: true,
        showCategoryOnCard: true,
        updatedAt: DateTime.now(),
      );
    }

    return null;
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