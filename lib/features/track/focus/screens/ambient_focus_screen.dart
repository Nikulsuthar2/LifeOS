import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/focus_provider.dart';

class AmbientFocusScreen extends ConsumerStatefulWidget {
  const AmbientFocusScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AmbientFocusScreen()),
    );
  }

  @override
  ConsumerState<AmbientFocusScreen> createState() => _AmbientFocusScreenState();
}

class _AmbientFocusScreenState extends ConsumerState<AmbientFocusScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  String _selectedSound = 'Brown Noise';
  bool _soundPlaying = true;

  final _sounds = ['Brown Noise', 'Lo-Fi Rain', 'Alpha Waves', 'Quiet White Noise'];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(focusTimerProvider);
    final notifier = ref.read(focusTimerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF09090C),
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient visual pulsing aura
            if (_soundPlaying)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Center(
                    child: Container(
                      width: 280 + (_pulseController.value * 40),
                      height: 280 + (_pulseController.value * 40),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.12 * _pulseController.value),
                            blurRadius: 100,
                            spreadRadius: 30,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Top Bar
            Positioned(
              top: 16,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181820),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF282834)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_rounded, size: 14, color: Color(0xFF10B981)),
                        SizedBox(width: 6),
                        Text(
                          'DISTRACTION BLOCKER ACTIVE',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white70),
                    tooltip: 'Exit Ambient Mode',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Main Center Timer
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (timerState.linkedTaskTitle != null || timerState.linkedTopicTitle != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E28),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        timerState.linkedTaskTitle ?? timerState.linkedTopicTitle!,
                        style: const TextStyle(
                          color: Color(0xFF818CF8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  // Giant Digits
                  Text(
                    timerState.formattedTime,
                    style: const TextStyle(
                      fontSize: 76,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 2,
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timerState.isRunning ? 'DEEP FOCUS SESSION' : 'SESSION PAUSED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: timerState.isRunning ? const Color(0xFF6366F1) : Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF1E1E28),
                          padding: const EdgeInsets.all(14),
                        ),
                        icon: const Icon(Icons.replay_rounded, color: Colors.white70),
                        onPressed: () => notifier.reset(),
                      ),
                      const SizedBox(width: 16),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.all(18),
                        ),
                        icon: Icon(
                          timerState.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          if (timerState.isRunning) {
                            notifier.pause();
                          } else {
                            notifier.start();
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF1E1E28),
                          padding: const EdgeInsets.all(14),
                        ),
                        icon: const Icon(Icons.stop_rounded, color: Colors.white70),
                        onPressed: () => notifier.reset(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Audio / Ambient sound bar
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF14141C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF22222E)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _soundPlaying ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        color: _soundPlaying ? const Color(0xFF6366F1) : Colors.white38,
                      ),
                      onPressed: () {
                        setState(() => _soundPlaying = !_soundPlaying);
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _sounds.map((sound) {
                            final isSel = _selectedSound == sound;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(sound, style: const TextStyle(fontSize: 11)),
                                selected: isSel && _soundPlaying,
                                onSelected: (sel) {
                                  setState(() {
                                    _selectedSound = sound;
                                    _soundPlaying = true;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
