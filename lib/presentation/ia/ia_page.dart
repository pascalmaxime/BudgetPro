import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/ia/ia_provider.dart';
import '../../features/profile/profile_provider.dart';

class IaPage extends ConsumerStatefulWidget {
  const IaPage({super.key});

  @override
  ConsumerState<IaPage> createState() => _IaPageState();
}

class _IaPageState extends ConsumerState<IaPage> {
  final _questionCtrl = TextEditingController();

  @override
  void dispose() {
    _questionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(iaLoadingProvider);
    final response = ref.watch(iaResponseProvider);
    final error = ref.watch(iaErrorProvider);
    final profile = ref.watch(profileProvider).value;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('Conseiller IA'),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: cs.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.psychology_outlined, size: 32, color: cs.onPrimaryContainer),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Analyse budgétaire personnalisée',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: cs.onPrimaryContainer)),
                                Text(
                                  profile == null
                                      ? 'Configurez votre profil dans Paramètres pour commencer'
                                      : 'Powered by Claude Haiku — données 100% locales',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: cs.onPrimaryContainer.withValues(alpha: 0.8)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _questionCtrl,
                    decoration: InputDecoration(
                      hintText: 'Posez une question (optionnel)...',
                      helperText: 'Ex: Comment réduire mes dépenses variables ?',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _questionCtrl.clear,
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: loading || profile == null
                        ? null
                        : () {
                            final q = _questionCtrl.text.trim();
                            ref.read(iaActionsProvider).analyser(q.isEmpty ? null : q);
                          },
                    icon: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(loading ? 'Analyse en cours...' : 'Analyser mon budget'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: cs.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: cs.onErrorContainer),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(error,
                                    style: TextStyle(color: cs.onErrorContainer))),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (response != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb_outline, color: cs.primary),
                                const SizedBox(width: 8),
                                Text('Recommandations',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 20),
                            SelectableText(response,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (response == null && !loading && error == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          Icon(Icons.psychology_outlined, size: 80, color: cs.outlineVariant),
                          const SizedBox(height: 16),
                          Text('Votre conseiller IA personnel',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: cs.outline)),
                          const SizedBox(height: 8),
                          Text(
                            'Analyse vos dépenses et vous propose\ndes recommandations personnalisées',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.outline),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
