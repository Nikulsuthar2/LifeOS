class JournalEntry {
  final String id;
  final String dateStr; // YYYY-MM-DD
  final String mood; // 'great', 'good', 'neutral', 'low', 'bad'
  final String wentWell;
  final String couldImprove;
  final String lessonsLearned;
  final String randomThoughts;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;

  JournalEntry({
    required this.id,
    required this.dateStr,
    this.mood = 'good',
    this.wentWell = '',
    this.couldImprove = '',
    this.lessonsLearned = '',
    this.randomThoughts = '',
    this.tags = const [],
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  JournalEntry copyWith({
    String? id,
    String? dateStr,
    String? mood,
    String? wentWell,
    String? couldImprove,
    String? lessonsLearned,
    String? randomThoughts,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      dateStr: dateStr ?? this.dateStr,
      mood: mood ?? this.mood,
      wentWell: wentWell ?? this.wentWell,
      couldImprove: couldImprove ?? this.couldImprove,
      lessonsLearned: lessonsLearned ?? this.lessonsLearned,
      randomThoughts: randomThoughts ?? this.randomThoughts,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
      'tags': tags.isEmpty ? '[]' : tags.map((t) => '"$t"').toList().toString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    List<String> parsedTags = [];
    final rawTags = map['tags'];
    if (rawTags is String && rawTags.isNotEmpty) {
      try {
        final clean = rawTags.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').trim();
        if (clean.isNotEmpty) {
          parsedTags = clean.split(',').map((e) => e.trim()).toList();
        }
      } catch (_) {}
    }

    return JournalEntry(
      id: map['id'] as String,
      dateStr: map['date_str'] as String,
      mood: (map['mood'] as String?) ?? 'good',
      wentWell: (map['went_well'] as String?) ?? '',
      couldImprove: (map['could_improve'] as String?) ?? '',
      lessonsLearned: (map['lessons_learned'] as String?) ?? '',
      randomThoughts: (map['random_thoughts'] as String?) ?? '',
      tags: parsedTags,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'] as String) : null,
    );
  }
}
