import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/l10n/app_localizations.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _api = ApiClient();
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _loading = true;

  static const _typeIcons = {
    'coach': Icons.psychology,
    'reminder': Icons.alarm,
    'insight': Icons.insights,
    'streak': Icons.local_fire_department,
    'system': Icons.info_outline,
  };

  static const _typeColors = {
    'coach': Colors.purple,
    'reminder': Colors.blue,
    'insight': Colors.teal,
    'streak': Colors.orange,
    'system': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getNotifications();
      _notifications = res.data['notifications'] ?? [];
      _unreadCount = res.data['unreadCount'] ?? 0;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _markRead(String id) async {
    try {
      await _api.markRead(id);
      _load();
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await _api.markAllRead();
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('${AppLocalizations.of(context).notifications}${_unreadCount > 0 ? ' ($_unreadCount)' : ''}'),
        actions: [
          if (_unreadCount > 0)
            TextButton(onPressed: _markAllRead, child: Text(AppLocalizations.of(context).markAllRead)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('🔔', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 12),
                  Text(AppLocalizations.of(context).noNotifications, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final n = _notifications[i];
                      final type = n['type'] ?? 'system';
                      final isRead = n['read'] == true;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (_typeColors[type] ?? Colors.grey).withOpacity(0.15),
                          child: Icon(_typeIcons[type] ?? Icons.info, color: _typeColors[type]),
                        ),
                        title: Text(n['title'] ?? '', style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                        subtitle: Text(n['message'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Text(_timeAgo(n['created_at']), style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        tileColor: isRead ? null : theme.colorScheme.primaryContainer.withOpacity(0.08),
                        onTap: () { if (!isRead) _markRead(n['_id']); },
                      );
                    },
                  ),
                ),
    );
  }

  String _timeAgo(dynamic date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}p';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }
}
