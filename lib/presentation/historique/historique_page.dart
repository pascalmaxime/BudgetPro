import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/transaction.dart';
import '../../features/budget/budget_provider.dart';
import '../shared/currency_text.dart';

class HistoriquePage extends ConsumerWidget {
  const HistoriquePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moisAsync = ref.watch(moisDisponiblesProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(title: Text('Historique')),
          moisAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Erreur : $e'))),
            data: (moisList) {
              if (moisList.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Aucun historique disponible', style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 8),
                        Text('Ajoutez des transactions sur le Dashboard', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }
              return SliverList.builder(
                itemCount: moisList.length,
                itemBuilder: (context, i) => _MoisCard(mois: moisList[i]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MoisCard extends ConsumerWidget {
  final String mois;
  const _MoisCard({required this.mois});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resume = ref.watch(resumeMoisProvider(mois));
    final date = DateFormat('yyyy-MM').parse(mois);
    final label = DateFormat('MMMM yyyy', 'fr_FR').format(date);
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ExpansionTile(
        title: Text(
          label[0].toUpperCase() + label.substring(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.trending_up, size: 14, color: cs.primary),
            const SizedBox(width: 4),
            Text(formatCurrency(resume.totalRevenus), style: TextStyle(color: cs.primary, fontSize: 12)),
            const SizedBox(width: 12),
            Icon(Icons.trending_down, size: 14, color: cs.error),
            const SizedBox(width: 4),
            Text(formatCurrency(resume.totalDepenses), style: TextStyle(color: cs.error, fontSize: 12)),
            const SizedBox(width: 12),
            Icon(Icons.account_balance_wallet, size: 14, color: cs.tertiary),
            const SizedBox(width: 4),
            CurrencyText(resume.solde, showSign: true, style: const TextStyle(fontSize: 12)),
          ],
        ),
        children: [_MoisDetail(mois: mois)],
      ),
    );
  }
}

class _MoisDetail extends ConsumerWidget {
  final String mois;
  const _MoisDetail({required this.mois});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transAsync = ref.watch(transactionsMoisProvider(mois));
    return transAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
      error: (e, _) => Text('Erreur : $e'),
      data: (transactions) {
        final grouped = <TransactionType, List<Transaction>>{};
        for (final t in transactions) {
          grouped.putIfAbsent(t.type, () => []).add(t);
        }
        return Column(
          children: TransactionType.values
              .where((type) => grouped.containsKey(type))
              .map((type) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text(type.label,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary)),
                      ),
                      ...grouped[type]!.map((t) => ListTile(
                            dense: true,
                            title: Text(t.description, style: const TextStyle(fontSize: 13)),
                            subtitle: Text(t.categorie.label, style: const TextStyle(fontSize: 11)),
                            trailing: CurrencyText(t.montant, style: const TextStyle(fontSize: 13)),
                          )),
                    ],
                  ))
              .toList(),
        );
      },
    );
  }
}
