import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/transaction.dart';
import '../../features/budget/budget_provider.dart';
import '../shared/budget_card.dart';
import '../shared/budget_health_card.dart';
import '../shared/currency_text.dart';
import '../shared/mois_selector.dart';
import 'add_transaction_sheet.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mois = ref.watch(moisSelectionneProvider);
    final resume = ref.watch(resumeMoisProvider(mois));
    final transAsync = ref.watch(transactionsMoisProvider(mois));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Dashboard',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
            centerTitle: true,
            floating: true,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(40),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: const MoisSelector(),
              ),
            ),
          ),

          // Health card
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: BudgetHealthCard(
                revenus: resume.totalRevenus,
                depenses: resume.totalDepenses,
                epargne: resume.totalEpargne,
              ),
            ),
          ),

          // Metrics grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                mainAxisExtent: 96,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildListDelegate([
                BudgetCard(
                  label: 'Revenus',
                  montant: resume.totalRevenus,
                  icon: Icons.trending_up_rounded,
                  accentColor: AppColors.revenue,
                  subtitle: 'Ce mois-ci',
                ),
                BudgetCard(
                  label: 'Dépenses',
                  montant: resume.totalDepenses,
                  icon: Icons.trending_down_rounded,
                  accentColor: AppColors.expense,
                  subtitle: 'Fixes + variables',
                ),
                BudgetCard(
                  label: 'Épargne',
                  montant: resume.totalEpargne,
                  icon: Icons.savings_rounded,
                  accentColor: AppColors.savings,
                  subtitle: 'Mise de côté',
                ),
                BudgetCard(
                  label: 'Solde restant',
                  montant: resume.solde,
                  icon: Icons.account_balance_wallet_rounded,
                  accentColor: AppColors.balance,
                  showSign: true,
                ),
              ]),
            ),
          ),

          // Transactions header
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text('Transactions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                  const Spacer(),
                  _QuickAddButton(
                    label: 'Revenu',
                    icon: Icons.add_rounded,
                    color: AppColors.revenue,
                    type: TransactionType.revenu,
                  ),
                  const SizedBox(width: 8),
                  _QuickAddButton(
                    label: 'Dépense',
                    icon: Icons.remove_rounded,
                    color: AppColors.expense,
                    type: TransactionType.depenseVariable,
                  ),
                  const SizedBox(width: 8),
                  _QuickAddButton(
                    label: 'Épargne',
                    icon: Icons.savings_outlined,
                    color: AppColors.savings,
                    type: TransactionType.epargne,
                  ),
                ],
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(top: 10)),

          // Transaction list
          transAsync.when(
            loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) =>
                SliverFillRemaining(child: Center(child: Text('Erreur : $e'))),
            data: (transactions) => transactions.isEmpty
                ? SliverToBoxAdapter(child: _EmptyTransactions())
                : SliverList.builder(
                    itemCount: transactions.length + 1,
                    itemBuilder: (context, i) {
                      if (i == transactions.length) {
                        return const SizedBox(height: 24);
                      }
                      return _TransactionTile(transaction: transactions[i]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final TransactionType type;

  const _QuickAddButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ajouter $label',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => AddTransactionSheet(type: type),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: cs.outline.withValues(alpha: 0.4)),
          const SizedBox(height: 10),
          Text('Aucune transaction ce mois-ci',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.outline)),
          const SizedBox(height: 4),
          Text('Ajoutez vos revenus et dépenses ci-dessus',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.outline.withValues(alpha: 0.6),
                  )),
        ],
      ),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  final Transaction transaction;
  const _TransactionTile({required this.transaction});

  Color _typeColor(TransactionType type) => switch (type) {
        TransactionType.revenu => AppColors.revenue,
        TransactionType.epargne => AppColors.savings,
        TransactionType.depenseFixe => AppColors.expense,
        TransactionType.depenseVariable => AppColors.expense,
      };

  IconData _typeIcon(TransactionType type) => switch (type) {
        TransactionType.revenu => Icons.arrow_downward_rounded,
        TransactionType.epargne => Icons.savings_rounded,
        TransactionType.depenseFixe => Icons.repeat_rounded,
        TransactionType.depenseVariable => Icons.arrow_upward_rounded,
      };

  void _openEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddTransactionSheet(
        type: transaction.type,
        transaction: transaction,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _typeColor(transaction.type);
    final isRevenu = transaction.type == TransactionType.revenu ||
        transaction.type == TransactionType.epargne;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: isDark ? cs.surfaceContainerHigh : cs.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openEdit(context),
          onLongPress: () => _showOptions(context, ref),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              children: [
                // Icône type
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_typeIcon(transaction.type), size: 20, color: color),
                ),
                const SizedBox(width: 12),

                // Description + catégorie · date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${transaction.categorie.label} · ${DateFormat('dd MMM', 'fr_FR').format(transaction.date)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                      ),
                    ],
                  ),
                ),

                // Montant
                const SizedBox(width: 8),
                Text(
                  '${isRevenu ? '+' : '-'}${formatCurrency(transaction.montant)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isRevenu ? AppColors.revenue : AppColors.expense,
                      ),
                ),

                // Bouton modifier
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      size: 18, color: cs.onSurface.withValues(alpha: 0.35)),
                  tooltip: 'Modifier',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _openEdit(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showOptions(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Modifier'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Supprimer',
                  style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'edit') {
      _openEdit(context);
    } else if (action == 'delete') {
      ref
          .read(transactionsMoisProvider(transaction.mois).notifier)
          .supprimer(transaction.id);
    }
  }
}
