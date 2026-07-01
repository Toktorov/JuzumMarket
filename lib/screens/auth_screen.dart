import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../data/api.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import '../l10n/l10n.dart';
import 'main_screen.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _loading = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final phone = '+996$digits';
    final password = _passwordController.text;

    setState(() => _loading = true);
    try {
      final state = context.read<AppState>();
      if (_isLogin) {
        await state.login(phone, password);
      } else {
        await state.register(
            name, phone, _emailController.text.trim(), password);
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(context.tr('Нет связи с сервером. Проверьте подключение.'));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFE5484D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                // Logo area
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Image.asset(
                      'assets/logo/juzum_glyph_white.png',
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.shopping_bag_rounded,
                        size: 32,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'JUZUM',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: c.ink,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  _isLogin ? context.tr('Вход') : context.tr('Регистрация'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin
                      ? context.tr('Введите номер телефона для входа')
                      : context.tr('Создайте аккаунт для покупок'),
                  style: TextStyle(
                    fontSize: 14,
                    color: c.grey,
                  ),
                ),
                const SizedBox(height: 28),
                if (!_isLogin) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: context.tr('Ваше имя'),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (v) {
                      if (!_isLogin && (v == null || v.trim().isEmpty)) {
                        return context.tr('Введите имя');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: context.tr('Email (для сброса пароля)'),
                      prefixIcon: const Icon(Icons.mail_outline),
                    ),
                    validator: (v) {
                      if (_isLogin) return null;
                      final t = (v ?? '').trim();
                      if (!t.contains('@') || !t.contains('.')) {
                        return context.tr('Введите корректный email');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_KgPhoneFormatter()],
                  decoration: InputDecoration(
                    hintText: '700 12 34 56',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                      child: Text(
                        '🇰🇬 +996',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.ink,
                        ),
                      ),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                  validator: (v) {
                    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 9) {
                      return context.tr('Введите 9 цифр номера');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: context.tr('Пароль'),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 4) {
                      return context.tr('Минимум 4 символа');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  text: _isLogin
                      ? context.tr('Войти')
                      : context.tr('Зарегистрироваться'),
                  gradient: true,
                  loading: _loading,
                  onPressed: _submit,
                ),
                if (_isLogin)
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      ),
                      child: Text(
                        context.tr('Забыли пароль?'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.solid,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _isLogin = !_isLogin),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: c.grey,
                        ),
                        children: [
                          TextSpan(
                            text: _isLogin
                                ? context.tr('Нет аккаунта? ')
                                : context.tr('Уже есть аккаунт? '),
                          ),
                          TextSpan(
                            text: _isLogin
                                ? context.tr('Регистрация')
                                : context.tr('Войти'),
                            style: const TextStyle(
                              color: AppColors.solid,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Номер КР: максимум 9 цифр, группировка «700 12 34 56».
class _KgPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 9) digits = digits.substring(0, 9);
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 5 || i == 7) buf.write(' ');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
