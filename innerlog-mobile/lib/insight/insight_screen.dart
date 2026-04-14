import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api.dart';

class InsightScreen extends StatefulWidget {
  const InsightScreen({super.key});
  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> {
  final _api = ApiClient();
  Map<String, dynamic>? _latest;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInsight();
  }

  Future<void> _loadInsight() async {
    try {
      final res = await _api.getLatestInsight();
      setState(() { _latest = res.data; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Insight')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _latest == null || _latest!.isEmpty
              ? const Center(child: Text('Chưa có insight. Hãy check-in thêm!'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Insight ${_latest!['period'] ?? ''}',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 16),
                      if (_latest!['bullets'] != null)
                        ...(_latest!['bullets'] as List).map((b) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(children: [
                                const Icon(Icons.circle, size: 8, color: Colors.deepPurple),
                                const SizedBox(width: 8),
                                Expanded(child: Text(b)),
                              ]),
                            )),
                      const SizedBox(height: 24),
                      if (_latest!['meta'] != null) ...[
                        _metaChip('Mood TB', '${_latest!['meta']['avg_mood']}/5'),
                        _metaChip('Xu hướng', _latest!['meta']['mood_trend'] ?? ''),
                        _metaChip('Stress', _latest!['meta']['stress_level'] ?? ''),
                      ],
                    ],
                  ),
                ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
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

  Widget _metaChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Chip(label: Text('$label: $value')),
    );
  }
}
