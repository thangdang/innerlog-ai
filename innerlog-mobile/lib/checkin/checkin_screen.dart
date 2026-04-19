import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api.dart';
import '../core/offline_queue.dart';
import '../core/l10n/app_localizations.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});
  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> with SingleTickerProviderStateMixin {
  final _api = ApiClient();
  int _mood = 3;
  String _energy = 'normal';
  final _note = TextEditingController();
  bool _loading = false;
  bool _success = false;
  int _streak = 0;
  int _longestStreak = 0;
  final _emojis = ['', '😢', '😟', '😐', '🙂', '😄'];
  final _availableTags = ['work', 'study', 'health', 'relationship', 'finance', 'mood'];
  final Set<String> _selectedTags = {};
  final _milestones = {7, 30, 100, 365};

  late AnimationController _checkAnim;
  late Animation<double> _checkScale;

  Map<String, String> _tagLabels(AppLocalizations l) => {
    'work': l.tagWork, 'study': l.tagStudy, 'health': l.tagHealth,
    'relationship': l.tagRelationship, 'finance': l.tagFinance, 'mood': l.tagMood,
  };

  @override
  void initState() {
    super.initState();
    _loadStreak();
    _checkAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _checkScale = CurvedAnimation(parent: _checkAnim, curve: Curves.elasticOut);
  }

  @override
  void dispose() { _checkAnim.dispose(); _note.dispose(); super.dispose(); }

  Future<void> _loadStreak() async {
    try {
      final res = await _api.getStreak();
      setState(() { _streak = res.data['current_streak'] ?? 0; _longestStreak = res.data['longest_streak'] ?? 0; });
    } catch (_) {}
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    setState(() { _loading = true; _success = false; });
    try {
      final res = await _api.createCheckin(_mood, _energy, _note.text.isEmpty ? null : _note.text, tags: _selectedTags.toList());
      final streakData = res.data['streak'];
      int newStreak = _streak;
      if (streakData != null) { newStreak = streakData['current_streak'] ?? _streak; _longestStreak = streakData['longest_streak'] ?? _longestStreak; }
      HapticFeedback.mediumImpact();
      setState(() { _success = true; _note.clear(); _selectedTags.clear(); _streak = newStreak; });
      _checkAnim.forward(from: 0);
      if (_milestones.contains(newStreak)) _showMilestone(newStreak);
      Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _success = false); });
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.connectionError) {
        await OfflineQueue.enqueue(mood: _mood, energy: _energy, note: _note.text.isEmpty ? null : _note.text, tags: _selectedTags.toList());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.offlineCheckin)));
          setState(() { _success = true; _note.clear(); _selectedTags.clear(); });
          _checkAnim.forward(from: 0);
          Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _success = false); });
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.checkinError)));
      }
    } finally { if (mounted) setState(() => _loading = false); }
  }

  void _showMilestone(int days) {
    final l = AppLocalizations.of(context);
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(l.congratulations),
      content: Text(l.streakMilestone(days)),
      actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.thanks))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final labels = _tagLabels(l);
    return Scaffold(
      appBar: AppBar(title: Text(l.dailyCheckin)),
      body: RefreshIndicator(
        onRefresh: _loadStreak,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Streak banner
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)]), borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                Column(children: [
                  Text('🔥 $_streak', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(l.streak, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
                Column(children: [
                  Text('🏆 $_longestStreak', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(l.record, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ]),
            ),
            const SizedBox(height: 24),
            Text(l.howAreYou, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) {
                final score = i + 1;
                return Semantics(
                  label: l.moodSemantic(score), selected: _mood == score, button: true,
                  child: GestureDetector(
                    onTap: () { HapticFeedback.lightImpact(); setState(() => _mood = score); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      decoration: BoxDecoration(color: _mood == score ? theme.colorScheme.primaryContainer : Colors.transparent, borderRadius: BorderRadius.circular(16)),
                      child: Column(children: [
                        Text(_emojis[score], style: TextStyle(fontSize: _mood == score ? 40 : 28)),
                        Text('$score', style: TextStyle(fontWeight: _mood == score ? FontWeight.bold : FontWeight.normal)),
                      ]),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Text(l.energy, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [ButtonSegment(value: 'low', label: Text(l.energyLow)), ButtonSegment(value: 'normal', label: Text(l.energyNormal)), ButtonSegment(value: 'high', label: Text(l.energyHigh))],
              selected: {_energy}, onSelectionChanged: (v) => setState(() => _energy = v.first),
            ),
            const SizedBox(height: 24),
            Text(l.tags, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, children: _availableTags.map((tag) => FilterChip(
              label: Text(labels[tag] ?? tag), selected: _selectedTags.contains(tag),
              onSelected: (s) => setState(() { if (s) _selectedTags.add(tag); else _selectedTags.remove(tag); }),
            )).toList()),
            const SizedBox(height: 24),
            TextField(controller: _note, maxLines: 3, maxLength: 500, decoration: InputDecoration(labelText: l.noteOptional, hintText: l.noteHint, border: const OutlineInputBorder())),
            const SizedBox(height: 24),
            if (_success)
              Center(child: ScaleTransition(scale: _checkScale, child: Column(children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 64), const SizedBox(height: 8),
                Text(l.checkinSuccess, style: theme.textTheme.titleMedium?.copyWith(color: Colors.green)),
              ])))
            else
              SizedBox(width: double.infinity, height: 48, child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l.checkin),
              )),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }
}
