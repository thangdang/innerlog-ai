import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _api = ApiClient();
  String? _error;
  bool _loading = false;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.login(_email.text, _password.text);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', res.data['token']);
      if (mounted) context.go('/checkin');
    } catch (e) {
      setState(() { _error = 'Đăng nhập thất bại'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('InnerLog', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text('Theo dõi cuộc sống của bạn', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 32),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu', border: OutlineInputBorder())),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _login,
                  child: _loading ? const CircularProgressIndicator() : const Text('Đăng nhập'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: () => context.go('/register'), child: const Text('Chưa có tài khoản? Đăng ký')),
            ],
          ),
        ),
      ),
    );
  }
}
