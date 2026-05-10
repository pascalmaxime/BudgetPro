import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/transaction.dart';
import '../../features/budget/budget_provider.dart';
import '../shared/budget_card.dart';
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Dashboard'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: const MoisSelector(),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              childAspectRatio: 1.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                BudgetCard(
                  label: 'Revenus',
                  montant: resume.totalRevenus,
                  icon: Icons.trending_up,
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                BudgetCard(
                  label: 'Dépenses',
                  montant: resume.totalDepenses,
                  icon: Icons.trending_down,
                  color: Theme.of(context).colorScheme.errorContainer,
                ),
                BudgetCard(
                  label: 'Épargne',
                  montant: resume.totalEpargne,
                  icon: Icons.savings,
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                ),
                BudgetCard(
                  label: 'Solde restant',
                  montant: resume.solde,
                  icon: Icons.account_balance_wallet,
                  showSign: true,
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Transactions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      _AddButton(type: TransactionType.revenu, label: 'Revenu', icon: Icons.add_circle_outline),
                      const SizedBox(width: 8),
                      _AddButton(type: TransactionType.depenseVariable, label: 'Dépense', icon: Icons.remove_circle_outline),
                      const SizedBox(width: 8),
                      _AddButton(type: TransactionType.epargne, label: 'Épargne', icon: Icons.savings_outlined),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 8)),
          transAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Erreur : $e'))),
            data: (transactions) => transactions.isEmpty
                ? const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Aucune transaction ce mois-ci', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                : SliverList.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, i) => _TransactionTile(transaction: transactions[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final TransactionType type;
  final String label;
  final IconData icon;

  const _AddButton({required this.type, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ajouter $label',
      child: IconButton.filledTonal(
        icon: Icon(icon, size: 20),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => AddTransactionSheet(type: type),
        ),
      ),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  final Transaction transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isRevenu = transaction.type == TransactionType.revenu;
    final isEpargne = transaction.type == TransactionType.epargne;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isRevenu
            ? cs.primaryContainer
            : isEpargne
                ? cs.tertiaryContainer
                : cs.errorContainer,
        child: Icon(
          isRevenu
              ? Icons.trending_up
              : isEpargne
                  ? Icons.savings
                  : Icons.shopping_bag_outlined,
          size: 20,
          color: isRevenu
              ? cs.onPrimaryContainer
              : isEpargne
                  ? cs.onTertiaryContainer
                  : cs.onErrorContainer,
        ),
      ),
      title: Text(transaction.description),
      subtitle: Text(
          '${transaction.categorie.label} · ${DateFormat('dd/MM').format(transaction.date)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CurrencyText(
            transaction.montant,
            showSign: isRevenu,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Supprimer ?'),
                  content: Text('Supprimer "${transaction.description}" ?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(transactionsMoisProvider(transaction.mois).notifier).supprimer(transaction.id);
              }
            },
          ),
        ],
      ),
    );
  }
}
