import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});
  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final _api = ApiClient();
  int _mood = 3;
  String _energy = 'normal';
  final _note = TextEditingController();
  bool _loading = false;
  String? _message;
  int _streak = 0;
  int _longestStreak = 0;

  final _emojis = ['', '😢', '😟', '😐', '🙂', '😄'];

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    try {
      final res = await _api.getStreak();
      setState(() {
        _streak = res.data['current_streak'] ?? 0;
        _longestStreak = res.data['longest_streak'] ?? 0;
      });
    } catch (_) {}
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _message = null; });
    try {
      final res = await _api.createCheckin(_mood, _energy, _note.text.isEmpty ? null : _note.text);
      final streakData = res.data['streak'];
      setState(() {
        _message = 'Check-in thành công!';
        _note.clear();
        if (streakData != null) {
          _streak = streakData['current_streak'] ?? _streak;
          _longestStreak = streakData['longest_streak'] ?? _longestStreak;
        }
      });
    } catch (e) {
      setState(() { _message = 'Lỗi khi check-in'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Check-in')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Streak banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(children: [
                    Text('🔥 $_streak', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text('Streak hiện tại', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                  Column(children: [
                    Text('🏆 $_longestStreak', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text('Kỷ lục', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Hôm nay bạn cảm thấy thế nào?', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) {
                final score = i + 1;
                return GestureDetector(
                  onTap: () => setState(() { _mood = score; }),
                  child: Column(children: [
                    Text(_emojis[score], style: TextStyle(fontSize: _mood == score ? 40 : 28)),
                    Text('$score', style: TextStyle(fontWeight: _mood == score ? FontWeight.bold : FontWeight.normal)),
                  ]),
                );
              }),
            ),
            const SizedBox(height: 24),
            Text('Năng lượng', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'low', label: Text('Thấp')),
                ButtonSegment(value: 'normal', label: Text('Bình thường')),
                ButtonSegment(value: 'high', label: Text('Cao')),
              ],
              selected: {_energy},
              onSelectionChanged: (v) => setState(() { _energy = v.first; }),
            ),
            const SizedBox(height: 24),
            TextField(controller: _note, maxLines: 3, decoration: const InputDecoration(labelText: 'Ghi chú (tùy chọn)', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            if (_message != null) Text(_message!, style: TextStyle(color: _message!.contains('thành công') ? Colors.green : Colors.red)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading ? const CircularProgressIndicator() : const Text('Check-in'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (i) {
          final routes = ['/checkin', '/insights', '/goals', '/profile'];
          context.go(routes[i]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.mood), label: 'Check-in'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'Insights'),
          NavigationDestination(icon: Icon(Icons.flag), label: 'Goals'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
