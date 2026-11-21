import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/health.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../providers/health_provider.dart';
import '../repositories/health_repository.dart';

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showLogVitalsDialog(HealthVitals? current) {
    final heightCtrl = TextEditingController(text: current?.heightCm?.toString() ?? '178');
    final weightCtrl = TextEditingController(text: current?.weightKg?.toString() ?? '72.5');
    final sugarCtrl = TextEditingController(text: current?.bloodSugar?.toString() ?? '95');
    final systolicCtrl = TextEditingController(text: current?.systolic?.toString() ?? '120');
    final diastolicCtrl = TextEditingController(text: current?.diastolic?.toString() ?? '80');
    String bloodType = current?.bloodType ?? 'O+';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Vitals & Biometrics'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: heightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Height (cm)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Weight (kg)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: bloodType,
                      decoration: const InputDecoration(labelText: 'Blood Type'),
                      items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((b) {
                        return DropdownMenuItem(value: b, child: Text(b));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) bloodType = val;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: sugarCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Blood Sugar (mg/dL)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: systolicCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Systolic BP'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: diastolicCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Diastolic BP'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final h = double.tryParse(heightCtrl.text);
              final w = double.tryParse(weightCtrl.text);
              final bmi = (h != null && w != null) ? HealthVitals.calculateBmi(h, w) : null;
              final vitals = HealthVitals(
                id: const Uuid().v4(),
                dateStr: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                heightCm: h,
                weightKg: w,
                bmi: bmi,
                bloodType: bloodType,
                bloodSugar: double.tryParse(sugarCtrl.text),
                systolic: int.tryParse(systolicCtrl.text),
                diastolic: int.tryParse(diastolicCtrl.text),
              );
              await ref.read(healthRepositoryProvider).saveVitals(vitals);
              ref.invalidate(latestVitalsProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Vitals'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    String category = 'skincare';
    String timeOfDay = 'morning';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Health Product / Medicine'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Product / Medicine Name',
                  hintText: 'e.g. Niacinamide Serum, Vitamin D3, Finasteride',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  DropdownMenuItem(value: 'skincare', child: Text('Skincare')),
                  DropdownMenuItem(value: 'haircare', child: Text('Haircare')),
                  DropdownMenuItem(value: 'medicine', child: Text('Medicine')),
                  DropdownMenuItem(value: 'supplement', child: Text('Supplement')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => category = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dosageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dosage / Routine Instructions',
                  hintText: 'e.g. 1 Tablet after meal, Apply before bed',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: timeOfDay,
                decoration: const InputDecoration(labelText: 'Time of Day'),
                items: const [
                  DropdownMenuItem(value: 'morning', child: Text('Morning')),
                  DropdownMenuItem(value: 'afternoon', child: Text('Afternoon')),
                  DropdownMenuItem(value: 'evening', child: Text('Evening')),
                  DropdownMenuItem(value: 'all', child: Text('Anytime')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => timeOfDay = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final product = HealthProduct(
                  id: const Uuid().v4(),
                  name: name,
                  category: category,
                  dosageOrRoutine: dosageCtrl.text.trim(),
                  timeOfDay: timeOfDay,
                );
                await ref.read(healthRepositoryProvider).saveProduct(product);
                ref.invalidate(healthProductsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogSleepDialog() {
    TimeOfDay bedTime = const TimeOfDay(hour: 23, minute: 0);
    TimeOfDay wakeTime = const TimeOfDay(hour: 7, minute: 0);
    int quality = 4;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final bedMinutes = bedTime.hour * 60 + bedTime.minute;
          int wakeMinutes = wakeTime.hour * 60 + wakeTime.minute;
          if (wakeMinutes < bedMinutes) wakeMinutes += 24 * 60;
          final durationMinutes = wakeMinutes - bedMinutes;
          final hours = durationMinutes ~/ 60;
          final mins = durationMinutes % 60;

          return AlertDialog(
            title: const Text('Log Sleep'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Bed Time'),
                  trailing: Text(bedTime.format(context), style: const TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: bedTime);
                    if (picked != null) setDialogState(() => bedTime = picked);
                  },
                ),
                ListTile(
                  title: const Text('Wake Time'),
                  trailing: Text(wakeTime.format(context), style: const TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: wakeTime);
                    if (picked != null) setDialogState(() => wakeTime = picked);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Duration: ${hours}h ${mins}m',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                const Text('Sleep Quality'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    return IconButton(
                      icon: Icon(
                        star <= quality ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 28,
                      ),
                      onPressed: () => setDialogState(() => quality = star),
                    );
                  }),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final sleep = HealthSleepLog(
                    id: const Uuid().v4(),
                    dateStr: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    bedTime: '${bedTime.hour.toString().padLeft(2, '0')}:${bedTime.minute.toString().padLeft(2, '0')}',
                    wakeTime: '${wakeTime.hour.toString().padLeft(2, '0')}:${wakeTime.minute.toString().padLeft(2, '0')}',
                    durationMinutes: durationMinutes,
                    qualityRating: quality,
                  );
                  await ref.read(healthRepositoryProvider).saveSleepLog(sleep);
                  ref.invalidate(sleepLogsProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Log Sleep'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddWorkoutDialog() {
    final titleCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '45');
    String type = 'Strength';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Log Workout Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Workout Title',
                  hintText: 'e.g. Chest & Triceps, 5k Morning Run',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: ['Strength', 'Cardio', 'HIIT', 'Yoga', 'Calisthenics', 'Pilates'].map((t) {
                  return DropdownMenuItem(value: t, child: Text(t));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => type = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duration (minutes)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                final workout = HealthWorkout(
                  id: const Uuid().v4(),
                  title: title,
                  type: type,
                  durationMinutes: int.tryParse(durationCtrl.text) ?? 45,
                  dateStr: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                );
                await ref.read(healthRepositoryProvider).saveWorkout(workout);
                ref.invalidate(workoutsListProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Workout'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMealDialog() {
    final titleCtrl = TextEditingController();
    final caloriesCtrl = TextEditingController(text: '450');
    String mealType = 'lunch';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Log Meal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: mealType,
                decoration: const InputDecoration(labelText: 'Meal Type'),
                items: const [
                  DropdownMenuItem(value: 'breakfast', child: Text('Breakfast')),
                  DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                  DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                  DropdownMenuItem(value: 'snack', child: Text('Snack')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => mealType = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Meal Description',
                  hintText: 'e.g. Grilled Chicken Salad with Quinoa',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: caloriesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Estimated Calories (kcal)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                final meal = HealthMeal(
                  id: const Uuid().v4(),
                  dateStr: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  mealType: mealType,
                  title: title,
                  calories: int.tryParse(caloriesCtrl.text) ?? 0,
                );
                await ref.read(healthRepositoryProvider).saveMeal(meal);
                ref.invalidate(mealsForDateProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Log Meal'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Health & Vitals',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Vitals & BMI'),
            Tab(text: 'Water'),
            Tab(text: 'Sleep'),
            Tab(text: 'Products & Meds'),
            Tab(text: 'Workouts'),
            Tab(text: 'Diet & Meals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVitalsTab(isDark, primary),
          _buildWaterTab(isDark, primary),
          _buildSleepTab(isDark, primary),
          _buildProductsTab(isDark, primary),
          _buildWorkoutsTab(isDark, primary),
          _buildDietTab(isDark, primary),
        ],
      ),
    );
  }

  // --- 1. Vitals Tab ---
  Widget _buildVitalsTab(bool isDark, Color primary) {
    final vitalsAsync = ref.watch(latestVitalsProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        vitalsAsync.when(
          data: (vitals) {
            final bmi = vitals?.bmi ?? 22.5;
            String bmiCategory = 'Normal Weight';
            Color bmiColor = AppColors.success;
            if (bmi < 18.5) {
              bmiCategory = 'Underweight';
              bmiColor = const Color(0xFF38BDF8);
            } else if (bmi >= 25.0 && bmi < 30.0) {
              bmiCategory = 'Overweight';
              bmiColor = AppColors.high;
            } else if (bmi >= 30.0) {
              bmiCategory = 'Obese';
              bmiColor = AppColors.urgent;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // BMI Hero Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF16161A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF26262C) : const Color(0xFFE5E5EA),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Body Mass Index (BMI)',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: bmiColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              bmiCategory,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: bmiColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        bmi.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: bmiColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Healthy range: 18.5 – 24.9',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Metrics Grid (Height, Weight, Blood Type, Blood Sugar, Blood Pressure)
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildMetricCard('Height', '${vitals?.heightCm?.toInt() ?? 178} cm', Icons.height_rounded, isDark),
                    _buildMetricCard('Weight', '${vitals?.weightKg ?? 72.5} kg', Icons.monitor_weight_outlined, isDark),
                    _buildMetricCard('Blood Type', vitals?.bloodType ?? 'O+', Icons.bloodtype_outlined, isDark),
                    _buildMetricCard('Blood Sugar', '${vitals?.bloodSugar?.toInt() ?? 95} mg/dL', Icons.water_drop_outlined, isDark),
                    _buildMetricCard('Blood Pressure', '${vitals?.systolic ?? 120}/${vitals?.diastolic ?? 80}', Icons.favorite_border_rounded, isDark),
                    InkWell(
                      onTap: () => _showLogVitalsDialog(vitals),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primary.withValues(alpha: 0.35)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_note_rounded, size: 28, color: primary),
                            const SizedBox(height: 4),
                            Text(
                              'Log Vitals',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16161A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF26262C) : const Color(0xFFE5E5EA),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // --- 2. Water Tab ---
  Widget _buildWaterTab(bool isDark, Color primary) {
    final waterAsync = ref.watch(todayWaterLogProvider);
    final date = ref.watch(healthDateProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    return waterAsync.when(
      data: (water) {
        final progress = (water.glassesDrank / water.targetGlasses).clamp(0.0, 1.0);
        final ml = water.glassesDrank * 250;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16161A) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF26262C) : const Color(0xFFE5E5EA),
                  width: 0.8,
                ),
              ),
              child: Column(
                children: [
                  const Text('Daily Hydration Goal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 12,
                          backgroundColor: isDark ? const Color(0xFF26262C) : const Color(0xFFE8E8EC),
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF38BDF8)),
                        ),
                      ),
                      Column(
                        children: [
                          const Icon(Icons.water_drop_rounded, size: 36, color: Color(0xFF38BDF8)),
                          const SizedBox(height: 4),
                          Text(
                            '${water.glassesDrank}/${water.targetGlasses}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '$ml mL',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        onPressed: water.glassesDrank > 0
                            ? () async {
                                await ref.read(healthRepositoryProvider).updateWaterGlasses(dateStr, water.glassesDrank - 1);
                                ref.invalidate(todayWaterLogProvider);
                              }
                            : null,
                        icon: const Icon(Icons.remove_rounded, size: 24),
                      ),
                      const SizedBox(width: 24),
                      FilledButton.icon(
                        onPressed: () async {
                          await ref.read(healthRepositoryProvider).updateWaterGlasses(dateStr, water.glassesDrank + 1);
                          ref.invalidate(todayWaterLogProvider);
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Drink 1 Glass (250ml)'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  // --- 3. Sleep Tab ---
  Widget _buildSleepTab(bool isDark, Color primary) {
    final sleepLogsAsync = ref.watch(sleepLogsProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Sleep History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            FilledButton.icon(
              onPressed: _showLogSleepDialog,
              icon: const Icon(Icons.bedtime_outlined, size: 16),
              label: const Text('Log Sleep'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        sleepLogsAsync.when(
          data: (logs) {
            if (logs.isEmpty) {
              return const Center(child: Text('No sleep logs recorded yet.'));
            }

            return Column(
              children: logs.map((log) {
                final hours = log.durationMinutes ~/ 60;
                final mins = log.durationMinutes % 60;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF16161A) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF26262C) : const Color(0xFFE5E5EA),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF818CF8).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.nightlight_round, color: Color(0xFF818CF8), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${log.dateStr} · ${hours}h ${mins}m',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'Bed: ${log.bedTime}  ·  Wake: ${log.wakeTime}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: List.generate(
                          log.qualityRating,
                          (_) => const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ],
    );
  }

  // --- 4. Products Tab ---
  Widget _buildProductsTab(bool isDark, Color primary) {
    final productsAsync = ref.watch(healthProductsProvider);
    final takenIdsAsync = ref.watch(takenProductIdsProvider);
    final date = ref.watch(healthDateProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Daily Skincare & Medicine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            FilledButton.icon(
              onPressed: _showAddProductDialog,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Product'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        productsAsync.when(
          data: (products) {
            final takenIds = takenIdsAsync.value ?? <String>{};

            if (products.isEmpty) {
              return const Center(child: Text('No products or medicine added yet.'));
            }

            return Column(
              children: products.map((prod) {
                final isTaken = takenIds.contains(prod.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF16161A) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF26262C) : const Color(0xFFE5E5EA),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isTaken,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        onChanged: (val) async {
                          await ref.read(healthRepositoryProvider).toggleProductTaken(prod.id, dateStr, val ?? false);
                          ref.invalidate(takenProductIdsProvider);
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prod.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                decoration: isTaken ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            Text(
                              '${prod.category.toUpperCase()} · ${prod.dosageOrRoutine ?? prod.timeOfDay}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          await ref.read(healthRepositoryProvider).deleteProduct(prod.id);
                          ref.invalidate(healthProductsProvider);
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ],
    );
  }

  // --- 5. Workouts Tab ---
  Widget _buildWorkoutsTab(bool isDark, Color primary) {
    final workoutsAsync = ref.watch(workoutsListProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Workout Logs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            FilledButton.icon(
              onPressed: _showAddWorkoutDialog,
              icon: const Icon(Icons.fitness_center_rounded, size: 16),
              label: const Text('Log Workout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        workoutsAsync.when(
          data: (workouts) {
            if (workouts.isEmpty) {
              return const Center(child: Text('No workouts logged yet.'));
            }

            return Column(
              children: workouts.map((w) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF16161A) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF26262C) : const Color(0xFFE5E5EA),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF97316).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.fitness_center_rounded, color: Color(0xFFF97316), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(w.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            Text(
                              '${w.type} · ${w.durationMinutes} min · ${w.dateStr}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                        onPressed: () async {
                          await ref.read(healthRepositoryProvider).deleteWorkout(w.id);
                          ref.invalidate(workoutsListProvider);
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ],
    );
  }

  // --- 6. Diet Tab ---
  Widget _buildDietTab(bool isDark, Color primary) {
    final mealsAsync = ref.watch(mealsForDateProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Daily Meals & Nutrition', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            FilledButton.icon(
              onPressed: _showAddMealDialog,
              icon: const Icon(Icons.restaurant_rounded, size: 16),
              label: const Text('Log Meal'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        mealsAsync.when(
          data: (meals) {
            final totalCalories = meals.fold<int>(0, (sum, m) => sum + m.calories);

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF16161A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF26262C) : const Color(0xFFE5E5EA),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Calories Today', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(
                        '$totalCalories kcal',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (meals.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No meals logged for today.')),
                  )
                else
                  ...meals.map((m) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF16161A) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF26262C) : const Color(0xFFE5E5EA),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              m.mealType.toUpperCase(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: primary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              m.title,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            '${m.calories} kcal',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () async {
                              await ref.read(healthRepositoryProvider).deleteMeal(m.id);
                              ref.invalidate(mealsForDateProvider);
                            },
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ],
    );
  }
}
