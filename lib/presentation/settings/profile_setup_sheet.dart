import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/user_profile.dart';
import '../../features/profile/profile_provider.dart';

// ── Items éditables ────────────────────────────────────────────────────────────

class _SourceItem {
  final String id;
  final TextEditingController labelCtrl;
  final TextEditingController montantCtrl;
  final TextEditingController jourCtrl;

  _SourceItem({
    required this.id,
    String label = '',
    String montant = '',
    String jour = '1',
  })  : labelCtrl = TextEditingController(text: label),
        montantCtrl = TextEditingController(text: montant),
        jourCtrl = TextEditingController(text: jour);

  void dispose() {
    labelCtrl.dispose();
    montantCtrl.dispose();
    jourCtrl.dispose();
  }

  double get montant =>
      double.tryParse(montantCtrl.text.replaceAll(',', '.')) ?? 0;
  int get jour => (int.tryParse(jourCtrl.text) ?? 1).clamp(1, 31);
}

class _ChargeItem {
  final String id;
  final TextEditingController labelCtrl;
  final TextEditingController montantCtrl;
  final TextEditingController jourCtrl;

  _ChargeItem({
    required this.id,
    String label = '',
    String montant = '',
    String jour = '1',
  })  : labelCtrl = TextEditingController(text: label),
        montantCtrl = TextEditingController(text: montant),
        jourCtrl = TextEditingController(text: jour);

  void dispose() {
    labelCtrl.dispose();
    montantCtrl.dispose();
    jourCtrl.dispose();
  }

  double get montant =>
      double.tryParse(montantCtrl.text.replaceAll(',', '.')) ?? 0;
  int get jour => (int.tryParse(jourCtrl.text) ?? 1).clamp(1, 31);
}

// ── ProfileSetupSheet ──────────────────────────────────────────────────────────

class ProfileSetupSheet extends ConsumerStatefulWidget {
  const ProfileSetupSheet({super.key});

  @override
  ConsumerState<ProfileSetupSheet> createState() => _ProfileSetupSheetState();
}

class _ProfileSetupSheetState extends ConsumerState<ProfileSetupSheet> {
  static const _uuid = Uuid();

  // ── Situation ────────────────────────────────────────────────────────────
  ContratType _contrat = ContratType.cdi;
  LogementType _logement = LogementType.locataire;
  final _loyerCtrl = TextEditingController();

  // ── Revenus ──────────────────────────────────────────────────────────────
  final List<_SourceItem> _sources = [];

  // ── Charges fixes ────────────────────────────────────────────────────────
  final List<_ChargeItem> _charges = [];

  // ── Objectif ─────────────────────────────────────────────────────────────
  bool _objectifManuel = false;
  final _objectifCtrl = TextEditingController(text: '0');

  // ── Objectif patrimoine ──────────────────────────────────────────────────
  final _objectifPatrimoineCtrl = TextEditingController(text: '');
  DateTime? _dateObjectifPatrimoine;

  // ── Rappel abonnements ────────────────────────────────────────────────────
  final _rappelCtrl = TextEditingController(text: '3');

