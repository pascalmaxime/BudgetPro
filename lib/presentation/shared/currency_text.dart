import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _fmt = NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 2);

String formatCurrency(double amount) => _fmt.format(amount);

class CurrencyText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final bool showSign;

  const CurrencyText(this.amount, {super.key, this.style, this.showSign = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color? color;
    if (showSign) {
      color = amount >= 0 ? cs.primary : cs.error;
    }
    final text = showSign && amount > 0 ? '+${formatCurrency(amount)}' : formatCurrency(amount);
    return Text(text, style: style?.copyWith(color: color) ?? TextStyle(color: color));
  }
}
