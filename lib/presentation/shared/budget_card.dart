import 'package:flutter/material.dart';
import 'currency_text.dart';

class BudgetCard extends StatelessWidget {
  final String label;
  final double montant;
  final IconData icon;
  final Color? color;
  final bool showSign;

  const BudgetCard({
    super.key,
    required this.label,
    required this.montant,
    required this.icon,
    this.color,
    this.showSign = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardColor = color ?? cs.primaryContainer;

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: cs.onSurface.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: cs.onSurface.withValues(alpha: 0.7))),
              ],
            ),
            const SizedBox(height: 8),
            CurrencyText(
              montant,
              showSign: showSign,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
