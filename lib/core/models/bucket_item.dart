class BucketItem {
  final String id;
  final String title;
  final String category; // "movie", "game", "book", "travel", "experience", "other"
  final String status;   // "wishlist", "in_progress", "completed"
  final double? rating;  // 1.0 to 5.0
  final String? notes;
  final String? targetDate;
  final String? completedAt;
  final String? iconName;
  final DateTime createdAt;

  const BucketItem({
    required this.id,
    required this.title,
    required this.category,
    this.status = 'wishlist',
    this.rating,
    this.notes,
    this.targetDate,
    this.completedAt,
    this.iconName,
    required this.createdAt,
  });

  bool get isCompleted => status == 'completed';

  String get categoryDisplay {
    switch (category.toLowerCase()) {
      case 'movie':
        return 'Movies & Shows';
      case 'game':
        return 'Games';
      case 'book':
        return 'Books';
      case 'travel':
        return 'Travel';
      case 'experience':
        return 'Experiences';
      default:
        return 'Other';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'status': status,
      'rating': rating ?? 0.0,
      'notes': notes,
      'target_date': targetDate,
      'completed_at': completedAt,
      'cover_url': iconName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BucketItem.fromMap(Map<String, dynamic> map) {
    return BucketItem(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String? ?? 'other',
      status: map['status'] as String? ?? 'wishlist',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
      targetDate: map['target_date'] as String?,
      completedAt: map['completed_at'] as String?,
      iconName: map['cover_url'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  BucketItem copyWith({
    String? id,
    String? title,
    String? category,
    String? status,
    double? rating,
    String? notes,
    String? targetDate,
    String? completedAt,
    String? iconName,
    DateTime? createdAt,
  }) {
    return BucketItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      targetDate: targetDate ?? this.targetDate,
      completedAt: completedAt ?? this.completedAt,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
