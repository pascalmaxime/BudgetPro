import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/profile/profile_provider.dart';
import '../../features/theme/theme_provider.dart';
import 'profile_setup_sheet.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(title: Text('Paramètres')),
          SliverList(
            delegate: SliverChildListDelegate([
              const _SectionTitle(title: 'Profil financier'),
              profileAsync.when(
                loading: () => const ListTile(title: Text('Chargement...')),
                error: (e, _) => ListTile(title: Text('Erreur : $e')),
                data: (profile) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: profile != null
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      profile != null ? Icons.person : Icons.person_outline,
                      color: profile != null
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  title: Text(profile != null
                      ? profile.typeContrat.label
                      : 'Profil non configuré'),
                  subtitle: profile != null
                      ? Text(
                          '${profile.situationLogement.label} · Épargne : ${profile.objectifEpargne.toStringAsFixed(0)} €/mois')
                      : const Text('Configurez votre profil pour une analyse personnalisée'),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const ProfileSetupSheet(),
                  ),
                ),
              ),
              const Divider(),
              const _SectionTitle(title: 'Apparence'),
              RadioGroup<ThemeMode>(
                groupValue: themeMode,
                onChanged: (v) => ref.read(themeProvider.notifier).set(v!),
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(title: const Text('Thème système'), value: ThemeMode.system),
                    RadioListTile<ThemeMode>(title: const Text('Clair'), value: ThemeMode.light),
                    RadioListTile<ThemeMode>(title: const Text('Sombre'), value: ThemeMode.dark),
                  ],
                ),
              ),
              const Divider(),
              const _SectionTitle(title: 'À propos'),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('BudgetPro'),
                subtitle: Text('Version 1.0.0 · Données 100% locales'),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

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
