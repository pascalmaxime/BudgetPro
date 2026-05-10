import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'currency_text.dart';

enum BudgetHealth { noData, excellent, bon, attention, critique }

extension BudgetHealthExt on BudgetHealth {
  String get label => switch (this) {
        BudgetHealth.noData => 'Aucune donnée ce mois',
        BudgetHealth.excellent => 'Excellent',
        BudgetHealth.bon => 'Bon',
        BudgetHealth.attention => 'Attention',
        BudgetHealth.critique => 'Budget dépassé',
      };

  Color get color => switch (this) {
        BudgetHealth.noData => const Color(0xFF9CA3AF),
        BudgetHealth.excellent => AppColors.excellent,
        BudgetHealth.bon => AppColors.balance,
        BudgetHealth.attention => AppColors.warning,
        BudgetHealth.critique => AppColors.expense,
      };

  IconData get icon => switch (this) {
        BudgetHealth.noData => Icons.info_outline,
        BudgetHealth.excellent => Icons.star_rounded,
        BudgetHealth.bon => Icons.thumb_up_rounded,
        BudgetHealth.attention => Icons.warning_amber_rounded,
        BudgetHealth.critique => Icons.trending_down_rounded,
      };
}

class BudgetHealthCard extends StatelessWidget {
  final double revenus;
  final double depenses;
  final double epargne;

  const BudgetHealthCard({
    super.key,
    required this.revenus,
    required this.depenses,
    required this.epargne,
  });

  BudgetHealth get _health {
    if (revenus == 0) return BudgetHealth.noData;
    final txDepense = depenses / revenus;
    final txEpargne = epargne / revenus;
    if (txDepense > 1.0) return BudgetHealth.critique;
    if (txEpargne >= 0.2 && txDepense <= 0.75) return BudgetHealth.excellent;
    if (txEpargne >= 0.1 && txDepense <= 0.85) return BudgetHealth.bon;
    return BudgetHealth.attention;
  }

  double get _progress => revenus == 0 ? 0 : (depenses / revenus).clamp(0.0, 1.0);
  double get _txEpargne => revenus == 0 ? 0 : (epargne / revenus * 100).clamp(0.0, 100.0);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final health = _health;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [health.color.withValues(alpha: 0.25), cs.surfaceContainerHigh]
              : [health.color.withValues(alpha: 0.08), cs.surface],
        ),
        border: Border.all(color: health.color.withValues(alpha: 0.3), width: 1.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(health.icon, color: health.color, size: 20),
              const SizedBox(width: 8),
              Text(
                'Santé budgétaire',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: health.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  health.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: health.color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          if (revenus > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revenus du mois',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                      ),
                      const SizedBox(height: 2),
                      CurrencyText(
                        revenus,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
                if (_txEpargne > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Taux d\'épargne',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_txEpargne.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.excellent,
                            ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dépenses',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                    ),
                    Text(
                      '${(_progress * 100).toStringAsFixed(0)}% des revenus',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: health.color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 8,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(health.color),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              'Ajoutez vos revenus du mois pour voir votre bilan budgétaire.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
