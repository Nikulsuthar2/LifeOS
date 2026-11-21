class PolymathSkill {
  final String id;
  final String title;
  final String domain; // "Computer Science", "Mathematics", "Neuroscience", "Music & Audio", "Philosophy", "Design", "Fitness"
  final int level; // 1: Novice, 2: Competent, 3: Proficient, 4: Advanced, 5: Master
  final String status; // "active", "queued", "mastered"
  final int currentXp;
  final int targetXp;
  final String? notes;
  final String? linkedRoadmapId;
  final DateTime createdAt;

  const PolymathSkill({
    required this.id,
    required this.title,
    required this.domain,
    this.level = 1,
    this.status = 'active',
    this.currentXp = 0,
    this.targetXp = 100,
    this.notes,
    this.linkedRoadmapId,
    required this.createdAt,
  });

  String get levelTitle {
    switch (level) {
      case 1:
        return 'Novice';
      case 2:
        return 'Competent';
      case 3:
        return 'Proficient';
      case 4:
        return 'Advanced';
      case 5:
        return 'Master';
      default:
        return 'Level $level';
    }
  }

  double get progressFraction {
    if (targetXp <= 0) return 1.0;
    return (currentXp / targetXp).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'domain': domain,
      'level': level,
      'status': status,
      'xp': currentXp,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PolymathSkill.fromMap(Map<String, dynamic> map) {
    return PolymathSkill(
      id: map['id'] as String,
      title: map['title'] as String,
      domain: map['domain'] as String? ?? 'General',
      level: map['level'] as int? ?? 1,
      status: map['status'] as String? ?? 'active',
      currentXp: (map['xp'] ?? map['current_xp']) as int? ?? 0,
      targetXp: 100 * (map['level'] as int? ?? 1),
      notes: map['notes'] as String?,
      linkedRoadmapId: map['linked_roadmap_id'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  PolymathSkill copyWith({
    String? id,
    String? title,
    String? domain,
    int? level,
    String? status,
    int? currentXp,
    int? targetXp,
    String? notes,
    String? linkedRoadmapId,
    DateTime? createdAt,
  }) {
    return PolymathSkill(
      id: id ?? this.id,
      title: title ?? this.title,
      domain: domain ?? this.domain,
      level: level ?? this.level,
      status: status ?? this.status,
      currentXp: currentXp ?? this.currentXp,
      targetXp: targetXp ?? this.targetXp,
      notes: notes ?? this.notes,
      linkedRoadmapId: linkedRoadmapId ?? this.linkedRoadmapId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