  // ── Scroll ────────────────────────────────────────────────────────────────
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).value;
    if (profile != null) {
      _contrat = profile.typeContrat;
      _logement = profile.situationLogement;
      _loyerCtrl.text = profile.loyerMensuel?.toStringAsFixed(0) ?? '';
      _rappelCtrl.text = profile.rappelJoursAvant.toString();
      for (final s in profile.sources) {
        _sources.add(_SourceItem(
          id: s.id,
          label: s.label,
          montant: s.montant.toStringAsFixed(0),
          jour: s.jour.toString(),
        ));
      }
      for (final c in profile.chargesFixes) {
        _charges.add(_ChargeItem(
          id: c.id,
          label: c.label,
          montant: c.montant.toStringAsFixed(0),
          jour: c.jour.toString(),
        ));
      }
      if (profile.objectifEpargne > 0) {
        _objectifManuel = true;
        _objectifCtrl.text = profile.objectifEpargne.toStringAsFixed(0);
      }
      if (profile.objectifPatrimoine > 0) {
        _objectifPatrimoineCtrl.text =
            profile.objectifPatrimoine.toStringAsFixed(0);
      }
      _dateObjectifPatrimoine = profile.dateObjectifPatrimoine;
    }
    if (_sources.isEmpty) {
      _sources.add(_SourceItem(id: _uuid.v4(), label: 'Salaire net'));
    }
  }

  @override
  void dispose() {
    _loyerCtrl.dispose();
    _objectifCtrl.dispose();
    _objectifPatrimoineCtrl.dispose();
    _rappelCtrl.dispose();
    _scrollCtrl.dispose();
    for (final s in _sources) {
      s.dispose();
    }
    for (final c in _charges) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Computed ──────────────────────────────────────────────────────────────

  double get _revenuTotal =>
      _sources.fold(0.0, (sum, item) => sum + item.montant);

  double get _tauxRecommande => switch (_contrat) {
        ContratType.cdi => 20.0,
        ContratType.cdd => 15.0,
        ContratType.alternant => 15.0,
        ContratType.freelance => 25.0,
        ContratType.etudiant => 10.0,
        ContratType.sansEmploi => 5.0,
        ContratType.retraite => 10.0,
      };

  double get _objectifAuto => _revenuTotal * _tauxRecommande / 100;

  // ── Actions ───────────────────────────────────────────────────────────────

  void _addSource() => setState(
      () => _sources.add(_SourceItem(id: _uuid.v4())));

  void _removeSource(int i) => setState(() {
        _sources[i].dispose();
        _sources.removeAt(i);
      });

  void _addCharge() => setState(
      () => _charges.add(_ChargeItem(id: _uuid.v4())));

  void _removeCharge(int i) => setState(() {
        _charges[i].dispose();
        _charges.removeAt(i);
      });

  Future<void> _submit() async {
    // Validation : au moins une source de revenu avec un montant valide
    final hasRevenu = _sources.any(
      (s) => s.labelCtrl.text.trim().isNotEmpty && s.montant > 0,
    );
    if (!hasRevenu) {
      // Remonter au début pour montrer la section Revenus
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez au moins une source de revenu avec un montant.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final sources = <SourceRevenu>[
      for (final item in _sources)
        if (item.labelCtrl.text.trim().isNotEmpty && item.montant > 0)
          SourceRevenu(
              id: item.id,
              label: item.labelCtrl.text.trim(),
              montant: item.montant,
              jour: item.jour),
    ];

    final charges = <ChargeFixer>[
      for (final item in _charges)
        if (item.labelCtrl.text.trim().isNotEmpty && item.montant > 0)
          ChargeFixer(
              id: item.id,
              label: item.labelCtrl.text.trim(),
              montant: item.montant,
              jour: item.jour),
    ];

    final existingId = ref.read(profileProvider).value?.id;
    final profile = UserProfile(
      id: existingId,
      typeContrat: _contrat,
      situationLogement: _logement,
      loyerMensuel: _logement == LogementType.locataire
          ? double.tryParse(_loyerCtrl.text.replaceAll(',', '.'))
          : null,
      sources: sources,
      chargesFixes: charges,
      objectifEpargne: _objectifManuel
          ? (double.tryParse(_objectifCtrl.text.replaceAll(',', '.')) ?? 0)
          : 0,
      rappelJoursAvant: int.tryParse(_rappelCtrl.text) ?? 3,
      objectifPatrimoine:
          double.tryParse(_objectifPatrimoineCtrl.text.replaceAll(',', '.')) ??
              0,
      dateObjectifPatrimoine: _dateObjectifPatrimoine,
    );

    await ref.read(profileProvider.notifier).save(profile);
    if (mounted) Navigator.of(context).pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 8),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profil financier',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Revenus, charges et objectifs personnalisés',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                    ),
                  ],
                ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: _submit,
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSituationSection(context, cs),
                  const SizedBox(height: 20),
                  _buildSourcesSection(context, cs),
                  const SizedBox(height: 20),
                  _buildChargesSection(context, cs),
                  const SizedBox(height: 20),
                  _buildObjectifSection(context, cs),
                  const SizedBox(height: 20),
                  _buildObjectifPatrimoineSection(context, cs),
                  const SizedBox(height: 20),
                  _buildNotificationsSection(context, cs),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Enregistrer le profil'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sections ──────────────────────────────────────────────────────────────

  Widget _buildSituationSection(BuildContext context, ColorScheme cs) {
    return _Section(
      icon: Icons.person_outline_rounded,
      title: 'Situation',
      children: [
        DropdownButtonFormField<ContratType>(
          initialValue: _contrat,
          decoration: const InputDecoration(
            labelText: 'Statut professionnel',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: ContratType.values
              .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
              .toList(),
          onChanged: (v) => setState(() => _contrat = v!),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<LogementType>(
          initialValue: _logement,
          decoration: const InputDecoration(
            labelText: 'Situation logement',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: LogementType.values
              .map((l) => DropdownMenuItem(value: l, child: Text(l.label)))
              .toList(),
          onChanged: (v) => setState(() => _logement = v!),
        ),
        if (_logement == LogementType.locataire) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _loyerCtrl,
            decoration: const InputDecoration(
              labelText: 'Loyer mensuel (optionnel)',
              hintText: 'Ex : 750',
              border: OutlineInputBorder(),
              suffixText: '€',
              isDense: true,
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ],
    );
  }

  Widget _buildSourcesSection(BuildContext context, ColorScheme cs) {
    return _Section(
      icon: Icons.arrow_downward_rounded,
      iconColor: AppColors.revenue,
      title: 'Revenus mensuels récurrents',
      trailing: IconButton(
        icon: Icon(Icons.add_circle_rounded, color: AppColors.revenue),
        tooltip: 'Ajouter une source',
        visualDensity: VisualDensity.compact,
        onPressed: _addSource,
      ),
      children: [
        Text(
          'Salaire, allocations, freelance, loyers perçus…',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
        ),
        const SizedBox(height: 10),
        ...List.generate(_sources.length, (i) {
          final item = _sources[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: item.labelCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: i == 0 ? 'Salaire net' : 'Libellé',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: item.montantCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(),
                      suffixText: '€',
                      isDense: true,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Jour du mois (1–31)',
                  child: SizedBox(
                    width: 48,
                    child: TextField(
                      controller: item.jourCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'J.',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline,
                      color: cs.error.withValues(alpha: 0.7), size: 20),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Supprimer',
                  onPressed: _sources.length > 1 ? () => _removeSource(i) : null,
                ),
              ],
            ),
          );
        }),
        if (_revenuTotal > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Total : ${_revenuTotal.toStringAsFixed(0)} € / mois',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.revenue,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.end,
            ),
          ),
        TextButton.icon(
          onPressed: _addSource,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Ajouter une source de revenu'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.revenue,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  Widget _buildChargesSection(BuildContext context, ColorScheme cs) {
    return _Section(
      icon: Icons.lock_outline_rounded,
      iconColor: AppColors.warning,
      title: 'Charges fixes mensuelles',
      trailing: IconButton(
        icon: Icon(Icons.add_circle_rounded, color: AppColors.warning),
        tooltip: 'Ajouter une charge',
        visualDensity: VisualDensity.compact,
        onPressed: _addCharge,
      ),
      children: [
        Text(
          'Factures récurrentes hors loyer (électricité, internet, assurance…)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
        ),
        if (_logement == LogementType.locataire &&
            _loyerCtrl.text.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.home_outlined,
                    size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Loyer mensuel : ${_loyerCtrl.text} €',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Text(
                  '(section Situation)',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        ...List.generate(_charges.length, (i) {
          final item = _charges[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: item.labelCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Électricité, internet…',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: item.montantCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(),
                      suffixText: '€',
                      isDense: true,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Jour du mois (1–31)',
                  child: SizedBox(
                    width: 48,
                    child: TextField(
                      controller: item.jourCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'J.',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline,
                      color: cs.error.withValues(alpha: 0.7), size: 20),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Supprimer',
                  onPressed: () => _removeCharge(i),
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: _addCharge,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Ajouter une charge fixe'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.warning,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  Widget _buildObjectifSection(BuildContext context, ColorScheme cs) {
    return _Section(
      icon: Icons.savings_rounded,
      iconColor: AppColors.savings,
      title: 'Objectif d\'épargne',
      children: [
        // Auto-computed preview
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.savings.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppColors.savings.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: AppColors.savings),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Objectif recommandé : ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                    children: [
                      TextSpan(
                        text:
                            '${_objectifAuto.toStringAsFixed(0)} €/mois',
                        style: TextStyle(
                          color: AppColors.savings,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: ' (${_tauxRecommande.toStringAsFixed(0)} % — ${_contrat.label})',
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SwitchListTile.adaptive(
          value: _objectifManuel,
          onChanged: (v) => setState(() {
            _objectifManuel = v;
            if (v && _objectifCtrl.text == '0' && _objectifAuto > 0) {
              _objectifCtrl.text =
                  _objectifAuto.toStringAsFixed(0);
            }
          }),
          title: const Text('Personnaliser l\'objectif'),
          subtitle: Text(
            _objectifManuel
                ? 'Saisie manuelle activée'
                : 'Calcul automatique selon votre statut',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
          ),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        if (_objectifManuel) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _objectifCtrl,
            decoration: const InputDecoration(
              labelText: 'Objectif épargne mensuel',
              border: OutlineInputBorder(),
              suffixText: '€',
              isDense: true,
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ],
    );
  }

  Widget _buildObjectifPatrimoineSection(
      BuildContext context, ColorScheme cs) {
    return _Section(
      icon: Icons.emoji_events_rounded,
      iconColor: const Color(0xFFF59E0B),
      title: 'Objectif patrimoine',
      children: [
        Text(
          'Définissez un cap à atteindre et l\'appli calculera ce qu\'il faut mettre de côté chaque mois.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _objectifPatrimoineCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Patrimoine cible',
                  hintText: 'Ex : 100000',
                  border: OutlineInputBorder(),
                  suffixText: '€',
                  isDense: true,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dateObjectifPatrimoine ??
                        DateTime(now.year + 2, now.month, now.day),
                    firstDate: DateTime(now.year, now.month + 1),
                    lastDate: DateTime(now.year + 30),
                    helpText: 'Date d\'échéance',
                  );
                  if (picked != null) {
                    setState(() => _dateObjectifPatrimoine = picked);
                  }
                },
                icon: const Icon(Icons.calendar_month_outlined, size: 16),
                label: Text(
                  _dateObjectifPatrimoine != null
                      ? '${_dateObjectifPatrimoine!.day.toString().padLeft(2, '0')}/${_dateObjectifPatrimoine!.month.toString().padLeft(2, '0')}/${_dateObjectifPatrimoine!.year}'
                      : 'Échéance',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
        if (_dateObjectifPatrimoine != null &&
            (_objectifPatrimoineCtrl.text.trim().isNotEmpty)) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() {
              _objectifPatrimoineCtrl.clear();
              _dateObjectifPatrimoine = null;
            }),
            icon: const Icon(Icons.clear, size: 14),
            label: const Text('Effacer l\'objectif'),
            style: TextButton.styleFrom(
              foregroundColor: cs.error,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNotificationsSection(BuildContext context, ColorScheme cs) {
    return _Section(
      icon: Icons.notifications_outlined,
      title: 'Rappels',
      children: [
        TextField(
          controller: _rappelCtrl,
          decoration: const InputDecoration(
            labelText: 'Rappel avant renouvellement d\'abonnement',
            border: OutlineInputBorder(),
            suffixText: 'jours',
            isDense: true,
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}

// ── Section widget ─────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  const _Section({
    required this.icon,
    this.iconColor,
    required this.title,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = iconColor ?? cs.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (trailing != null) ...[
              const Spacer(),
              trailing!,
            ],
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}
