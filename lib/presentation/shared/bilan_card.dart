import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'currency_text.dart';

/// Statut budgétaire du mois
enum BilanStatus { noData, excellent, bon, attention, critique }

extension BilanStatusExt on BilanStatus {
  String get label => switch (this) {
        BilanStatus.noData => 'Aucune donnée',
        BilanStatus.excellent => 'Excellent',
        BilanStatus.bon => 'Bon',
        BilanStatus.attention => 'Attention',
        BilanStatus.critique => 'Dépassé',
      };

  Color get color => switch (this) {
        BilanStatus.noData => const Color(0xFF9CA3AF),
        BilanStatus.excellent => AppColors.excellent,
        BilanStatus.bon => AppColors.balance,
        BilanStatus.attention => AppColors.warning,
        BilanStatus.critique => AppColors.expense,
      };
}

/// Carte bilan mensuel style P&L comptable
class BilanCard extends StatelessWidget {
  final double revenus;
  final double depensesFixes;
  final double depensesVariables;
  final double epargne;

  /// Objectif d'épargne issu du profil (optionnel)
  final double? objectifEpargne;

  /// Taux recommandé selon statut (optionnel)
  final double? tauxRecommande;

  const BilanCard({
    super.key,
    required this.revenus,
    required this.depensesFixes,
    required this.depensesVariables,
    required this.epargne,
    this.objectifEpargne,
    this.tauxRecommande,
  });

  double get _totalDepenses => depensesFixes + depensesVariables;
  double get _soldeLivre => revenus - _totalDepenses - epargne;
  double get _txEpargne => revenus > 0 ? epargne / revenus : 0;
  double get _txDepenses => revenus > 0 ? _totalDepenses / revenus : 0;

