/// User profile model
class UserProfile {
  final int? id;
  final int age;
  final String gender; // 'Erkek', 'Kadın', 'Diğer'
  final int dailyCalorieGoal;

  UserProfile({
    this.id,
    required this.age,
    required this.gender,
    required this.dailyCalorieGoal,
  });

  /// Create from Map (database)
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      age: map['age'] as int,
      gender: map['gender'] as String,
      dailyCalorieGoal: map['daily_calorie_goal'] as int,
    );
  }

  /// Convert to Map (database)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'age': age,
      'gender': gender,
      'daily_calorie_goal': dailyCalorieGoal,
    };
  }

  /// Create a copy with updated fields
  UserProfile copyWith({
    int? id,
    int? age,
    String? gender,
    int? dailyCalorieGoal,
  }) {
    return UserProfile(
      id: id ?? this.id,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
    );
  }

  /// Validate profile data
  static String? validateAge(int? age) {
    if (age == null) {
      return 'Yaş gereklidir';
    }
    if (age < 18) {
      return 'Yaş en az 18 olmalıdır';
    }
    if (age > 100) {
      return 'Yaş en fazla 100 olabilir';
    }
    return null;
  }

  /// Validate calorie goal
  static String? validateCalorieGoal(int? goal) {
    if (goal == null) {
      return 'Günlük kalori hedefi gereklidir';
    }
    if (goal < 1000) {
      return 'Günlük kalori hedefi en az 1000 olmalıdır';
    }
    if (goal > 5000) {
      return 'Günlük kalori hedefi en fazla 5000 olabilir';
    }
    return null;
  }

  /// Validate gender
  static String? validateGender(String? gender) {
    if (gender == null || gender.isEmpty) {
      return 'Cinsiyet seçilmelidir';
    }
    if (!['Erkek', 'Kadın', 'Diğer'].contains(gender)) {
      return 'Geçersiz cinsiyet seçimi';
    }
    return null;
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, age: $age, gender: $gender, dailyCalorieGoal: $dailyCalorieGoal)';
  }
}

