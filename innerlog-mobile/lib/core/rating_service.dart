import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';

/// Smart in-app rating prompt.
/// Triggers after 7-day streak or positive insight.
/// Never shows when user is stressed. Respects 30-day cooldown.
class RatingService {
  static const _lastPromptKey = 'last_rating_prompt';
  static const _neverShowKey = 'rating_never_show';
  static const _cooldownDays = 30;

  /// Check conditions and show rating dialog if appropriate.
  /// [streak] — current streak count
  /// [avgMood] — latest insight avg mood (null if no insight)
  /// [hasHighSeverityAlert] — true if coach detected high severity issue
  static Future<void> checkAndShow(
    BuildContext context, {
    required int streak,
    double? avgMood,
    bool hasHighSeverityAlert = false,
  }) async {
    // Never show if user opted out
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_neverShowKey) == true) return;

    // Never show when user is stressed
    if (hasHighSeverityAlert) return;

    // Cooldown: don't show within 30 days of last prompt
    final lastPrompt = prefs.getString(_lastPromptKey);
    if (lastPrompt != null) {
      final lastDate = DateTime.tryParse(lastPrompt);
      if (lastDate != null && DateTime.now().difference(lastDate).inDays < _cooldownDays) {
        return;
      }
    }

    // Trigger conditions:
    // 1. Streak >= 7 days (user is engaged)
    // 2. OR latest insight mood >= 3.5 (user feels positive)
    final shouldShow = streak >= 7 || (avgMood != null && avgMood >= 3.5);
    if (!shouldShow) return;

    // Show the dialog
    if (!context.mounted) return;
    await _showRatingDialog(context, prefs);
  }

  static Future<void> _showRatingDialog(BuildContext context, SharedPreferences prefs) async {
    await prefs.setString(_lastPromptKey, DateTime.now().toIso8601String());

    if (!context.mounted) return;
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.ratingTitle),
        content: Text(l.ratingMessage),
        actions: [
          TextButton(
            onPressed: () {
              prefs.setBool(_neverShowKey, true);
              Navigator.pop(context);
            },
            child: Text(l.rateNever, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.rateLater),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Open store URL via url_launcher
            },
            child: Text(l.rateNow),
          ),
        ],
      ),
    );
  }
}
