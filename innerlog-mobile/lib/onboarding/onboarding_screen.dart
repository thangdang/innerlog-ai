import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';
import '../core/l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 21, minute: 0);
  bool _reminderEnabled = true;
  int _mood = 3;
  String _energy = 'normal';
  final _emojis = ['', '😢', '😟', '😐', '🙂', '😄'];

  void _next() {
    if (_page < 2) _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    await prefs.setString('reminder_time', '${_reminderTime.hour}:${_reminderTime.minute.toString().padLeft(2, '0')}');
    await prefs.setBool('reminder_enabled', _reminderEnabled);
    try { await ApiClient().createCheckin(_mood, _energy, null); } catch (_) {}
    if (mounted) context.go('/app/home');
  }

  Future<void> _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go('/app/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_page < 2) Align(alignment: Alignment.topRight, child: TextButton(onPressed: _skip, child: Text(l.skip))),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Page 1: Welcome
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text('🧠', style: TextStyle(fontSize: 80)),
                      const SizedBox(height: 24),
                      Text(l.appName, style: theme.textTheme.headlineLarge),
                      const SizedBox(height: 12),
                      Text(l.onboardingSubtitle, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 16),
                      Text(l.onboardingPrivacy, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    ]),
                  ),
                  // Page 2: Reminder
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text('⏰', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 24),
                      Text(l.onboardingReminder, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 12),
                      Text(l.onboardingReminderSub, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 24),
                      FilledButton.tonal(
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: _reminderTime);
                          if (picked != null) setState(() => _reminderTime = picked);
                        },
                        child: Text(_reminderTime.format(context), style: const TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(title: Text(l.enableReminder), value: _reminderEnabled, onChanged: (v) => setState(() => _reminderEnabled = v)),
                    ]),
                  ),
                  // Page 3: First check-in
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(l.onboardingMood, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(5, (i) {
                          final score = i + 1;
                          return GestureDetector(
                            onTap: () => setState(() => _mood = score),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                              decoration: BoxDecoration(
                                color: _mood == score ? theme.colorScheme.primaryContainer : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(_emojis[score], style: TextStyle(fontSize: _mood == score ? 44 : 32)),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment(value: 'low', label: Text(l.energyLow)),
                          ButtonSegment(value: 'normal', label: Text(l.energyNormal)),
                          ButtonSegment(value: 'high', label: Text(l.energyHigh)),
                        ],
                        selected: {_energy},
                        onSelectionChanged: (v) => setState(() => _energy = v.first),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => Container(
                  width: _page == i ? 24 : 8, height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(color: _page == i ? theme.colorScheme.primary : theme.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(4)),
                ))),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: FilledButton(
                  onPressed: _page < 2 ? _next : _complete,
                  child: Text(_page < 2 ? l.continueBtn : l.startJourney),
                )),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
