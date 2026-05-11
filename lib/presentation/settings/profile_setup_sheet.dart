import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_profile.dart';
import '../../features/profile/profile_provider.dart';

class ProfileSetupSheet extends ConsumerStatefulWidget {
  const ProfileSetupSheet({super.key});

  @override
  ConsumerState<ProfileSetupSheet> createState() => _ProfileSetupSheetState();
}

class _ProfileSetupSheetState extends ConsumerState<ProfileSetupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _loyerCtrl = TextEditingController();
  final _epargneCtrl = TextEditingController();
  final _rappelCtrl = TextEditingController(text: '3');
  ContratType _contrat = ContratType.cdi;
  LogementType _logement = LogementType.locataire;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).value;
    if (profile != null) {
      _contrat = profile.typeContrat;
      _logement = profile.situationLogement;
      _loyerCtrl.text = profile.loyerMensuel?.toString() ?? '';
      _epargneCtrl.text = profile.objectifEpargne.toString();
      _rappelCtrl.text = profile.rappelJoursAvant.toString();
    }
  }

  @override
  void dispose() {
    _loyerCtrl.dispose();
    _epargneCtrl.dispose();
    _rappelCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final existingId = ref.read(profileProvider).value?.id;
    final profile = UserProfile(
      id: existingId,
      typeContrat: _contrat,
      situationLogement: _logement,
      loyerMensuel: _logement == LogementType.locataire
          ? double.tryParse(_loyerCtrl.text.replaceAll(',', '.'))
          : null,
      objectifEpargne: double.parse(_epargneCtrl.text.replaceAll(',', '.')),
      rappelJoursAvant: int.tryParse(_rappelCtrl.text) ?? 3,
    );
    await ref.read(profileProvider.notifier).save(profile);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Profil financier',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              DropdownButtonFormField<ContratType>(
                initialValue: _contrat,
                decoration: const InputDecoration(labelText: 'Situation professionnelle', border: OutlineInputBorder()),
                items: ContratType.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
                onChanged: (v) => setState(() => _contrat = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<LogementType>(
                initialValue: _logement,
                decoration: const InputDecoration(labelText: 'Situation logement', border: OutlineInputBorder()),
                items: LogementType.values.map((l) => DropdownMenuItem(value: l, child: Text(l.label))).toList(),
                onChanged: (v) => setState(() => _logement = v!),
              ),
              if (_logement == LogementType.locataire) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _loyerCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Loyer mensuel (€)', border: OutlineInputBorder(), suffixText: '€'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Invalide';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _epargneCtrl,
                decoration: const InputDecoration(
                    labelText: 'Objectif épargne mensuel (€)', border: OutlineInputBorder(), suffixText: '€'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Invalide';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rappelCtrl,
                decoration: const InputDecoration(
                    labelText: 'Rappel abonnements (jours avant)', border: OutlineInputBorder(), suffixText: 'j'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  if (int.tryParse(v) == null || int.parse(v) < 1) return 'Minimum 1 jour';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _submit, child: const Text('Enregistrer le profil')),
            ],
          ),
        ),
      ),
    );
  }
}
