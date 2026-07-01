import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../l10n/l10n.dart';
import '../models/order.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _city;
  late final TextEditingController _address;
  late final TextEditingController _comment;

  // Карта
  final _card = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  final _holder = TextEditingController();

  PaymentMethod _payment = PaymentMethod.online;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    final last = state.lastDelivery;
    _name = TextEditingController(text: last?.name ?? state.userName);
    _phone = TextEditingController(text: last?.phone ?? state.userPhone);
    _city = TextEditingController(text: last?.city ?? '');
    _address = TextEditingController(text: last?.address ?? '');
    _comment = TextEditingController(text: last?.comment ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _phone,
      _city,
      _address,
      _comment,
      _card,
      _expiry,
      _cvv,
      _holder,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      // Прокрутим к первой ошибке визуально — простой фидбэк.
      return;
    }

    final state = context.read<AppState>();
    final delivery = DeliveryInfo(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      city: _city.text.trim(),
      address: _address.text.trim(),
      comment: _comment.text.trim(),
    );

    // Отправка заказа на сервер (для онлайн-оплаты это и есть «обработка»).
    setState(() => _processing = true);
    try {
      final order =
          await state.placeOrder(delivery: delivery, payment: _payment);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Не удалось оформить заказ. Проверьте связь и повторите.')),
          backgroundColor: const Color(0xFFE5484D),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = context.watch<AppState>();
    final itemsTotal = state.cartTotal;
    final fee = state.currentDeliveryFee;
    final total = itemsTotal + fee;
    final online = _payment == PaymentMethod.online;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Оформление заказа'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- Доставка ---
            _Section(context.tr('Данные доставки')),
            _field(_name, context.tr('Имя получателя'), icon: Icons.person_outline),
            _field(
              _phone,
              context.tr('Телефон'),
              icon: Icons.phone_outlined,
              keyboard: TextInputType.phone,
              validator: (v) => (v == null || v.trim().length < 5)
                  ? context.tr('Введите корректный номер')
                  : null,
            ),
            _field(_city, context.tr('Город'), icon: Icons.location_city_outlined),
            _field(_address, context.tr('Адрес (улица, дом, кв.)'),
                icon: Icons.home_outlined),
            _field(
              _comment,
              context.tr('Комментарий к заказу (необязательно)'),
              icon: Icons.notes_outlined,
              required: false,
            ),
            const SizedBox(height: 8),

            // --- Оплата ---
            _Section(context.tr('Способ оплаты')),
            _PaymentTile(
              method: PaymentMethod.online,
              selected: online,
              icon: Icons.credit_card_rounded,
              onTap: () => setState(() => _payment = PaymentMethod.online),
            ),
            const SizedBox(height: 8),
            _PaymentTile(
              method: PaymentMethod.cash,
              selected: !online,
              icon: Icons.payments_outlined,
              onTap: () => setState(() => _payment = PaymentMethod.cash),
            ),

            // --- Карта (только для онлайн-оплаты) ---
            if (online) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.tint,
                  borderRadius: BorderRadius.circular(AppColors.rCard),
                  border: Border.all(color: c.line),
                ),
                child: Column(
                  children: [
                    _field(
                      _card,
                      context.tr('Номер карты'),
                      icon: Icons.credit_card,
                      keyboard: TextInputType.number,
                      formatters: [_CardNumberFormatter()],
                      validator: (v) {
                        final digits =
                            (v ?? '').replaceAll(RegExp(r'\D'), '');
                        return digits.length < 16 ? context.tr('Введите 16 цифр') : null;
                      },
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _field(
                            _expiry,
                            context.tr('ММ/ГГ'),
                            keyboard: TextInputType.number,
                            formatters: [_ExpiryFormatter()],
                            validator: (v) => (v ?? '').length < 5
                                ? context.tr('ММ/ГГ')
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            _cvv,
                            'CVV',
                            keyboard: TextInputType.number,
                            obscure: true,
                            formatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            validator: (v) =>
                                (v ?? '').length < 3 ? 'CVV' : null,
                          ),
                        ),
                      ],
                    ),
                    _field(
                      _holder,
                      context.tr('Имя на карте'),
                      icon: Icons.badge_outlined,
                    ),
                    Row(
                      children: [
                        Icon(Icons.lock_outline,
                            size: 14, color: c.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            context.tr('Данные карты защищены. Это демо-оплата.'),
                            style: TextStyle(
                              fontSize: 11,
                              color: c.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // --- Итоги ---
            _Section(context.tr('Ваш заказ')),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.tint,
                borderRadius: BorderRadius.circular(AppColors.rCard),
              ),
              child: Column(
                children: [
                  _summaryRow(c, context.trp('Товары ({n} шт.)', {'n': '${state.cartCount}'}),
                      '${itemsTotal.toInt()} ${context.tr('сом')}'),
                  const SizedBox(height: 8),
                  _summaryRow(
                    c,
                    context.tr('Доставка'),
                    fee == 0 ? context.tr('Бесплатно') : '${fee.toInt()} ${context.tr('сом')}',
                    highlight: fee == 0,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: c.line, height: 1),
                  ),
                  _summaryRow(c, context.tr('Итого'), '${total.toInt()} ${context.tr('сом')}', bold: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: online
                  ? context.trp('Оплатить {sum} сом', {'sum': '${total.toInt()}'})
                  : context.tr('Подтвердить заказ'),
              gradient: true,
              loading: _processing,
              icon: online ? Icons.lock_rounded : Icons.check_rounded,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    IconData? icon,
    TextInputType? keyboard,
    bool obscure = false,
    bool required = true,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        obscureText: obscure,
        inputFormatters: formatters,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon) : null,
        ),
        validator: validator ??
            (required
                ? (v) =>
                    (v == null || v.trim().isEmpty) ? context.tr('Заполните поле') : null
                : null),
      ),
    );
  }

  Widget _summaryRow(AppPalette c, String label, String value,
      {bool bold = false, bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 17 : 14,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            color: bold ? c.ink : c.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 18 : 14,
            fontWeight: FontWeight.w800,
            color: highlight
                ? Colors.green
                : (bold ? AppColors.solid : c.ink),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: c.ink,
          ),
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _PaymentTile({
    required this.method,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? c.tint : c.card,
          borderRadius: BorderRadius.circular(AppColors.rCard),
          border: Border.all(
            color: selected ? AppColors.solid : c.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.solid, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                context.tr(method.label),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.solid : c.grey,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/// Форматирует номер карты группами по 4 цифры (макс. 16).
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 16 ? digits.substring(0, 16) : digits;
    final buf = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i != 0 && i % 4 == 0) buf.write(' ');
      buf.write(limited[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Форматирует срок действия как ММ/ГГ.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 4 ? digits.substring(0, 4) : digits;
    String text = limited;
    if (limited.length >= 3) {
      text = '${limited.substring(0, 2)}/${limited.substring(2)}';
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
