import 'package:sqflite/sqflite.dart';
import '../models/user_profile.dart';
import 'database_helper.dart';

/// Repository for user profile operations
class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Get user profile (only one user supported)
  Future<UserProfile?> getUserProfile() async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'users',
        orderBy: 'id DESC',
        limit: 1,
      );

      if (results.isEmpty) {
        return null;
      }

      return UserProfile.fromMap(results.first);
    } catch (e) {
      print('[UserRepository] Error getting user profile: $e');
      return null;
    }
  }

  /// Save or update user profile
  Future<int> saveUserProfile(UserProfile profile) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().toIso8601String();

      // Check if user exists
      final existing = await getUserProfile();

      if (existing != null && existing.id != null) {
        // Update existing user
        return await db.update(
          'users',
          {
            ...profile.toMap(),
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [existing.id],
        );
      } else {
        // Insert new user
        return await db.insert(
          'users',
          {
            ...profile.toMap(),
            'created_at': now,
            'updated_at': now,
          },
        );
      }
    } catch (e) {
      print('[UserRepository] Error saving user profile: $e');
      rethrow;
    }
  }

  /// Delete user profile
  Future<int> deleteUserProfile() async {
    try {
      final db = await _dbHelper.database;
      return await db.delete('users');
    } catch (e) {
      print('[UserRepository] Error deleting user profile: $e');
      rethrow;
    }
  }

  /// Check if user profile exists
  Future<bool> hasProfile() async {
    final profile = await getUserProfile();
    return profile != null;
  }
}

