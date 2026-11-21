import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/journal.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../providers/journal_provider.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEntryEditor({JournalEntry? existingEntry, DateTime? targetDate}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _JournalEditorSheet(
        entry: existingEntry,
        initialDate: targetDate ?? DateTime.now(),
      ),
    );
  }

  void _deleteEntry(JournalEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reflection'),
        content: Text('Delete reflection for ${entry.dateStr}? This action cannot be undone.'),
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
      await ref.read(journalRepositoryProvider).deleteEntry(entry.id);
      ref.invalidate(journalEntriesProvider);
      ref.invalidate(todayJournalEntryProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reflection deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final todayEntryAsync = ref.watch(todayJournalEntryProvider);
    final entriesAsync = ref.watch(journalEntriesProvider);
    final currentMood = ref.watch(journalMoodFilterProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Journal & Reflection',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEntryEditor(),
        backgroundColor: primary,
        foregroundColor: ThemeData.estimateBrightnessForColor(primary) == Brightness.light
            ? const Color(0xFF141416)
            : Colors.white,
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Reflect', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 8, AppSpacing.lg, 96),
        children: [
          // 1. Today's Reflection Prompt Banner
          todayEntryAsync.when(
            data: (todayEntry) {
              final isDone = todayEntry != null;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [primary.withValues(alpha: 0.18), const Color(0xFF141418)]
                        : [primary.withValues(alpha: 0.12), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: primary.withValues(alpha: isDark ? 0.3 : 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          isDone ? _moodEmoji(todayEntry.mood) : '✍️',
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDone ? 'Today\'s Reflection Logged' : 'Evening Reflection',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isDone
                                ? 'Tap to view or edit today\'s entry'
                                : 'Take 3 minutes to reflect on wins, lessons & gratitude',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openEntryEditor(existingEntry: todayEntry),
                      child: Text(
                        isDone ? 'Edit' : 'Start',
                        style: TextStyle(fontWeight: FontWeight.w700, color: primary),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // 2. Search & Mood Filter Bar
          SizedBox(
            height: 40,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search reflections...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(journalSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF1C1C20) : const Color(0xFFF0F0F4),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF2C2C32) : const Color(0xFFE4E4E8),
                    width: 0.8,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF2C2C32) : const Color(0xFFE4E4E8),
                    width: 0.8,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: primary, width: 1.2),
                ),
              ),
              onChanged: (val) {
                ref.read(journalSearchQueryProvider.notifier).state = val.trim();
              },
            ),
          ),

          const SizedBox(height: 10),

          // Mood filter chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildMoodFilterChip('all', 'All', currentMood, primary, isDark),
                _buildMoodFilterChip('great', '🤩 Great', currentMood, primary, isDark),
                _buildMoodFilterChip('good', '😊 Good', currentMood, primary, isDark),
                _buildMoodFilterChip('neutral', '😐 Neutral', currentMood, primary, isDark),
                _buildMoodFilterChip('low', '😔 Low', currentMood, primary, isDark),
                _buildMoodFilterChip('bad', '😫 Bad', currentMood, primary, isDark),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Past Reflections Timeline
          entriesAsync.when(
            data: (entries) {
              if (entries.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 44,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No journal entries yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap the Reflect button to record today\'s reflections.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PAST REFLECTIONS (${entries.length})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...entries.map((entry) {
                    return _JournalEntryCard(
                      entry: entry,
                      isDark: isDark,
                      primary: primary,
                      onEdit: () => _openEntryEditor(existingEntry: entry),
                      onDelete: () => _deleteEntry(entry),
                    );
                  }),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading journal: $e')),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodFilterChip(String moodKey, String label, String currentMood, Color primary, bool isDark) {
    final isSelected = currentMood == moodKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          ref.read(journalMoodFilterProvider.notifier).state = moodKey;
        },
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        selectedColor: primary.withValues(alpha: 0.2),
        checkmarkColor: primary,
        labelStyle: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? primary : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
      ),
    );
  }

  static String _moodEmoji(String mood) {
    switch (mood) {
      case 'great':
        return '🤩';
      case 'good':
        return '😊';
      case 'neutral':
        return '😐';
      case 'low':
        return '😔';
      case 'bad':
        return '😫';
      default:
        return '😊';
    }
  }
}

