import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../theme/app_colors.dart';
import '../l10n/l10n.dart';
import '../widgets/primary_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _name = TextEditingController(text: state.userName);
    _phone = TextEditingController(text: state.userPhone);
    _email = TextEditingController(text: state.userEmail);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _save() {
    context.read<AppState>().updateProfile(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
        );
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('Профиль сохранён')),
        backgroundColor: AppColors.solid,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Настройки'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Label(context.tr('Профиль'), c: c),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: _name,
              decoration: InputDecoration(
                hintText: context.tr('Имя'),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
          ),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: context.tr('Телефон'),
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: context.tr('Email (для сброса пароля)'),
              prefixIcon: const Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
              text: context.tr('Сохранить'), gradient: true, onPressed: _save),
          const SizedBox(height: 24),

          _Label(context.tr('Язык'), c: c),
          for (final code in supportedLangs)
            _LangOption(
              code: code,
              label: langNames[code]!,
              selected: state.lang == code,
              onTap: () => state.setLang(code),
            ),
          const SizedBox(height: 24),

          _Label(context.tr('Оформление'), c: c),
          Row(
            children: [
              _ThemeOption(
                icon: Icons.light_mode_rounded,
                label: context.tr('Светлая'),
                selected: !state.isDark,
                onTap: () => state.setDark(false),
              ),
              const SizedBox(width: 12),
              _ThemeOption(
                icon: Icons.dark_mode_rounded,
                label: context.tr('Тёмная'),
                selected: state.isDark,
                onTap: () => state.setDark(true),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _Label(context.tr('Уведомления'), c: c),
          _SwitchTile(
            title: context.tr('Push-уведомления'),
            value: state.pushEnabled,
            onChanged: state.setPushEnabled,
          ),
          const SizedBox(height: 8),
          _SwitchTile(
            title: context.tr('Email-рассылка'),
            value: state.emailEnabled,
            onChanged: state.setEmailEnabled,
          ),
          const SizedBox(height: 24),

          _Label(context.tr('О приложении'), c: c),
          _InfoTile(
            icon: Icons.info_outline,
            title: context.tr('Версия'),
            trailing: '1.0.0',
          ),
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.storefront_outlined,
            title: context.tr('JUZUM — маркетплейс'),
            trailing: context.tr('КР'),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final AppPalette c;
  const _Label(this.text, {required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: c.ink,
        ),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.solid.withValues(alpha: 0.10)
                : c.tint,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.solid : c.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                code.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: selected ? AppColors.solid : c.grey,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.solid : c.grey,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.gradient : null,
            color: selected ? null : c.tint,
            borderRadius: BorderRadius.circular(AppColors.rCard),
            border: selected ? null : Border.all(color: c.line),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 26,
                  color: selected ? AppColors.white : AppColors.solid),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.white : c.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: c.tint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.ink,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.solid,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String trailing;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: c.tint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.solid),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.ink,
              ),
            ),
          ),
          Text(
            trailing,
            style: TextStyle(fontSize: 14, color: c.grey),
          ),
        ],
      ),
    );
  }
}
