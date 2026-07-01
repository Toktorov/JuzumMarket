import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../data/api.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import '../l10n/l10n.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();

  bool _codeSent = false;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFE5484D)),
    );
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      _error(context.tr('Введите корректный email'));
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AppState>().forgotPassword(email);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Код отправлен на почту')),
          backgroundColor: AppColors.solid,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _error(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _error(context.tr('Нет связи с сервером'));
    }
  }

  Future<void> _reset() async {
    final code = _code.text.trim();
    final password = _password.text;
    if (code.length < 4) {
      _error(context.tr('Введите код из письма'));
      return;
    }
    if (password.length < 4) {
      _error(context.tr('Пароль не короче 4 символов'));
      return;
    }
    setState(() => _loading = true);
    try {
      await context
          .read<AppState>()
          .resetPassword(_email.text.trim(), code, password);
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Пароль изменён. Войдите с новым паролем.')),
          backgroundColor: AppColors.solid,
        ),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _error(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _error(context.tr('Нет связи с сервером'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Сброс пароля'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppColors.gradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.lock_reset_rounded,
                  size: 34, color: AppColors.white),
            ),
            const SizedBox(height: 20),
            Text(
              _codeSent ? context.tr('Введите код') : context.tr('Забыли пароль?'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _codeSent
                  ? context.trp(
                      'Мы отправили 6-значный код на {email}. Введите его и придумайте новый пароль.',
                      {'email': _email.text.trim()})
                  : context.tr(
                      'Укажите email, который вы привязали при регистрации — пришлём код для сброса.'),
              style: TextStyle(fontSize: 14, color: c.grey, height: 1.4),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _email,
              enabled: !_codeSent,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Email',
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            if (_codeSent) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: context.tr('Код из письма'),
                  prefixIcon: const Icon(Icons.pin_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: context.tr('Новый пароль'),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
            ],
            const SizedBox(height: 28),
            PrimaryButton(
              text: _codeSent
                  ? context.tr('Сбросить пароль')
                  : context.tr('Отправить код'),
              gradient: true,
              loading: _loading,
              onPressed: _codeSent ? _reset : _sendCode,
            ),
            if (_codeSent) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _loading ? null : _sendCode,
                  child: Text(
                    context.tr('Отправить код повторно'),
                    style: TextStyle(color: c.grey),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
