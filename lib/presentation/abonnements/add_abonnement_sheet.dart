import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/abonnement.dart';
import '../../features/abonnements/abonnements_provider.dart';
import '../../features/profile/profile_provider.dart';
import '../../core/notifications/notification_service.dart';

class AddAbonnementSheet extends ConsumerStatefulWidget {
  final Abonnement? abonnement;
  const AddAbonnementSheet({super.key, this.abonnement});

  @override
  ConsumerState<AddAbonnementSheet> createState() => _AddAbonnementSheetState();
}

class _AddAbonnementSheetState extends ConsumerState<AddAbonnementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  FrequenceType _frequence = FrequenceType.mensuel;
  CategorieAbonnement _categorie = CategorieAbonnement.autre;
  DateTime _dateRenouvellement = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.abonnement != null) {
      final a = widget.abonnement!;
      _nomCtrl.text = a.nom;
      _montantCtrl.text = a.montant.toString();
      _frequence = a.frequence;
      _categorie = a.categorie;
      _dateRenouvellement = a.dateRenouvellement;
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _montantCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateRenouvellement,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _dateRenouvellement = picked);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = ref.read(profileProvider).value;
    final joursAvant = profile?.rappelJoursAvant ?? 3;

    final a = Abonnement(
      id: widget.abonnement?.id ?? const Uuid().v4(),
      nom: _nomCtrl.text.trim(),
      montant: double.parse(_montantCtrl.text.replaceAll(',', '.')),
      frequence: _frequence,
      dateRenouvellement: _dateRenouvellement,
      categorie: _categorie,
    );

    if (widget.abonnement == null) {
      await ref.read(abonnementsProvider.notifier).ajouter(a);
    } else {
      await ref.read(abonnementsProvider.notifier).modifier(a);
    }

    await NotificationService.planifierRappelAbonnement(a, joursAvant);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.abonnement != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isEdit ? 'Modifier l\'abonnement' : 'Nouvel abonnement',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nomCtrl,
              decoration: const InputDecoration(labelText: 'Nom (ex: Netflix)', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _montantCtrl,
              decoration: const InputDecoration(
                  labelText: 'Montant (€)', border: OutlineInputBorder(), suffixText: '€'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requis';
                if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Invalide';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<FrequenceType>(
              value: _frequence,
              decoration: const InputDecoration(labelText: 'Fréquence', border: OutlineInputBorder()),
              items: FrequenceType.values.map((f) => DropdownMenuItem(value: f, child: Text(f.label))).toList(),
              onChanged: (v) => setState(() => _frequence = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CategorieAbonnement>(
              value: _categorie,
              decoration: const InputDecoration(labelText: 'Catégorie', border: OutlineInputBorder()),
              items: CategorieAbonnement.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
              onChanged: (v) => setState(() => _categorie = v!),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text('Prochain renouvellement : ${DateFormat('dd/MM/yyyy').format(_dateRenouvellement)}'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submit,
              child: Text(isEdit ? 'Enregistrer' : 'Ajouter l\'abonnement'),
            ),
          ],
        ),
      ),
    );
  }
}
