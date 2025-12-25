import 'package:flutter_test/flutter_test.dart';
import 'package:yemek_yardimci_app/providers/profile_provider.dart';
import 'package:yemek_yardimci_app/models/user_profile.dart';

void main() {
  group('ProfileProvider Tests', () {
    late ProfileProvider provider;

    setUp(() {
      provider = ProfileProvider();
    });

    test('initial state should have no profile', () {
      expect(provider.profile, isNull);
      expect(provider.hasProfile, false);
      expect(provider.isLoading, false);
    });

    test('saveProfile validates age correctly', () async {
      final result = await provider.saveProfile(
        age: 15, // Invalid: too young
        gender: 'Erkek',
        dailyCalorieGoal: 2000,
      );

      expect(result, false);
      expect(provider.error, 'Yaş en az 18 olmalıdır');
    });

    test('saveProfile validates calorie goal correctly', () async {
      final result = await provider.saveProfile(
        age: 25,
        gender: 'Erkek',
        dailyCalorieGoal: 500, // Invalid: too low
      );

      expect(result, false);
      expect(provider.error, 'Günlük kalori hedefi en az 1000 olmalıdır');
    });

    test('saveProfile validates gender correctly', () async {
      final result = await provider.saveProfile(
        age: 25,
        gender: '', // Invalid: empty
        dailyCalorieGoal: 2000,
      );

      expect(result, false);
      expect(provider.error, 'Cinsiyet seçilmelidir');
    });

    test('exceedsCalorieGoal returns false when no profile', () {
      expect(provider.exceedsCalorieGoal(1000), false);
    });

    test('getRemainingCalories returns null when no profile', () {
      expect(provider.getRemainingCalories(1000), isNull);
    });

    test('shouldSuggestLowCalorieRecipes returns false when no profile', () {
      expect(provider.shouldSuggestLowCalorieRecipes(), false);
    });
  });

  group('UserProfile Model Validation Tests', () {
    test('validateAge returns null for valid age', () {
      expect(UserProfile.validateAge(25), isNull);
      expect(UserProfile.validateAge(18), isNull);
      expect(UserProfile.validateAge(100), isNull);
    });

    test('validateAge returns error for invalid age', () {
      expect(UserProfile.validateAge(17), isNotNull);
      expect(UserProfile.validateAge(101), isNotNull);
      expect(UserProfile.validateAge(null), isNotNull);
    });

    test('validateCalorieGoal returns null for valid goal', () {
      expect(UserProfile.validateCalorieGoal(2000), isNull);
      expect(UserProfile.validateCalorieGoal(1000), isNull);
      expect(UserProfile.validateCalorieGoal(5000), isNull);
    });

    test('validateCalorieGoal returns error for invalid goal', () {
      expect(UserProfile.validateCalorieGoal(999), isNotNull);
      expect(UserProfile.validateCalorieGoal(5001), isNotNull);
      expect(UserProfile.validateCalorieGoal(null), isNotNull);
    });

    test('validateGender returns null for valid gender', () {
      expect(UserProfile.validateGender('Erkek'), isNull);
      expect(UserProfile.validateGender('Kadın'), isNull);
      expect(UserProfile.validateGender('Diğer'), isNull);
    });

    test('validateGender returns error for invalid gender', () {
      expect(UserProfile.validateGender(''), isNotNull);
      expect(UserProfile.validateGender(null), isNotNull);
      expect(UserProfile.validateGender('Invalid'), isNotNull);
    });
  });
}