class _JournalEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final bool isDark;
  final Color primary;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _JournalEntryCard({
    required this.entry,
    required this.isDark,
    required this.primary,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    DateTime? entryDate;
    try {
      entryDate = DateTime.parse(entry.dateStr);
    } catch (_) {}

    final dateDisplay = entryDate != null
        ? DateFormat('EEEE, MMM d, yyyy').format(entryDate)
        : entry.dateStr;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16161A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF26262C) : const Color(0xFFE5E5EA),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Date, Mood chip, Actions
          Row(
            children: [
              Text(
                _JournalScreenState._moodEmoji(entry.mood),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateDisplay,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Edit',
                onPressed: onEdit,
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Delete',
                onPressed: onDelete,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 1. Went Well
          if (entry.wentWell.isNotEmpty) ...[
            _buildSection(
              title: 'WINS & WHAT WENT WELL',
              content: entry.wentWell,
              icon: Icons.celebration_rounded,
              color: AppColors.success,
            ),
            const SizedBox(height: 10),
          ],

          // 2. Could Improve
          if (entry.couldImprove.isNotEmpty) ...[
            _buildSection(
              title: 'AREAS TO IMPROVE',
              content: entry.couldImprove,
              icon: Icons.trending_up_rounded,
              color: AppColors.high,
            ),
            const SizedBox(height: 10),
          ],

          // 3. Lessons Learned
          if (entry.lessonsLearned.isNotEmpty) ...[
            _buildSection(
              title: 'KEY INSIGHTS & LESSONS',
              content: entry.lessonsLearned,
              icon: Icons.lightbulb_outline_rounded,
              color: primary,
            ),
            const SizedBox(height: 10),
          ],

          // 4. Random Thoughts
          if (entry.randomThoughts.isNotEmpty) ...[
            _buildSection(
              title: 'STREAM OF CONSCIOUSNESS',
              content: entry.randomThoughts,
              icon: Icons.bubble_chart_outlined,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            const SizedBox(height: 10),
          ],

          // Tags row
          if (entry.tags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: entry.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF222228) : const Color(0xFFF0F0F4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#$tag',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          content,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}

class _JournalEditorSheet extends ConsumerStatefulWidget {
  final JournalEntry? entry;
  final DateTime initialDate;

  const _JournalEditorSheet({this.entry, required this.initialDate});

  @override
  ConsumerState<_JournalEditorSheet> createState() => _JournalEditorSheetState();
}

class _JournalEditorSheetState extends ConsumerState<_JournalEditorSheet> {
  late final TextEditingController _wentWellController;
  late final TextEditingController _couldImproveController;
  late final TextEditingController _lessonsController;
  late final TextEditingController _thoughtsController;
  late final TextEditingController _tagController;
  late String _mood;
  late DateTime _selectedDate;
  late List<String> _tags;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _wentWellController = TextEditingController(text: widget.entry?.wentWell ?? '');
    _couldImproveController = TextEditingController(text: widget.entry?.couldImprove ?? '');
    _lessonsController = TextEditingController(text: widget.entry?.lessonsLearned ?? '');
    _thoughtsController = TextEditingController(text: widget.entry?.randomThoughts ?? '');
    _tagController = TextEditingController();
    _mood = widget.entry?.mood ?? 'good';
    _selectedDate = widget.entry != null
        ? (DateTime.tryParse(widget.entry!.dateStr) ?? widget.initialDate)
        : widget.initialDate;
    _tags = List.from(widget.entry?.tags ?? []);
  }

  @override
  void dispose() {
    _wentWellController.dispose();
    _couldImproveController.dispose();
    _lessonsController.dispose();
    _thoughtsController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final entry = JournalEntry(
      id: widget.entry?.id ?? const Uuid().v4(),
      dateStr: dateStr,
      mood: _mood,
      wentWell: _wentWellController.text.trim(),
      couldImprove: _couldImproveController.text.trim(),
      lessonsLearned: _lessonsController.text.trim(),
      randomThoughts: _thoughtsController.text.trim(),
      tags: _tags,
      updatedAt: DateTime.now(),
    );

    setState(() => _isSaving = true);
    await ref.read(journalRepositoryProvider).saveEntry(entry);
    ref.invalidate(journalEntriesProvider);
    ref.invalidate(todayJournalEntryProvider);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141416) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        16,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.entry != null ? 'Edit Reflection' : 'Daily Reflection',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: primary),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('EEE, MMM d').format(_selectedDate),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Mood selector row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMoodBtn('great', '🤩', 'Great'),
              _buildMoodBtn('good', '😊', 'Good'),
              _buildMoodBtn('neutral', '😐', 'Neutral'),
              _buildMoodBtn('low', '😔', 'Low'),
              _buildMoodBtn('bad', '😫', 'Bad'),
            ],
          ),

          const SizedBox(height: 16),

          // Input form
          Expanded(
            child: ListView(
              children: [
                _buildPromptField(
                  controller: _wentWellController,
                  label: 'What went well today?',
                  hint: 'Wins, breakthroughs, things that made you smile...',
                  isDark: isDark,
                  primary: primary,
                ),
                const SizedBox(height: 14),
                _buildPromptField(
                  controller: _couldImproveController,
                  label: 'What could have gone better?',
                  hint: 'Mistakes made, friction points, distractions...',
                  isDark: isDark,
                  primary: primary,
                ),
                const SizedBox(height: 14),
                _buildPromptField(
                  controller: _lessonsController,
                  label: 'Lessons & Insights',
                  hint: 'What did you discover or learn about life or work today?',
                  isDark: isDark,
                  primary: primary,
                ),
                const SizedBox(height: 14),
                _buildPromptField(
                  controller: _thoughtsController,
                  label: 'Random Thoughts & Gratitude',
                  hint: 'Stream of consciousness, quotes, gratitude...',
                  isDark: isDark,
                  primary: primary,
                ),
                const SizedBox(height: 14),

                // Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ..._tags.map((t) => Chip(
                          label: Text('#$t', style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          onDeleted: () => setState(() => _tags.remove(t)),
                        )),
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: _tagController,
                        decoration: const InputDecoration(
                          hintText: '+ tag',
                          border: InputBorder.none,
                          filled: false,
                          isDense: true,
                        ),
                        onSubmitted: (val) {
                          final clean = val.trim().toLowerCase();
                          if (clean.isNotEmpty && !_tags.contains(clean)) {
                            setState(() {
                              _tags.add(clean);
                              _tagController.clear();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Save Reflection', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodBtn(String moodKey, String emoji, String label) {
    final isSelected = _mood == moodKey;
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () => setState(() => _mood = moodKey),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    required Color primary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 3,
          minLines: 2,
          style: const TextStyle(fontSize: 13.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 12.5,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1B1B1F) : const Color(0xFFF4F4F8),
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF282830) : const Color(0xFFE2E2E6),
                width: 0.8,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF282830) : const Color(0xFFE2E2E6),
                width: 0.8,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primary, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}
