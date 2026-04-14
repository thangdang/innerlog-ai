import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiClient();
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await _api.getMe();
      setState(() { _user = res.data; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (mounted) context.go('/login');
  }

  void _showChangePassword(BuildContext context) {
    final current = TextEditingController();
    final newPass = TextEditingController();
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: current, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại')),
          const SizedBox(height: 12),
          TextField(controller: newPass, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu mới')),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              try {
                await _api.changePassword(current.text, newPass.text);
                if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công'))); }
              } catch (_) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thất bại')));
              }
            },
            child: const Text('Xác nhận'),
          ),
        ]),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa tài khoản?'),
        content: const Text('Toàn bộ dữ liệu sẽ bị xóa vĩnh viễn. Không thể khôi phục.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              await _api.deleteAccount();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) { Navigator.pop(context); context.go('/login'); }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                CircleAvatar(radius: 40, child: Text((_user?['display_name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 32))),
                const SizedBox(height: 16),
                Text(_user?['display_name'] ?? 'User', style: Theme.of(context).textTheme.headlineSmall),
                Text(_user?['email'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Chip(label: Text('Plan: ${_user?['plan'] ?? 'free'}')),
                const SizedBox(height: 24),
                ListTile(leading: const Icon(Icons.language), title: const Text('Ngôn ngữ'), subtitle: Text(_user?['language'] ?? 'vi')),
                ListTile(leading: const Icon(Icons.access_time), title: const Text('Múi giờ'), subtitle: Text(_user?['timezone'] ?? 'Asia/Ho_Chi_Minh')),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Xuất dữ liệu cá nhân'),
                  onTap: () async {
                    try {
                      await _api.exportData();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dữ liệu đã được xuất')));
                    } catch (_) {}
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lock, color: Colors.orange),
                  title: const Text('Đổi mật khẩu'),
                  onTap: () => _showChangePassword(context),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Xóa tài khoản', style: TextStyle(color: Colors.red)),
                  onTap: () => _confirmDeleteAccount(context),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(onPressed: _logout, child: const Text('Đăng xuất')),
                ),
              ]),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 3,
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