  BilanStatus get _status {
    if (revenus == 0) return BilanStatus.noData;
    if (_txDepenses > 1.0) return BilanStatus.critique;
    if (_txEpargne >= 0.20 && _txDepenses <= 0.75) return BilanStatus.excellent;
    if (_txEpargne >= 0.10 && _txDepenses <= 0.85) return BilanStatus.bon;
    return BilanStatus.attention;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = _status;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? cs.surfaceContainerHigh : cs.surface,
        border: Border.all(
          color: status == BilanStatus.noData
              ? cs.outlineVariant
              : status.color.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          // ── En-tête ────────────────────────────────────────────────────
          _buildHeader(context, cs, status),

          if (revenus > 0) ...[
            const Divider(height: 1),
            _buildPLBody(context, cs),
            const Divider(height: 1),
            _buildFooter(context, cs, status),
          ] else ...[
            _buildEmptyState(context, cs),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs, BilanStatus status) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: status == BilanStatus.noData
                  ? cs.surfaceContainerHighest
                  : status.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 18,
              color: status == BilanStatus.noData ? cs.outline : status.color,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bilan du mois',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                'Comptes de résultat',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
              ),
            ],
          ),
          const Spacer(),
          // Badge statut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: status.color.withValues(alpha: 0.3)),
            ),
            child: Text(
              status.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: status.color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPLBody(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          // Revenus
          _PLRow(
            context: context,
            cs: cs,
            icon: Icons.arrow_downward_rounded,
            label: 'Revenus',
            montant: revenus,
            color: AppColors.revenue,
            signe: '+',
            isTotal: false,
          ),
          Divider(height: 1, indent: 16, endIndent: 16, color: cs.outlineVariant.withValues(alpha: 0.4)),

          // Charges fixes
          _PLRow(
            context: context,
            cs: cs,
            icon: Icons.lock_outline_rounded,
            label: 'Charges fixes',
            montant: depensesFixes,
            color: AppColors.warning,
            signe: '−',
            isTotal: false,
          ),

          // Dépenses variables
          _PLRow(
            context: context,
            cs: cs,
            icon: Icons.receipt_long_outlined,
            label: 'Dépenses variables',
            montant: depensesVariables,
            color: AppColors.expense,
            signe: '−',
            isTotal: false,
          ),

          // Épargne
          _PLRow(
            context: context,
            cs: cs,
            icon: Icons.savings_rounded,
            label: 'Épargne',
            montant: epargne,
            color: AppColors.savings,
            signe: '−',
            isTotal: false,
          ),

          Divider(height: 1, indent: 16, endIndent: 16, color: cs.outlineVariant),

          // Solde libre
          _PLRow(
            context: context,
            cs: cs,
            icon: _soldeLivre >= 0
                ? Icons.check_circle_outline_rounded
                : Icons.warning_amber_rounded,
            label: 'Solde libre',
            montant: _soldeLivre.abs(),
            color: _soldeLivre >= 0 ? AppColors.excellent : AppColors.expense,
            signe: _soldeLivre >= 0 ? '+' : '−',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ColorScheme cs, BilanStatus status) {
    final pct = (_txEpargne * 100).clamp(0.0, 100.0);
    final objPct = objectifEpargne != null && objectifEpargne! > 0 && revenus > 0
        ? (objectifEpargne! / revenus * 100).clamp(0.0, 100.0)
        : tauxRecommande;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Taux d\'épargne : ',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
              ),
              Text(
                '${pct.toStringAsFixed(1)} %',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _txEpargne >= 0.20
                          ? AppColors.excellent
                          : _txEpargne >= 0.10
                              ? AppColors.warning
                              : AppColors.expense,
                    ),
              ),
              if (objPct != null) ...[
                Text(
                  '  ·  Objectif : ${objPct.toStringAsFixed(0)} %',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                ),
              ],
              const Spacer(),
              Text(
                '${(_txDepenses * 100).toStringAsFixed(0)} % en dépenses',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: status.color.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Barre de progression composée : fixes + variables + épargne
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 7,
              child: Row(
                children: [
                  if (depensesFixes > 0 && revenus > 0)
                    Expanded(
                      flex: (depensesFixes / revenus * 1000).round(),
                      child: Container(color: AppColors.warning),
                    ),
                  if (depensesVariables > 0 && revenus > 0)
                    Expanded(
                      flex: (depensesVariables / revenus * 1000).round(),
                      child: Container(color: AppColors.expense),
                    ),
                  if (epargne > 0 && revenus > 0)
                    Expanded(
                      flex: (epargne / revenus * 1000).round(),
                      child: Container(color: AppColors.savings),
                    ),
                  Expanded(
                    flex: ((_soldeLivre.clamp(0, double.infinity)) / revenus * 1000).round().clamp(1, 9999),
                    child: Container(
                        color: cs.surfaceContainerHighest),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Légende
          Row(
            children: [
              _Legend(color: AppColors.warning, label: 'Fixes'),
              const SizedBox(width: 10),
              _Legend(color: AppColors.expense, label: 'Variables'),
              const SizedBox(width: 10),
              _Legend(color: AppColors.savings, label: 'Épargne'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Text(
        'Ajoutez un revenu ce mois-ci pour voir votre bilan.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
      ),
    );
  }
}

// ── Ligne P&L ─────────────────────────────────────────────────────────────────

class _PLRow extends StatelessWidget {
  final BuildContext context;
  final ColorScheme cs;
  final IconData icon;
  final String label;
  final double montant;
  final Color color;
  final String signe;
  final bool isTotal;

  const _PLRow({
    required this.context,
    required this.cs,
    required this.icon,
    required this.label,
    required this.montant,
    required this.color,
    required this.signe,
    required this.isTotal,
  });

  @override
  Widget build(BuildContext ctx) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, isTotal ? 10 : 7, 16, isTotal ? 10 : 7),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isTotal
                        ? cs.onSurface
                        : cs.onSurface.withValues(alpha: 0.75),
                    fontWeight:
                        isTotal ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ),
          Text(
            '$signe ${formatCurrency(montant)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight:
                      isTotal ? FontWeight.w800 : FontWeight.w600,
                  fontSize: isTotal ? 14 : null,
                ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
        ),
      ],
    );
  }
}
