import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';
import '../core/l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _api = ApiClient();
  String? _error;
  bool _loading = false;
  bool _showPassword = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.login(_email.text.trim(), _password.text);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', res.data['token']);
      if (res.data['refreshToken'] != null) {
        await prefs.setString('refreshToken', res.data['refreshToken']);
      }
      if (mounted) context.go('/app/home');
    } catch (e) {
      setState(() { _error = AppLocalizations.of(context).loginFailed; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🧠', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 8),
                  Text(l.appName, style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 4),
                  Text(l.trackYourLife, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 32),
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: l.email, prefixIcon: const Icon(Icons.email_outlined), border: const OutlineInputBorder()),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return l.emailRequired;
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) return l.emailInvalid;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: l.password,
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l.passwordRequired;
                      if (v.length < 6) return l.passwordMinLength;
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _loading ? null : _login,
                      child: _loading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l.login),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(onPressed: () => context.go('/register'), child: Text(l.noAccount)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
