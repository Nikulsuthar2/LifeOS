class NoteItem {
  final String id;
  final String title;
  final String content;
  final String folder;
  final List<String> tags;
  final bool isPinned;
  final int color;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteItem({
    required this.id,
    required this.title,
    this.content = '',
    this.folder = 'General',
    this.tags = const [],
    this.isPinned = false,
    this.color = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  NoteItem copyWith({
    String? id,
    String? title,
    String? content,
    String? folder,
    List<String>? tags,
    bool? isPinned,
    int? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      folder: folder ?? this.folder,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'folder': folder,
      'tags': tags.isEmpty ? '[]' : tags.map((t) => '"$t"').toList().toString(),
      'is_pinned': isPinned ? 1 : 0,
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory NoteItem.fromMap(Map<String, dynamic> map) {
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

    return NoteItem(
      id: map['id'] as String,
      title: map['title'] as String,
      content: (map['content'] as String?) ?? '',
      folder: (map['folder'] as String?) ?? 'General',
      tags: parsedTags,
      isPinned: (map['is_pinned'] as int? ?? 0) == 1,
      color: (map['color'] as int? ?? 0),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}
