// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/auth_api.dart';
import '../utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _saving = false;
  String? _error;
  String? _passLiveError;

  @override
  void dispose() {
    _userCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  /// Усиленная проверка пароля (пункт 7).
  String? _checkPassword(String v) {
    if (v.length < 8) return 'Минимум 8 символов';
    if (!RegExp(r'\d').hasMatch(v)) return 'Нужна хотя бы одна цифра';
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=]').hasMatch(v)) {
      return 'Нужен хотя бы один специальный символ';
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _passLiveError = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final api = context.read<AuthApi>();
      await api.register(
        username: _userCtrl.text.trim(),
        password: _passCtrl.text,
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Аккаунт создан. Войдите.')));
      context.go('/login');
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.errors.values.join('\n'));
    } on ConflictException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  TextFormField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Логин *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length < 3) {
                        return 'Логин не короче 3 символов';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ФИО *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => Validators.required(v, field: 'ФИО'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      return Validators.email(v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Пароль *',
                      border: const OutlineInputBorder(),
                      errorText: _passLiveError,
                    ),
                    onChanged: (v) {
                      setState(() => _passLiveError = _checkPassword(v));
                    },
                    validator: (v) => _checkPassword(v ?? ''),
                  ),
                  if (_passLiveError != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Требования: длина ≥ 8, цифра, спецсимвол',
                      style: TextStyle(
                        color: _passLiveError == null
                            ? Colors.green
                            : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_add),
                    label: const Text('Создать аккаунт'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Уже есть аккаунт? Войти'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
