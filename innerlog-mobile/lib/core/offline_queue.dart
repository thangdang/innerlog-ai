import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';

/// Stores check-ins locally when offline, syncs when back online.
class OfflineQueue {
  static const _key = 'offline_checkins';

  /// Save a check-in to local queue.
  static Future<void> enqueue({
    required int mood,
    required String energy,
    String? note,
    List<String>? tags,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode({
      'mood_score': mood,
      'energy_level': energy,
      'text_note': note,
      'tags': tags ?? [],
      'queued_at': DateTime.now().toIso8601String(),
    }));
    await prefs.setStringList(_key, raw);
  }

  /// Number of pending offline check-ins.
  static Future<int> pendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).length;
  }

  /// Try to sync all queued check-ins to server.
  /// Returns number of successfully synced items.
  static Future<int> syncAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    if (raw.isEmpty) return 0;

    final api = ApiClient();
    final failed = <String>[];
    int synced = 0;

    for (final item in raw) {
      try {
        final data = jsonDecode(item) as Map<String, dynamic>;
        await api.createCheckin(
          data['mood_score'] as int,
          data['energy_level'] as String,
          data['text_note'] as String?,
          tags: (data['tags'] as List?)?.cast<String>(),
        );
        synced++;
      } catch (_) {
        // Still offline or server error — keep in queue
        failed.add(item);
      }
    }

    await prefs.setStringList(_key, failed);
    return synced;
  }
}
