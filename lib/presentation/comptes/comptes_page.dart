import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/compte.dart';
import '../../features/comptes/comptes_provider.dart';
import '../shared/currency_text.dart';
import 'add_compte_sheet.dart';

class ComptesPage extends ConsumerWidget {
  const ComptesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comptesAsync = ref.watch(comptesProvider);
    final patrimoine = ref.watch(patrimoineTotal);
    final interets = ref.watch(interetsEstimesAnnuels);
    final parCategorie = ref.watch(totalParCategorieProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Comptes & Épargne',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
            centerTitle: true,
            floating: true,
            backgroundColor: cs.surfaceContainerLowest,
          ),

          // Patrimoine total
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _PatrimoineCard(
                patrimoine: patrimoine,
                interets: interets,
                parCategorie: parCategorie,
              ),
            ),
          ),

          // Liste des comptes par catégorie
          comptesAsync.when(
            loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) =>
                SliverFillRemaining(child: Center(child: Text('Erreur : $e'))),
            data: (comptes) {
              if (comptes.isEmpty) {
                return SliverToBoxAdapter(child: _EmptyComptes());
              }
              final grouped = <CategorieCompte, List<Compte>>{};
              for (final c in comptes) {
                grouped.putIfAbsent(c.type.categorie, () => []).add(c);
              }
              return SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),
                  ...CategorieCompte.values
                      .where((cat) => grouped.containsKey(cat))
                      .expand((cat) => [
                            _SectionHeader(
                                title: cat.label,
                                total: grouped[cat]!.fold(
                                    0.0, (s, c) => s + c.solde)),
                            ...grouped[cat]!
                                .map((c) => _CompteTile(compte: c)),
                          ]),
                  const SizedBox(height: 80),
                ]),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => const AddCompteSheet(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter un compte'),
      ),
    );
  }
}

class _PatrimoineCard extends StatelessWidget {
  final double patrimoine;
  final double interets;
  final Map<CategorieCompte, double> parCategorie;

  const _PatrimoineCard({
    required this.patrimoine,
    required this.interets,
    required this.parCategorie,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A56DB).withValues(alpha: 0.3), cs.surfaceContainerHigh]
              : [const Color(0xFF1A56DB).withValues(alpha: 0.1), cs.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF1A56DB).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Patrimoine total',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  )),
          const SizedBox(height: 4),
          CurrencyText(
            patrimoine,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (interets > 0) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.trending_up_rounded,
                  size: 14, color: AppColors.excellent),
              const SizedBox(width: 4),
              Text(
                '≈ ${formatCurrency(interets)} d\'intérêts estimés/an',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.excellent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ]),
          ],
          if (parCategorie.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: parCategorie.entries
                  .where((e) => e.value > 0)
                  .map((e) => _CategorieChip(
                        label: e.key.label,
                        montant: e.value,
                        ratio: patrimoine > 0 ? e.value / patrimoine : 0,
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategorieChip extends StatelessWidget {
  final String label;
  final double montant;
  final double ratio;

  const _CategorieChip({
    required this.label,
    required this.montant,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  )),
          const SizedBox(height: 2),
          Row(children: [
            Text(formatCurrency(montant),
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            Text('${(ratio * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                    )),
          ]),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final double total;
  const _SectionHeader({required this.title, required this.total});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Text(title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  )),
          const Spacer(),
          Text(formatCurrency(total),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  )),
        ],
      ),
    );
  }
}

class _CompteTile extends ConsumerWidget {
  final Compte compte;
  const _CompteTile({required this.compte});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = compte.progressVersPlafond;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: isDark ? cs.surfaceContainerHigh : cs.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showEditSolde(context, ref),
          onLongPress: () => _showOptions(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    // Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _categorieColor(compte.type.categorie)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _categorieIcon(compte.type.categorie),
                        size: 22,
                        color: _categorieColor(compte.type.categorie),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(compte.nom,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Row(children: [
                            Text(compte.type.label,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: cs.onSurface
                                            .withValues(alpha: 0.5))),
                            if (compte.banque != null) ...[
                              Text(' · ',
                                  style: TextStyle(
                                      color: cs.onSurface
                                          .withValues(alpha: 0.3))),
                              Text(compte.banque!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                          color: cs.onSurface
                                              .withValues(alpha: 0.5))),
                            ],
                          ]),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CurrencyText(
                          compte.solde,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (compte.type.tauxAnnuel != null)
                          Text(
                            compte.type.tauxLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: AppColors.excellent,
                                    fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ],
                ),
                // Plafond progress bar
                if (progress != null) ...[
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(progress * 100).toStringAsFixed(1)}% du plafond utilisé',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.5)),
                          ),
                          Text(
                            compte.type.plafondLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.45)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: cs.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress > 0.9
                                ? AppColors.expense
                                : progress > 0.7
                                    ? AppColors.warning
                                    : AppColors.excellent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _categorieColor(CategorieCompte cat) => switch (cat) {
        CategorieCompte.livrets => AppColors.revenue,
        CategorieCompte.epargneLogement => const Color(0xFF8B5CF6),
        CategorieCompte.retraite => AppColors.savings,
        CategorieCompte.investissement => const Color(0xFF06B6D4),
        CategorieCompte.courant => AppColors.balance,
      };

  IconData _categorieIcon(CategorieCompte cat) => switch (cat) {
        CategorieCompte.livrets => Icons.account_balance_rounded,
        CategorieCompte.epargneLogement => Icons.home_rounded,
        CategorieCompte.retraite => Icons.elderly_rounded,
        CategorieCompte.investissement => Icons.show_chart_rounded,
        CategorieCompte.courant => Icons.credit_card_rounded,
      };

  Future<void> _showEditSolde(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(text: compte.solde.toString());
    final result = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Mettre à jour le solde\n${compte.nom}'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
              labelText: 'Nouveau solde (€)',
              border: OutlineInputBorder(),
              suffixText: '€'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () {
                final v = double.tryParse(ctrl.text.replaceAll(',', '.'));
                if (v != null) Navigator.pop(context, v);
              },
              child: const Text('Mettre à jour')),
        ],
      ),
    );
    if (result != null) {
      ref.read(comptesProvider.notifier).mettreAJourSolde(compte.id, result);
    }
  }

  Future<void> _showOptions(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Modifier'),
            onTap: () => Navigator.pop(context, 'edit'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pop(context, 'delete'),
          ),
        ]),
      ),
    );
    if (action == 'edit' && context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => AddCompteSheet(compte: compte),
      );
    } else if (action == 'delete') {
      ref.read(comptesProvider.notifier).supprimer(compte.id);
    }
  }
}

class _EmptyComptes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        children: [
          Icon(Icons.account_balance_rounded,
              size: 56, color: cs.onSurface.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text('Aucun compte enregistré',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: cs.outline)),
          const SizedBox(height: 8),
          Text(
            'Ajoutez vos livrets, PEA, assurance-vie…\npour suivre votre patrimoine.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.outline.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}
