class GamificationProfile {
  final String id;
  final int currentLevel;
  final int totalXp;
  final int streakFreezes;
  final String rankTitle;
  final DateTime updatedAt;

  const GamificationProfile({
    required this.id,
    this.currentLevel = 1,
    this.totalXp = 0,
    this.streakFreezes = 2,
    this.rankTitle = 'Novice Initiate',
    required this.updatedAt,
  });

  int get currentXp => totalXp % 100;
  int get targetXp => 100;
  double get levelProgress => (currentXp / targetXp).clamp(0.0, 1.0);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'level': currentLevel,
      'total_xp': totalXp,
      'streak_freezes': streakFreezes,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory GamificationProfile.fromMap(Map<String, dynamic> map) {
    final lvl = (map['level'] ?? map['current_level']) as int? ?? 1;
    final xp = (map['total_xp'] ?? map['current_xp']) as int? ?? 0;
    return GamificationProfile(
      id: map['id'] as String? ?? 'main_user_profile',
      currentLevel: lvl,
      totalXp: xp,
      streakFreezes: map['streak_freezes'] as int? ?? 2,
      rankTitle: _computeRank(lvl),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  static String _computeRank(int level) {
    if (level < 3) return 'Novice Initiate';
    if (level < 6) return 'Apprentice Architect';
    if (level < 10) return 'Polymath Practitioner';
    if (level < 15) return 'Master Strategist';
    return 'Grandmaster of Life';
  }

  GamificationProfile copyWith({
    String? id,
    int? currentLevel,
    int? totalXp,
    int? streakFreezes,
    String? rankTitle,
    DateTime? updatedAt,
  }) {
    return GamificationProfile(
      id: id ?? this.id,
      currentLevel: currentLevel ?? this.currentLevel,
      totalXp: totalXp ?? this.totalXp,
      streakFreezes: streakFreezes ?? this.streakFreezes,
      rankTitle: rankTitle ?? this.rankTitle,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class GamificationBadge {
  final String id;
  final String code;
  final String title;
  final String description;
  final String iconName;
  final bool isUnlocked;
  final String? unlockedAt;

  const GamificationBadge({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.iconName,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'description': description,
      'icon': iconName,
      'unlocked_at': unlockedAt,
    };
  }

  factory GamificationBadge.fromMap(Map<String, dynamic> map) {
    final unlockedAt = map['unlocked_at'] as String?;
    return GamificationBadge(
      id: map['id'] as String,
      code: map['code'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      iconName: (map['icon'] ?? map['icon_name']) as String? ?? 'emoji_events',
      isUnlocked: unlockedAt != null && unlockedAt.isNotEmpty,
      unlockedAt: unlockedAt,
    );
  }
}

class GamificationXpLog {
  final String id;
  final int amount;
  final String sourceModule;
  final String reason;
  final DateTime createdAt;

  const GamificationXpLog({
    required this.id,
    required this.amount,
    required this.sourceModule,
    required this.reason,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'xp_amount': amount,
      'source_type': sourceModule,
      'description': reason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GamificationXpLog.fromMap(Map<String, dynamic> map) {
    return GamificationXpLog(
      id: map['id'] as String,
      amount: (map['xp_amount'] ?? map['amount']) as int? ?? 0,
      sourceModule: (map['source_type'] ?? map['source_module']) as String? ?? 'general',
      reason: (map['description'] ?? map['reason']) as String? ?? '',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
