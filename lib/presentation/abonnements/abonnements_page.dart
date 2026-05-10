import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/abonnement.dart';
import '../../features/abonnements/abonnements_provider.dart';
import '../shared/currency_text.dart';
import 'add_abonnement_sheet.dart';

class AbonnementsPage extends ConsumerWidget {
  const AbonnementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abosAsync = ref.watch(abonnementsProvider);
    final coutMensuel = ref.watch(coutMensuelAbonnementsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Abonnements'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Chip(
                  avatar: const Icon(Icons.euro, size: 16),
                  label: Text('${formatCurrency(coutMensuel)}/mois'),
                ),
              ),
            ],
          ),
          abosAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Erreur : $e'))),
            data: (abos) {
              if (abos.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.subscriptions_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Aucun abonnement', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              final actifs = abos.where((a) => a.actif).toList();
              final inactifs = abos.where((a) => !a.actif).toList();
              return SliverList(
                delegate: SliverChildListDelegate([
                  if (actifs.isNotEmpty) ...[
                    const _SectionHeader(title: 'Actifs'),
                    ...actifs.map((a) => _AbonnementTile(abonnement: a)),
                  ],
                  if (inactifs.isNotEmpty) ...[
                    const _SectionHeader(title: 'Inactifs'),
                    ...inactifs.map((a) => _AbonnementTile(abonnement: a)),
                  ],
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
          builder: (_) => const AddAbonnementSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: Theme.of(context).colorScheme.primary)),
    );
  }
}

class _AbonnementTile extends ConsumerWidget {
  final Abonnement abonnement;
  const _AbonnementTile({required this.abonnement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final jours = abonnement.joursAvantRenouvellement;
    final urgence = jours <= 3;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: abonnement.actif ? cs.primaryContainer : cs.surfaceContainerHighest,
        child: Icon(_categorieIcon(abonnement.categorie),
            size: 20,
            color: abonnement.actif ? cs.onPrimaryContainer : cs.onSurfaceVariant),
      ),
      title: Text(abonnement.nom,
          style: TextStyle(
              color: abonnement.actif ? null : cs.onSurface.withValues(alpha: 0.5))),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(abonnement.categorie.label),
          if (abonnement.actif)
            Text(
              'Renouvellement dans $jours j — ${DateFormat('dd/MM/yyyy').format(abonnement.prochainRenouvellement)}',
              style: TextStyle(
                color: urgence ? cs.error : cs.onSurfaceVariant,
                fontWeight: urgence ? FontWeight.bold : null,
                fontSize: 12,
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CurrencyText(abonnement.montantMensuel,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('/mois',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
          PopupMenuButton<String>(
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Modifier')),
              PopupMenuItem(
                value: 'toggle',
                child: Text(abonnement.actif ? 'Désactiver' : 'Activer'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            ],
            onSelected: (action) async {
              switch (action) {
                case 'edit':
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => AddAbonnementSheet(abonnement: abonnement),
                  );
                case 'toggle':
                  ref.read(abonnementsProvider.notifier).toggleActif(abonnement.id);
                case 'delete':
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Supprimer ?'),
                      content: Text('Supprimer "${abonnement.nom}" ?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    ref.read(abonnementsProvider.notifier).supprimer(abonnement.id);
                  }
              }
            },
          ),
        ],
      ),
    );
  }

  IconData _categorieIcon(CategorieAbonnement cat) => switch (cat) {
        CategorieAbonnement.streaming => Icons.tv_outlined,
        CategorieAbonnement.musique => Icons.music_note_outlined,
        CategorieAbonnement.sport => Icons.fitness_center_outlined,
        CategorieAbonnement.logiciels => Icons.computer_outlined,
        CategorieAbonnement.presse => Icons.newspaper_outlined,
        CategorieAbonnement.autre => Icons.subscriptions_outlined,
      };
}
