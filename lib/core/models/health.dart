class HealthVitals {
  final String id;
  final String dateStr;
  final double? heightCm;
  final double? weightKg;
  final double? bmi;
  final String? bloodType;
  final double? bloodSugar;
  final int? systolic;
  final int? diastolic;
  final String? notes;
  final DateTime createdAt;

  HealthVitals({
    required this.id,
    required this.dateStr,
    this.heightCm,
    this.weightKg,
    this.bmi,
    this.bloodType,
    this.bloodSugar,
    this.systolic,
    this.diastolic,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static double calculateBmi(double heightCm, double weightKg) {
    if (heightCm <= 0) return 0;
    final m = heightCm / 100.0;
    return double.parse((weightKg / (m * m)).toStringAsFixed(1));
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date_str': dateStr,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'bmi': bmi,
      'blood_type': bloodType,
      'blood_sugar': bloodSugar,
      'blood_pressure_systolic': systolic,
      'blood_pressure_diastolic': diastolic,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HealthVitals.fromMap(Map<String, dynamic> map) {
    return HealthVitals(
      id: map['id'] as String,
      dateStr: map['date_str'] as String,
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      bmi: (map['bmi'] as num?)?.toDouble(),
      bloodType: map['blood_type'] as String?,
      bloodSugar: (map['blood_sugar'] as num?)?.toDouble(),
      systolic: map['blood_pressure_systolic'] as int?,
      diastolic: map['blood_pressure_diastolic'] as int?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class HealthWaterLog {
  final String id;
  final String dateStr;
  final int glassesDrank;
  final int targetGlasses;
  final DateTime updatedAt;

  HealthWaterLog({
    required this.id,
    required this.dateStr,
    this.glassesDrank = 0,
    this.targetGlasses = 8,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date_str': dateStr,
      'glasses_drank': glassesDrank,
      'target_glasses': targetGlasses,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory HealthWaterLog.fromMap(Map<String, dynamic> map) {
    return HealthWaterLog(
      id: map['id'] as String,
      dateStr: map['date_str'] as String,
      glassesDrank: (map['glasses_drank'] as int?) ?? 0,
      targetGlasses: (map['target_glasses'] as int?) ?? 8,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class HealthSleepLog {
  final String id;
  final String dateStr;
  final String bedTime; // HH:mm
  final String wakeTime; // HH:mm
  final int durationMinutes;
  final int qualityRating; // 1 to 5
  final String? notes;
  final DateTime createdAt;

  HealthSleepLog({
    required this.id,
    required this.dateStr,
    required this.bedTime,
    required this.wakeTime,
    this.durationMinutes = 480,
    this.qualityRating = 4,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date_str': dateStr,
      'bed_time': bedTime,
      'wake_time': wakeTime,
      'duration_minutes': durationMinutes,
      'quality_rating': qualityRating,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HealthSleepLog.fromMap(Map<String, dynamic> map) {
    return HealthSleepLog(
      id: map['id'] as String,
      dateStr: map['date_str'] as String,
      bedTime: (map['bed_time'] as String?) ?? '23:00',
      wakeTime: (map['wake_time'] as String?) ?? '07:00',
      durationMinutes: (map['duration_minutes'] as int?) ?? 480,
      qualityRating: (map['quality_rating'] as int?) ?? 4,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class HealthProduct {
  final String id;
  final String name;
  final String category; // 'skincare', 'haircare', 'medicine', 'supplement'
  final String? dosageOrRoutine;
  final String timeOfDay; // 'morning', 'afternoon', 'evening', 'all'
  final bool isActive;
  final String? notes;
  final DateTime createdAt;

  HealthProduct({
    required this.id,
    required this.name,
    required this.category,
    this.dosageOrRoutine,
    this.timeOfDay = 'all',
    this.isActive = true,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'dosage_or_routine': dosageOrRoutine,
      'time_of_day': timeOfDay,
      'is_active': isActive ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HealthProduct.fromMap(Map<String, dynamic> map) {
    return HealthProduct(
      id: map['id'] as String,
      name: map['name'] as String,
      category: (map['category'] as String?) ?? 'skincare',
      dosageOrRoutine: map['dosage_or_routine'] as String?,
      timeOfDay: (map['time_of_day'] as String?) ?? 'all',
      isActive: (map['is_active'] as int? ?? 1) == 1,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class HealthWorkout {
  final String id;
  final String title;
  final String type; // 'Strength', 'Cardio', 'HIIT', 'Yoga'
  final int durationMinutes;
  final String exercisesJson;
  final String dateStr;
  final String? notes;
  final DateTime createdAt;

  HealthWorkout({
    required this.id,
    required this.title,
    this.type = 'Strength',
    this.durationMinutes = 45,
    this.exercisesJson = '[]',
    required this.dateStr,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'duration_minutes': durationMinutes,
      'exercises_json': exercisesJson,
      'date_str': dateStr,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HealthWorkout.fromMap(Map<String, dynamic> map) {
    return HealthWorkout(
      id: map['id'] as String,
      title: map['title'] as String,
      type: (map['type'] as String?) ?? 'Strength',
      durationMinutes: (map['duration_minutes'] as int?) ?? 45,
      exercisesJson: (map['exercises_json'] as String?) ?? '[]',
      dateStr: map['date_str'] as String,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class HealthMeal {
  final String id;
  final String dateStr;
  final String mealType; // 'breakfast', 'lunch', 'dinner', 'snack'
  final String title;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatsG;
  final String? notes;
  final DateTime createdAt;

  HealthMeal({
    required this.id,
    required this.dateStr,
    required this.mealType,
    required this.title,
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatsG = 0,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date_str': dateStr,
      'meal_type': mealType,
      'title': title,
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fats_g': fatsG,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HealthMeal.fromMap(Map<String, dynamic> map) {
    return HealthMeal(
      id: map['id'] as String,
      dateStr: map['date_str'] as String,
      mealType: (map['meal_type'] as String?) ?? 'lunch',
      title: map['title'] as String,
      calories: (map['calories'] as int?) ?? 0,
      proteinG: (map['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (map['carbs_g'] as num?)?.toDouble() ?? 0,
      fatsG: (map['fats_g'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}
