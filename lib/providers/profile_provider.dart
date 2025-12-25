import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../repository/user_repository.dart';

/// Provider for user profile management
class ProfileProvider with ChangeNotifier {
  final UserRepository _repository = UserRepository();
  
  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProfile => _profile != null;
  
  int? get dailyCalorieGoal => _profile?.dailyCalorieGoal;
  int? get age => _profile?.age;
  String? get gender => _profile?.gender;

  /// Load user profile from database
  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _repository.getUserProfile();
      _error = null;
    } catch (e) {
      _error = 'Profil yüklenirken hata oluştu: $e';
      print('[ProfileProvider] Error loading profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save user profile
  Future<bool> saveProfile({
    required int age,
    required String gender,
    required int dailyCalorieGoal,
  }) async {
    // Validate inputs
    final ageError = UserProfile.validateAge(age);
    if (ageError != null) {
      _error = ageError;
      notifyListeners();
      return false;
    }

    final genderError = UserProfile.validateGender(gender);
    if (genderError != null) {
      _error = genderError;
      notifyListeners();
      return false;
    }

    final goalError = UserProfile.validateCalorieGoal(dailyCalorieGoal);
    if (goalError != null) {
      _error = goalError;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newProfile = UserProfile(
        id: _profile?.id,
        age: age,
        gender: gender,
        dailyCalorieGoal: dailyCalorieGoal,
      );

      await _repository.saveUserProfile(newProfile);
      _profile = newProfile;
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Profil kaydedilirken hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Check if total calories exceed goal
  bool exceedsCalorieGoal(int totalCalories) {
    if (_profile == null || dailyCalorieGoal == null) {
      return false;
    }
    return totalCalories > dailyCalorieGoal!;
  }

  /// Get remaining calories
  int? getRemainingCalories(int totalCalories) {
    if (_profile == null || dailyCalorieGoal == null) {
      return null;
    }
    return (dailyCalorieGoal! - totalCalories).clamp(0, dailyCalorieGoal!);
  }

  /// Check if should suggest low-calorie recipes
  bool shouldSuggestLowCalorieRecipes() {
    if (_profile == null || dailyCalorieGoal == null) {
      return false;
    }
    return dailyCalorieGoal! < 2000;
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

