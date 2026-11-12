class JournalEntry {
  final String id;
  final String dateStr; // YYYY-MM-DD
  final String mood; // 'great', 'good', 'neutral', 'bad'
  final String wentWell;
  final String couldImprove;
  final String lessonsLearned;
  final String randomThoughts;
  final DateTime createdAt;

  JournalEntry({
    required this.id,
    required this.dateStr,
    this.mood = 'good',
    this.wentWell = '',
    this.couldImprove = '',
    this.lessonsLearned = '',
    this.randomThoughts = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  JournalEntry copyWith({
    String? id,
    String? dateStr,
    String? mood,
    String? wentWell,
    String? couldImprove,
    String? lessonsLearned,
    String? randomThoughts,
    DateTime? createdAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      dateStr: dateStr ?? this.dateStr,
      mood: mood ?? this.mood,
      wentWell: wentWell ?? this.wentWell,
      couldImprove: couldImprove ?? this.couldImprove,
      lessonsLearned: lessonsLearned ?? this.lessonsLearned,
      randomThoughts: randomThoughts ?? this.randomThoughts,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date_str': dateStr,
      'mood': mood,
      'went_well': wentWell,
      'could_improve': couldImprove,
      'lessons_learned': lessonsLearned,
      'random_thoughts': randomThoughts,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as String,
      dateStr: map['date_str'] as String,
      mood: (map['mood'] as String?) ?? 'good',
      wentWell: (map['went_well'] as String?) ?? '',
      couldImprove: (map['could_improve'] as String?) ?? '',
      lessonsLearned: (map['lessons_learned'] as String?) ?? '',
      randomThoughts: (map['random_thoughts'] as String?) ?? '',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
    );
  }
}

