import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../features/budget/budget_provider.dart';
import '../../features/ia/ia_provider.dart';
import '../../features/profile/profile_provider.dart';

const _suggestions = [
  'Comment réduire mes dépenses variables ?',
  'Est-ce que mon taux d\'épargne est suffisant ?',
  'Quels abonnements pourrais-je résilier ?',
  'Comment mieux gérer mon budget alimentation ?',
];

class IaPage extends ConsumerStatefulWidget {
  const IaPage({super.key});

  @override
  ConsumerState<IaPage> createState() => _IaPageState();
}

class _IaPageState extends ConsumerState<IaPage> {
  final _questionCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _questionCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _analyser([String? question]) {
    final q = question ?? _questionCtrl.text.trim();
    if (question != null) _questionCtrl.text = question;
    ref.read(iaActionsProvider).analyser(q.isEmpty ? null : q);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(iaLoadingProvider);
    final response = ref.watch(iaResponseProvider);
    final error = ref.watch(iaErrorProvider);
    final profile = ref.watch(profileProvider).value;
    final mois = ref.watch(moisSelectionneProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          const SliverAppBar(
            title: Text('Conseiller IA',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
            centerTitle: true,
            floating: true,
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header card
                  _HeaderCard(profile: profile, mois: mois),
                  const SizedBox(height: 16),

                  // Input
                  _InputCard(
                    controller: _questionCtrl,
                    loading: loading,
                    enabled: profile != null,
                    onSubmit: _analyser,
                  ),
                  const SizedBox(height: 12),

                  // Quick suggestions
                  if (response == null && !loading)
                    _SuggestionsRow(onTap: _analyser),

                  // Error
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    _ErrorCard(error: error),
                  ],

                  // Loading
                  if (loading) ...[
                    const SizedBox(height: 24),
                    _LoadingCard(),
                  ],

                  // Response
                  if (response != null) ...[
                    const SizedBox(height: 16),
                    _ResponseCard(response: response, isDark: isDark),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.read(iaResponseProvider.notifier).state = null;
                        ref.read(iaErrorProvider.notifier).state = null;
                        _questionCtrl.clear();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Nouvelle analyse'),
                    ),
                  ],

                  // Empty state
                  if (response == null && !loading && error == null)
                    const _EmptyState(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final dynamic profile;
  final String mois;

  const _HeaderCard({required this.profile, required this.mois});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A56DB).withValues(alpha: 0.15),
            const Color(0xFF0D9488).withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF1A56DB).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1A56DB).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.psychology_rounded,
                color: Color(0xFF1A56DB), size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Votre conseiller budgétaire',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                Text(
                  profile == null
                      ? 'Configurez votre profil dans Paramètres'
                      : 'Analyse personnalisée · Claude Haiku',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                ),
              ],
            ),
          ),
          if (profile != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.excellent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                    decoration: const BoxDecoration(
                        color: AppColors.excellent, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text('Prêt',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.excellent,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final bool enabled;
  final void Function([String?]) onSubmit;

  const _InputCard({
    required this.controller,
    required this.loading,
    required this.enabled,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled && !loading,
            maxLines: 3,
            minLines: 1,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              hintText: enabled
                  ? 'Posez une question à votre conseiller...'
                  : 'Configurez votre profil d\'abord',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              fillColor: cs.surfaceContainerHigh,
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: controller.clear)
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: enabled && !loading ? () => onSubmit() : null,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, size: 20),
          ),
        ),
      ],
    );
  }
}

class _SuggestionsRow extends StatelessWidget {
  final void Function(String) onTap;
  const _SuggestionsRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Questions fréquentes',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.5),
                )),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestions.map((s) => ActionChip(
            label: Text(s, style: const TextStyle(fontSize: 12)),
            onPressed: () => onTap(s),
            avatar: const Icon(Icons.auto_awesome, size: 14),
          )).toList(),
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(cs.primary)),
            ),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Analyse en cours...',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Text('Claude Haiku analyse vos données',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      )),
            ]),
          ],
        ),
      ),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  final String response;
  final bool isDark;
  const _ResponseCard({required this.response, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF1A56DB).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A56DB).withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFF1A56DB), size: 18),
                const SizedBox(width: 8),
                Text('Recommandations',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF1A56DB),
                          fontWeight: FontWeight.w700,
                        )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              response,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: cs.onSurface.withValues(alpha: 0.85),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: cs.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(error,
                  style: TextStyle(color: cs.error, fontSize: 13))),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          Icon(Icons.psychology_outlined, size: 64,
              color: cs.onSurface.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Text('Posez votre première question',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.4),
                  )),
        ],
      ),
    );
  }
}
