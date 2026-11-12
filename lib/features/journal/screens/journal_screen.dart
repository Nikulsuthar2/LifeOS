import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/journal.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/journal_provider.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _wentWellController = TextEditingController();
  final _couldImproveController = TextEditingController();
  final _lessonsController = TextEditingController();
  final _thoughtsController = TextEditingController();
  String _mood = 'good';
  bool _isLoaded = false;

  @override
  void dispose() {
    _wentWellController.dispose();
    _couldImproveController.dispose();
    _lessonsController.dispose();
    _thoughtsController.dispose();
    super.dispose();
  }

  void _populateToday(JournalEntry? entry) {
    if (_isLoaded || entry == null) return;
    _wentWellController.text = entry.wentWell;
    _couldImproveController.text = entry.couldImprove;
    _lessonsController.text = entry.lessonsLearned;
    _thoughtsController.text = entry.randomThoughts;
    _mood = entry.mood;
    _isLoaded = true;
  }

  Future<void> _saveToday() async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final entry = JournalEntry(
      id: const Uuid().v4(),
      dateStr: todayStr,
      mood: _mood,
      wentWell: _wentWellController.text.trim(),
      couldImprove: _couldImproveController.text.trim(),
      lessonsLearned: _lessonsController.text.trim(),
      randomThoughts: _thoughtsController.text.trim(),
    );

    final repo = ref.read(journalRepositoryProvider);
    await repo.saveEntry(entry);

    ref.invalidate(journalEntriesProvider);
    ref.invalidate(todayJournalEntryProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reflection saved successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todayEntryAsync = ref.watch(todayJournalEntryProvider);
    final pastEntriesAsync = ref.watch(journalEntriesProvider);

    todayEntryAsync.whenData((entry) {
      if (!_isLoaded && entry != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _populateToday(entry));
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal & Reflection'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Daily prompt card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daily Reflection · ${DateFormat('MMM d').format(DateTime.now())}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      // Mood selection
                      Row(
                        children: [
                          _MoodButton(
                            emoji: '😄',
                            isSelected: _mood == 'great',
                            onTap: () => setState(() => _mood = 'great'),
                          ),
                          _MoodButton(
                            emoji: '🙂',
                            isSelected: _mood == 'good',
                            onTap: () => setState(() => _mood = 'good'),
                          ),
                          _MoodButton(
                            emoji: '😐',
                            isSelected: _mood == 'neutral',
                            onTap: () => setState(() => _mood = 'neutral'),
                          ),
                          _MoodButton(
                            emoji: '😔',
                            isSelected: _mood == 'tough',
                            onTap: () => setState(() => _mood = 'tough'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _wentWellController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'What went well today?',
                      hintText: 'Wins, focus sessions, breakthroughs...',
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _couldImproveController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'What didn\'t go well?',
                      hintText: 'Distractions, friction, energy slumps...',
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _lessonsController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Key lessons learned',
                      hintText: 'Insights from studying, coding, or life...',
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _thoughtsController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Ideas & Thoughts',
                      hintText: 'Unsorted sparks of inspiration...',
                    ),
                  ),
                  const SizedBox(height: 16),

                  FilledButton(
                    onPressed: _saveToday,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Reflection', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Past Entries History
            Text(
              'Past Reflections',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),

            pastEntriesAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const Text('No past reflections recorded yet.');
                }

                return Column(
                  children: entries.map((entry) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.dateStr,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              Text(
                                entry.mood == 'great'
                                    ? '😄 Great'
                                    : entry.mood == 'good'
                                        ? '🙂 Good'
                                        : entry.mood == 'neutral'
                                            ? '😐 Neutral'
                                            : '😔 Tough',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          if (entry.wentWell.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              '✨ ${entry.wentWell}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                          if (entry.lessonsLearned.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '💡 ${entry.lessonsLearned}',
                              style: const TextStyle(fontSize: 12, color: AppColors.primaryLight),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodButton({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: AppColors.primary, width: 1.5) : null,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}

