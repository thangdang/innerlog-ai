import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';
import '../core/l10n/app_localizations.dart';
import '../core/providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _api = ApiClient();
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadProfile(); }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getMe();
      setState(() { _user = res.data; _loading = false; });
    } catch (e) { setState(() => _loading = false); }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refreshToken');
    if (mounted) context.go('/login');
  }

  void _showLanguagePicker(BuildContext context) {
    final l = AppLocalizations.of(context);
    final currentLocale = ref.read(localeProvider);
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.language, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ListTile(
            leading: const Text('🇻🇳', style: TextStyle(fontSize: 24)),
            title: const Text('Tiếng Việt'),
            trailing: currentLocale.languageCode == 'vi' ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
              ref.read(localeProvider.notifier).setLocale('vi');
              _api.updateProfile({'language': 'vi'});
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
            title: const Text('English'),
            trailing: currentLocale.languageCode == 'en' ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
              ref.read(localeProvider.notifier).setLocale('en');
              _api.updateProfile({'language': 'en'});
              Navigator.pop(context);
            },
          ),
        ]),
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    final l = AppLocalizations.of(context);
    final current = TextEditingController();
    final newPass = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.changePassword, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(controller: current, obscureText: true, decoration: InputDecoration(labelText: l.currentPassword, border: const OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: newPass, obscureText: true, decoration: InputDecoration(labelText: l.newPassword, border: const OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(
            onPressed: () async {
              if (newPass.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.passwordMinLength)));
                return;
              }
              try {
                await _api.changePassword(current.text, newPass.text);
                if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.passwordChanged))); }
              } catch (_) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.passwordChangeFailed)));
              }
            },
            child: Text(l.confirm),
          )),
        ]),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    final l = AppLocalizations.of(context);
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(l.deleteAccountConfirm),
      content: Text(l.deleteAccountWarning),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        TextButton(
          onPressed: () async {
            await _api.deleteAccount();
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            if (mounted) { Navigator.pop(context); context.go('/login'); }
          },
          child: Text(l.delete, style: const TextStyle(color: Colors.red)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.profile)),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(padding: const EdgeInsets.all(24), children: [
                Center(child: CircleAvatar(radius: 40, child: Text((_user?['display_name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 32)))),
                const SizedBox(height: 16),
                Center(child: Text(_user?['display_name'] ?? 'User', style: theme.textTheme.headlineSmall)),
                Center(child: Text(_user?['email'] ?? '', style: theme.textTheme.bodyMedium)),
                const SizedBox(height: 8),
                Center(child: Chip(
                  avatar: Icon(_user?['plan'] == 'premium' ? Icons.star : Icons.star_border, size: 18),
                  label: Text(_user?['plan'] == 'premium' ? l.premium : l.free),
                )),
                const SizedBox(height: 24),
                Card(child: Column(children: [
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(l.language),
                    subtitle: Text(currentLocale.languageCode == 'en' ? 'English' : 'Tiếng Việt'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLanguagePicker(context),
                  ),
                  ListTile(leading: const Icon(Icons.access_time), title: Text(l.timezone), subtitle: Text(_user?['timezone'] ?? 'Asia/Ho_Chi_Minh')),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: Text(l.reminder),
                    subtitle: Text(_user?['reminder_enabled'] == true ? l.reminderOn(_user?['reminder_time'] ?? '21:00') : l.reminderOff),
                  ),
                ])),
                const SizedBox(height: 16),
                Card(child: Column(children: [
                  ListTile(leading: const Icon(Icons.download), title: Text(l.exportData), onTap: () async {
                    try { await _api.exportData(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.dataExported))); } catch (_) {}
                  }),
                  ListTile(leading: const Icon(Icons.lock, color: Colors.orange), title: Text(l.changePassword), onTap: () => _showChangePassword(context)),
                  ListTile(leading: const Icon(Icons.delete_forever, color: Colors.red), title: Text(l.deleteAccount, style: const TextStyle(color: Colors.red)), onTap: () => _confirmDeleteAccount(context)),
                ])),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _logout, icon: const Icon(Icons.logout), label: Text(l.logout))),
                const SizedBox(height: 32),
              ]),
      ),
    );
  }
}
