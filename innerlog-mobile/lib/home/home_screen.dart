import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api.dart';
import '../core/offline_queue.dart';
import '../core/rating_service.dart';
import '../core/l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiClient();
  bool _loading = true;
  int _streak = 0;
  int _longestStreak = 0;
  Map<String, dynamic>? _latestInsight;
  List<dynamic> _goals = [];
  int _unreadNotifications = 0;
  List<dynamic> _coachAlerts = [];

  final _emojis = ['', '😢', '😟', '😐', '🙂', '😄'];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    // Try syncing offline check-ins first
    try {
      final synced = await OfflineQueue.syncAll();
      if (synced > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).syncedOffline(synced))),
        );
      }
    } catch (_) {}
    await Future.wait([
      _loadStreak(),
      _loadInsight(),
      _loadGoals(),
      _loadNotifications(),
    ]);
    setState(() => _loading = false);

    // Check if we should show rating prompt
    if (mounted) {
      final avgMood = _latestInsight?['meta']?['avg_mood'];
      final hasHighAlert = _coachAlerts.any((a) => a['severity'] == 'high');
      RatingService.checkAndShow(
        context,
        streak: _streak,
        avgMood: avgMood is num ? avgMood.toDouble() : null,
        hasHighSeverityAlert: hasHighAlert,
      );
    }
  }

  Future<void> _loadStreak() async {
    try {
      final res = await _api.getStreak();
      _streak = res.data['current_streak'] ?? 0;
      _longestStreak = res.data['longest_streak'] ?? 0;
    } catch (_) {}
  }

  Future<void> _loadInsight() async {
    try {
      final res = await _api.getLatestInsight();
      if (res.data != null && res.data is Map && (res.data as Map).isNotEmpty) {
        _latestInsight = res.data;
      }
    } catch (_) {}
  }

  Future<void> _loadGoals() async {
    try {
      final res = await _api.getGoals(status: 'active');
      _goals = (res.data is List) ? res.data : [];
    } catch (_) {}
  }

  Future<void> _loadNotifications() async {
    try {
      final res = await _api.getNotifications(unreadOnly: true);
      _unreadNotifications = res.data['unreadCount'] ?? 0;
      final notifs = res.data['notifications'] as List? ?? [];
      _coachAlerts = notifs.where((n) => n['type'] == 'coach').take(2).toList();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).appName),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: Badge(
              isLabelVisible: _unreadNotifications > 0,
              label: Text('$_unreadNotifications'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStreakBanner(theme),
                  const SizedBox(height: 20),
                  _buildQuickMood(theme),
                  const SizedBox(height: 20),
                  _buildInsightCard(theme),
                  const SizedBox(height: 16),
                  _buildGoalsCard(theme),
                  const SizedBox(height: 16),
                  if (_coachAlerts.isNotEmpty) _buildCoachCard(theme),
                ],
              ),
      ),
    );
  }

  Widget _buildStreakBanner(ThemeData theme) {
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(children: [
            Text('🔥 $_streak', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(l.currentStreak, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
          Container(width: 1, height: 40, color: Colors.white24),
          Column(children: [
            Text('🏆 $_longestStreak', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(l.record, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
        ],
      ),
    );
  }

  Widget _buildQuickMood(ThemeData theme) {
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.howAreYou, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) {
                final score = i + 1;
                return GestureDetector(
                  onTap: () => context.go('/app/checkin'),
                  child: Text(_emojis[score], style: const TextStyle(fontSize: 36)),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(ThemeData theme) {
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.weeklyInsight, style: theme.textTheme.titleMedium),
                TextButton(
                  onPressed: () => context.go('/app/insights'),
                  child: Text(l.viewDetail),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_latestInsight != null && _latestInsight!['bullets'] != null)
              ...(_latestInsight!['bullets'] as List).take(3).map((b) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('• $b', style: theme.textTheme.bodyMedium),
                  ))
            else
              Text(l.noInsight,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsCard(ThemeData theme) {
    final l = AppLocalizations.of(context);
    final activeGoals = _goals.length;
    final completed = _goals.where((g) => g['status'] == 'completed').length;
    return Card(
      child: ListTile(
        leading: const Text('🎯', style: TextStyle(fontSize: 28)),
        title: Text(l.goalsCompleted(completed, activeGoals)),
        subtitle: activeGoals > 0
            ? LinearProgressIndicator(
                value: activeGoals > 0 ? completed / activeGoals : 0,
                borderRadius: BorderRadius.circular(4),
              )
            : Text(l.noGoals),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/app/goals'),
      ),
    );
  }

  Widget _buildCoachCard(ThemeData theme) {
    final l = AppLocalizations.of(context);
    return Card(
      color: theme.colorScheme.errorContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.silentCoach, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._coachAlerts.map((a) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(a['message'] ?? '', style: theme.textTheme.bodyMedium),
                )),
          ],
        ),
      ),
    );
  }
}
