import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../models/recurrence_engine.dart';

/// Interactive modal to customize task repeat frequencies, specific days, and end dates.
class RecurrenceSelectorSheet extends StatefulWidget {
  final String initialRecurrence;
  final DateTime? initialEndDate;
  final DateTime taskDate;

  const RecurrenceSelectorSheet({
    super.key,
    required this.initialRecurrence,
    this.initialEndDate,
    required this.taskDate,
  });

  static Future<RecurrenceResult?> show(
    BuildContext context, {
    required String initialRecurrence,
    DateTime? initialEndDate,
    required DateTime taskDate,
  }) {
    return showModalBottomSheet<RecurrenceResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecurrenceSelectorSheet(
        initialRecurrence: initialRecurrence,
        initialEndDate: initialEndDate,
        taskDate: taskDate,
      ),
    );
  }

  @override
  State<RecurrenceSelectorSheet> createState() => _RecurrenceSelectorSheetState();
}

class RecurrenceResult {
  final String recurrence;
  final DateTime? endDate;

  const RecurrenceResult({
    required this.recurrence,
    this.endDate,
  });
}

class _RecurrenceSelectorSheetState extends State<RecurrenceSelectorSheet> {
  late RecurrenceType _selectedType;
  late List<int> _selectedDaysOfWeek;
  late int _dayOfMonth;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final rule = RecurrenceRule.fromString(widget.initialRecurrence, endDate: widget.initialEndDate);
    _selectedType = rule.type;
    _selectedDaysOfWeek = List.from(rule.daysOfWeek.isNotEmpty ? rule.daysOfWeek : [widget.taskDate.weekday]);
    _dayOfMonth = rule.dayOfMonth ?? widget.taskDate.day;
    _endDate = widget.initialEndDate;
  }

  void _save() {
    RecurrenceRule rule;
    switch (_selectedType) {
      case RecurrenceType.none:
        rule = const RecurrenceRule(type: RecurrenceType.none);
        break;
      case RecurrenceType.daily:
        rule = RecurrenceRule(type: RecurrenceType.daily, endDate: _endDate);
        break;
      case RecurrenceType.weekdays:
        rule = RecurrenceRule(type: RecurrenceType.weekdays, endDate: _endDate);
        break;
      case RecurrenceType.weekly:
        rule = RecurrenceRule(
          type: RecurrenceType.weekly,
          daysOfWeek: _selectedDaysOfWeek,
          endDate: _endDate,
        );
        break;
      case RecurrenceType.monthly:
        rule = RecurrenceRule(
          type: RecurrenceType.monthly,
          dayOfMonth: _dayOfMonth,
          endDate: _endDate,
        );
        break;
      case RecurrenceType.yearly:
        rule = RecurrenceRule(type: RecurrenceType.yearly, endDate: _endDate);
        break;
      case RecurrenceType.custom:
        rule = RecurrenceRule(type: RecurrenceType.daily, endDate: _endDate);
        break;
    }

    Navigator.of(context).pop(RecurrenceResult(
      recurrence: rule.toDbString(),
      endDate: _selectedType == RecurrenceType.none ? null : _endDate,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161618) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C32) : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                ),
                Text(
                  'Repeat Task',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _save,
                  child: Text('Done', style: TextStyle(fontWeight: FontWeight.w700, color: primary)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Presets in Inset Grouped container
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A2A30) : const Color(0xFFE5E5EA),
                  width: 0.8,
                ),
              ),
              child: Column(
                children: [
                  _buildOptionRow('Does not repeat', RecurrenceType.none, isDark),
                  _buildDivider(isDark),
                  _buildOptionRow('Every day', RecurrenceType.daily, isDark),
                  _buildDivider(isDark),
                  _buildOptionRow('Every weekday (Mon–Fri)', RecurrenceType.weekdays, isDark),
                  _buildDivider(isDark),
                  _buildOptionRow('Weekly', RecurrenceType.weekly, isDark),
                  _buildDivider(isDark),
                  _buildOptionRow(
                    'Monthly (on day ${widget.taskDate.day})',
                    RecurrenceType.monthly,
                    isDark,
                  ),
                  _buildDivider(isDark),
                  _buildOptionRow(
                    'Yearly (every ${DateFormat('MMM d').format(widget.taskDate)})',
                    RecurrenceType.yearly,
                    isDark,
                  ),
                ],
              ),
            ),

            // Specific Days of the Week Selector (when Weekly is selected)
            if (_selectedType == RecurrenceType.weekly) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'REPEAT ON SPECIFIC DAYS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDayPill(1, 'M', isDark),
                  _buildDayPill(2, 'T', isDark),
                  _buildDayPill(3, 'W', isDark),
                  _buildDayPill(4, 'T', isDark),
                  _buildDayPill(5, 'F', isDark),
                  _buildDayPill(6, 'S', isDark),
                  _buildDayPill(7, 'S', isDark),
                ],
              ),
            ],

            // Repeat Until Date
            if (_selectedType != RecurrenceType.none) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'END RECURRENCE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2A2A30) : const Color(0xFFE5E5EA),
                    width: 0.8,
                  ),
                ),
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? widget.taskDate.add(const Duration(days: 90)),
                      firstDate: widget.taskDate,
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setState(() => _endDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.calendar, size: 18, color: primary),
                        const SizedBox(width: 12),
                        const Text('Repeat Until', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Text(
                          _endDate != null ? DateFormat('MMM d, yyyy').format(_endDate!) : 'Never (Forever)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        if (_endDate != null) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(() => _endDate = null),
                            child: const Icon(CupertinoIcons.clear_circled_solid, size: 16),
                          ),
                        ] else ...[
                          const SizedBox(width: 4),
                          const Icon(CupertinoIcons.chevron_forward, size: 14),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionRow(String title, RecurrenceType type, bool isDark) {
    final isSelected = _selectedType == type;
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? primary
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
            ),
            const Spacer(),
            if (isSelected) Icon(CupertinoIcons.checkmark, size: 16, color: primary),
          ],
        ),
      ),
    );
  }

  Widget _buildDayPill(int dayNum, String label, bool isDark) {
    final isSelected = _selectedDaysOfWeek.contains(dayNum);
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            if (_selectedDaysOfWeek.length > 1) {
              _selectedDaysOfWeek.remove(dayNum);
            }
          } else {
            _selectedDaysOfWeek.add(dayNum);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? primary : (isDark ? const Color(0xFF1E1E22) : const Color(0xFFF2F2F7)),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? primary
                : (isDark ? const Color(0xFF2E2E34) : const Color(0xFFE5E5EA)),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 0.8,
      indent: 14,
      color: isDark ? const Color(0xFF28282E) : const Color(0xFFE5E5EA),
    );
  }
}
