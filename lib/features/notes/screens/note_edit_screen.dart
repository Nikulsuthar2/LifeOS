import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/note.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../providers/note_provider.dart';
import '../repositories/note_repository.dart';

class NoteEditScreen extends ConsumerStatefulWidget {
  final NoteItem? note;

  const NoteEditScreen({super.key, this.note});

  static Future<void> open(BuildContext context, {NoteItem? note}) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteEditScreen(note: note)),
    );
  }

  @override
  ConsumerState<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends ConsumerState<NoteEditScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagController;
  late String _folder;
  late bool _isPinned;
  late List<String> _tags;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _tagController = TextEditingController();
    _folder = widget.note?.folder ?? 'General';
    _isPinned = widget.note?.isPinned ?? false;
    _tags = List.from(widget.note?.tags ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    final finalTitle = title.isEmpty ? 'Untitled Note' : title;
    final repo = ref.read(noteRepositoryProvider);

    if (widget.note != null) {
      final updated = widget.note!.copyWith(
        title: finalTitle,
        content: content,
        folder: _folder,
        tags: _tags,
        isPinned: _isPinned,
        updatedAt: DateTime.now(),
      );
      await repo.updateNote(updated);
    } else {
      final newNote = NoteItem(
        id: const Uuid().v4(),
        title: finalTitle,
        content: content,
        folder: _folder,
        tags: _tags,
        isPinned: _isPinned,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.insertNote(newNote);
    }

    ref.invalidate(notesListProvider);
    ref.invalidate(noteFoldersProvider);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _deleteNote() async {
    if (widget.note == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repo = ref.read(noteRepositoryProvider);
      await repo.deleteNote(widget.note!.id);
      ref.invalidate(notesListProvider);
      ref.invalidate(noteFoldersProvider);
      if (mounted) Navigator.pop(context);
    }
  }

  void _addTag(String tag) {
    final trimmed = tag.trim().toLowerCase();
    if (trimmed.isNotEmpty && !_tags.contains(trimmed)) {
      setState(() {
        _tags.add(trimmed);
        _tagController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(widget.note != null ? 'Edit Note' : 'New Note'),
        actions: [
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: _isPinned ? primary : null,
            ),
            tooltip: _isPinned ? 'Unpin' : 'Pin to top',
            onPressed: () => setState(() => _isPinned = !_isPinned),
          ),
          if (widget.note != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              tooltip: 'Delete',
              onPressed: _deleteNote,
            ),
          IconButton(
            icon: const Icon(Icons.check_rounded),
            tooltip: 'Save',
            onPressed: _isSaving ? null : _saveNote,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        children: [
          // Folder selection chip row
          Row(
            children: [
              Icon(Icons.folder_outlined, size: 18, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _folder,
                underline: const SizedBox.shrink(),
                borderRadius: BorderRadius.circular(12),
                items: ['General', 'Philosophy', 'Tech', 'Life', 'Ideas', 'Projects'].map((f) {
                  return DropdownMenuItem(
                    value: f,
                    child: Text(f, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _folder = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title input
          TextField(
            controller: _titleController,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5),
            decoration: const InputDecoration(
              hintText: 'Note Title...',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 16),

          // Content body input
          TextField(
            controller: _contentController,
            maxLines: null,
            minLines: 12,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Write your thoughts, ideas, code snippets, or notes...',
              hintStyle: TextStyle(
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                fontSize: 15,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 24),

          // Tags section
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ..._tags.map((tag) {
                return Chip(
                  label: Text('#$tag', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  visualDensity: VisualDensity.compact,
                  onDeleted: () => setState(() => _tags.remove(tag)),
                );
              }),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _tagController,
                  decoration: const InputDecoration(
                    hintText: '+ add tag',
                    isDense: true,
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  ),
                  onSubmitted: _addTag,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
