import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/models/skill.dart';
import '../providers/skill_provider.dart';
import '../repositories/skill_repository.dart';

class SkillsScreen extends ConsumerStatefulWidget {
  const SkillsScreen({super.key});

  @override
  ConsumerState<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends ConsumerState<SkillsScreen> {
  final _uuid = const Uuid();

  Color _getDomainColor(String domain) {
    switch (domain.toLowerCase()) {
      case 'tech':
      case 'computer science':
        return const Color(0xFF6366F1);
      case 'science':
      case 'neuroscience':
        return const Color(0xFF06B6D4);
      case 'arts & music':
      case 'music':
        return const Color(0xFFEC4899);
      case 'philosophy':
        return const Color(0xFF8B5CF6);
      case 'fitness':
      case 'health':
        return const Color(0xFF10B981);
      case 'business':
      case 'finance':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final skillsAsync = ref.watch(skillsListProvider);
    final domainsAsync = ref.watch(skillDomainsProvider);
    final activeStatus = ref.watch(skillStatusFilterProvider);
    final activeDomain = ref.watch(skillDomainFilterProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Polymath Skills',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Add Skill',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddEditSkillDialog(),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Polymath Overview Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 8),
              child: skillsAsync.when(
                data: (skills) {
                  final activeCount = skills.where((s) => s.status == 'active').length;
                  final queuedCount = skills.where((s) => s.status == 'queued').length;
                  final masteredCount = skills.where((s) => s.status == 'mastered').length;

                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E1E28), const Color(0xFF161620)]
                            : [const Color(0xFFF5F3FF), const Color(0xFFEDE9FE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.hub_rounded, color: Color(0xFF8B5CF6), size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Polymath Mastery Matrix',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryCol('ACTIVE', '$activeCount', const Color(0xFF6366F1)),
                            _buildSummaryCol('QUEUED', '$queuedCount', const Color(0xFFF59E0B)),
                            _buildSummaryCol('MASTERED', '$masteredCount', const Color(0xFF10B981)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
          ),

          // 2. Status Segment Tabs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text('All')),
                  ButtonSegment(value: 'active', label: Text('Active')),
                  ButtonSegment(value: 'queued', label: Text('Queued')),
                  ButtonSegment(value: 'mastered', label: Text('Mastered')),
                ],
                selected: {activeStatus},
                onSelectionChanged: (set) {
                  ref.read(skillStatusFilterProvider.notifier).setStatus(set.first);
                },
              ),
            ),
          ),

          // 3. Domain Filter Chips
          SliverToBoxAdapter(
            child: domainsAsync.when(
              data: (domains) {
                final allDomains = ['All', ...domains];
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
                  child: Row(
                    children: allDomains.map((d) {
                      final isSelected = activeDomain == d;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(d, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (_) {
                            ref.read(skillDomainFilterProvider.notifier).setDomain(d);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),

          // 4. Skills List
          skillsAsync.when(
            data: (skills) {
              if (skills.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.psychology_outlined,
                          size: 48,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No Skills in this View',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Track your multidisciplinary learning goals and practice XP',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => _showAddEditSkillDialog(),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add First Skill'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 4, AppSpacing.lg, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final skill = skills[index];
                      final domainColor = _getDomainColor(skill.domain);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E24) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2C2C34) : const Color(0xFFECECF0),
                              width: 0.8,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: domainColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      skill.domain.toUpperCase(),
                                      style: TextStyle(
                                        color: domainColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Level Stars
                                  Row(
                                    children: List.generate(5, (starIdx) {
                                      final isFilled = starIdx < skill.level;
                                      return Icon(
                                        isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                                        size: 15,
                                        color: isFilled ? const Color(0xFFF59E0B) : Colors.grey.shade600,
                                      );
                                    }),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    skill.levelTitle,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert_rounded, size: 18),
                                    onSelected: (val) async {
                                      if (val == 'delete') {
                                        await ref.read(skillRepositoryProvider).deleteSkill(skill.id);
                                        ref.invalidate(skillsListProvider);
                                        ref.invalidate(skillDomainsProvider);
                                      } else if (val == 'edit') {
                                        _showAddEditSkillDialog(skill: skill);
                                      } else {
                                        await ref.read(skillRepositoryProvider).setSkillStatus(skill.id, val);
                                        ref.invalidate(skillsListProvider);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Edit Skill')),
                                      if (skill.status != 'active')
                                        const PopupMenuItem(value: 'active', child: Text('Move to Active')),
                                      if (skill.status != 'queued')
                                        const PopupMenuItem(value: 'queued', child: Text('Move to Queued')),
                                      if (skill.status != 'mastered')
                                        const PopupMenuItem(value: 'mastered', child: Text('Mark as Mastered')),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                skill.title,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              if (skill.notes != null && skill.notes!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  skill.notes!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 12),
                              // XP Progress Bar
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: skill.progressFraction,
                                        minHeight: 6,
                                        backgroundColor: isDark ? const Color(0xFF2C2C34) : const Color(0xFFE5E5EB),
                                        valueColor: AlwaysStoppedAnimation<Color>(domainColor),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${skill.currentXp}/${skill.targetXp} XP',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFF59E0B)),
                                    label: const Text('+25 XP Practice', style: TextStyle(fontSize: 11)),
                                    onPressed: () async {
                                      await ref.read(skillRepositoryProvider).addPracticeXp(skill.id, 25);
                                      ref.invalidate(skillsListProvider);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: skills.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error loading skills: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSkillDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Skill'),
      ),
    );
  }

  Widget _buildSummaryCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ],
    );
  }

  void _showAddEditSkillDialog({PolymathSkill? skill}) {
    final titleCtrl = TextEditingController(text: skill?.title ?? '');
    final notesCtrl = TextEditingController(text: skill?.notes ?? '');
    String domain = skill?.domain ?? 'Tech';
    int level = skill?.level ?? 1;
    String status = skill?.status ?? 'active';

    final defaultDomains = ['Tech', 'Science', 'Arts & Music', 'Philosophy', 'Fitness', 'Business', 'Languages'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(skill == null ? 'Add Polymath Skill' : 'Edit Skill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: skill == null,
                  decoration: const InputDecoration(
                    labelText: 'Skill Title',
                    hintText: 'e.g. Flutter Architecture, Quantum Optics',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: defaultDomains.contains(domain) ? domain : defaultDomains.first,
                  decoration: const InputDecoration(labelText: 'Domain'),
                  items: defaultDomains.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => domain = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: level,
                  decoration: const InputDecoration(labelText: 'Mastery Level'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 • Novice')),
                    DropdownMenuItem(value: 2, child: Text('2 • Competent')),
                    DropdownMenuItem(value: 3, child: Text('3 • Proficient')),
                    DropdownMenuItem(value: 4, child: Text('4 • Advanced')),
                    DropdownMenuItem(value: 5, child: Text('5 • Master')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => level = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active (Currently Practicing)')),
                    DropdownMenuItem(value: 'queued', child: Text('Queued (Upcoming)')),
                    DropdownMenuItem(value: 'mastered', child: Text('Mastered')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => status = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Core Focus',
                    hintText: 'Key concepts, books, or milestones',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;

                final newSkill = PolymathSkill(
                  id: skill?.id ?? _uuid.v4(),
                  title: title,
                  domain: domain,
                  level: level,
                  status: status,
                  currentXp: skill?.currentXp ?? 0,
                  targetXp: skill?.targetXp ?? 100,
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  createdAt: skill?.createdAt ?? DateTime.now(),
                );

                await ref.read(skillRepositoryProvider).saveSkill(newSkill);
                ref.invalidate(skillsListProvider);
                ref.invalidate(skillDomainsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(skill == null ? 'Add Skill' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }
}
