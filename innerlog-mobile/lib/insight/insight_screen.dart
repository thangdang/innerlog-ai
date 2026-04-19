import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/api.dart';
import '../core/l10n/app_localizations.dart';

class InsightScreen extends StatefulWidget {
  const InsightScreen({super.key});
  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> with SingleTickerProviderStateMixin {
  final _api = ApiClient();
  late TabController _tabController;

  Map<String, dynamic>? _latest;
  List<dynamic> _history = [];
  List<Map<String, dynamic>> _moodTrend = [];
  bool _loadingLatest = true;
  bool _loadingHistory = true;
  bool _loadingChart = true;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadLatest(), _loadHistory(), _loadChart()]);
  }

  Future<void> _loadLatest() async {
    setState(() => _loadingLatest = true);
    try {
      final res = await _api.getLatestInsight();
      if (res.data != null && res.data is Map && (res.data as Map).isNotEmpty) {
        _latest = res.data;
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingLatest = false);
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final res = await _api.getInsightHistory();
      _history = (res.data is List) ? res.data : [];
    } catch (_) {}
    if (mounted) setState(() => _loadingHistory = false);
  }

  Future<void> _loadChart() async {
    setState(() => _loadingChart = true);
    try {
      final res = await _api.getCheckinStats(days: 30);
      final trend = res.data['moodTrend'] as List? ?? [];
      _moodTrend = trend.map<Map<String, dynamic>>((e) => {
        'date': e['date'] as String,
        'avg': (e['avg'] as num).toDouble(),
      }).toList();
    } catch (_) {}
    if (mounted) setState(() => _loadingChart = false);
  }

  Future<void> _generate(String period) async {
    setState(() => _generating = true);
    try {
      await _api.generateInsight(period: period);
      await _loadLatest();
      await _loadHistory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).generateError)),
        );
      }
    }
    if (mounted) setState(() => _generating = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).insights),
        bottom: TabBar(controller: _tabController, tabs: [
          Tab(text: AppLocalizations.of(context).latest),
          Tab(text: AppLocalizations.of(context).history),
        ]),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLatestTab(theme),
          _buildHistoryTab(theme),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generating ? null : () => _showPeriodPicker(),
        icon: _generating
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.auto_awesome),
        label: Text(_generating ? AppLocalizations.of(context).generating : AppLocalizations.of(context).generateInsight),
      ),
    );
  }

  void _showPeriodPicker() {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.selectPeriod, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ...[ ('7d', l.days7), ('30d', l.days30), ('60d', l.days60), ('90d', l.days90) ].map((e) => ListTile(
            title: Text(e.$2),
            leading: const Icon(Icons.calendar_today),
            onTap: () { Navigator.pop(context); _generate(e.$1); },
          )),
        ]),
      ),
    );
  }

  Widget _buildLatestTab(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () async { await _loadLatest(); await _loadChart(); },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mood trend chart
          if (!_loadingChart && _moodTrend.isNotEmpty) ...[
            Text(AppLocalizations.of(context).moodLast30, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: LineChart(LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 28, interval: 1,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10)),
                  )),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 24, interval: (_moodTrend.length / 5).ceilToDouble().clamp(1, 10),
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= _moodTrend.length) return const SizedBox();
                      final d = _moodTrend[i]['date'] as String;
                      return Text(d.substring(5), style: const TextStyle(fontSize: 9));
                    },
                  )),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                minY: 1, maxY: 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(_moodTrend.length, (i) =>
                      FlSpot(i.toDouble(), _moodTrend[i]['avg'] as double)),
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 3,
                    dotData: FlDotData(show: _moodTrend.length <= 14),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.colorScheme.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              )),
            ),
            const SizedBox(height: 24),
          ],

          // Latest insight
          if (_loadingLatest)
            const Center(child: CircularProgressIndicator())
          else if (_latest == null)
            Center(child: Column(children: [
              const SizedBox(height: 32),
              const Text('📊', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text(AppLocalizations.of(context).noInsight, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(AppLocalizations.of(context).generateInsight, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            ]))
          else ...[
            Text('Insight ${_latest!['period'] ?? ''}', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            if (_latest!['bullets'] != null)
              ...(_latest!['bullets'] as List).map((b) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.circle, size: 8, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Expanded(child: Text('$b')),
                    ]),
                  )),
            const SizedBox(height: 16),
            if (_latest!['meta'] != null) Wrap(spacing: 8, runSpacing: 4, children: [
              Chip(avatar: const Text('😊'), label: Text('Mood: ${_latest!['meta']['avg_mood']}/5')),
              Chip(avatar: const Text('📈'), label: Text('Trend: ${_latest!['meta']['mood_trend'] ?? ''}')),
              Chip(avatar: const Text('🧠'), label: Text('Stress: ${_latest!['meta']['stress_level'] ?? ''}')),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab(ThemeData theme) {
    if (_loadingHistory) return const Center(child: CircularProgressIndicator());
    if (_history.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).noInsightHistory, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)));
    }
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (_, i) {
          final insight = _history[i];
          final bullets = (insight['bullets'] as List?) ?? [];
          final meta = insight['meta'] as Map<String, dynamic>?;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Chip(label: Text(insight['period'] ?? '')),
                  Text(
                    _formatDate(insight['created_at']),
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ]),
                const SizedBox(height: 8),
                ...bullets.take(3).map((b) => Text('• $b', style: theme.textTheme.bodyMedium)),
                if (meta != null) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    Text('Mood: ${meta['avg_mood']}/5', style: theme.textTheme.bodySmall),
                    const SizedBox(width: 12),
                    Text('Stress: ${meta['stress_level']}', style: theme.textTheme.bodySmall),
                  ]),
                ],
              ]),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return date.toString();
    }
  }
}
