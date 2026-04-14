import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _api = ApiClient();
  String? _error;
  bool _loading = false;

  Future<void> _register() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.register(_email.text, _password.text, _name.text);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', res.data['token']);
      if (mounted) context.go('/checkin');
    } catch (e) {
      setState(() { _error = 'Đăng ký thất bại'; });
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
              Text('Tạo tài khoản', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Tên hiển thị', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu', border: OutlineInputBorder())),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _register,
                  child: _loading ? const CircularProgressIndicator() : const Text('Đăng ký'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: () => context.go('/login'), child: const Text('Đã có tài khoản? Đăng nhập')),
            ],
          ),
        ),
      ),
    );
  }
}
