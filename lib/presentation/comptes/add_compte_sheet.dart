import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/compte.dart';
import '../../features/comptes/comptes_provider.dart';

class AddCompteSheet extends ConsumerStatefulWidget {
  final Compte? compte;
  const AddCompteSheet({super.key, this.compte});

  @override
  ConsumerState<AddCompteSheet> createState() => _AddCompteSheetState();
}

class _AddCompteSheetState extends ConsumerState<AddCompteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _soldeCtrl = TextEditingController();
  final _banqueCtrl = TextEditingController();
  TypeCompte _type = TypeCompte.livretA;
  DateTime? _dateOuverture;

  @override
  void initState() {
    super.initState();
    if (widget.compte != null) {
      final c = widget.compte!;
      _nomCtrl.text = c.nom;
      _soldeCtrl.text = c.solde.toString();
      _banqueCtrl.text = c.banque ?? '';
      _type = c.type;
      _dateOuverture = c.dateOuverture;
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _soldeCtrl.dispose();
    _banqueCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final c = Compte(
      id: widget.compte?.id ?? const Uuid().v4(),
      nom: _nomCtrl.text.trim(),
      type: _type,
      solde: double.parse(_soldeCtrl.text.replaceAll(',', '.')),
      banque: _banqueCtrl.text.trim().isEmpty ? null : _banqueCtrl.text.trim(),
      dateOuverture: _dateOuverture,
    );
    if (widget.compte == null) {
      await ref.read(comptesProvider.notifier).ajouter(c);
    } else {
      await ref.read(comptesProvider.notifier).modifier(c);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.compte != null;
    final cs = Theme.of(context).colorScheme;

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
              Text(isEdit ? 'Modifier le compte' : 'Ajouter un compte',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),

              // Type selector
              DropdownButtonFormField<TypeCompte>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type de compte', border: OutlineInputBorder()),
                items: CategorieCompte.values.expand((cat) {
                  final types = TypeCompte.values.where((t) => t.categorie == cat);
                  return [
                    DropdownMenuItem<TypeCompte>(
                      enabled: false,
                      value: null,
                      child: Text(cat.label,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: cs.primary)),
                    ),
                    ...types.map((t) => DropdownMenuItem(
                          value: t,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(t.label),
                          ),
                        )),
                  ];
                }).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _type = v);
                    if (_nomCtrl.text.isEmpty) _nomCtrl.text = v.label;
                  }
                },
              ),

              // Info box for selected type
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_type.description,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: cs.onPrimaryContainer,
                                    )),
                          ],
                        ),
                      ),
                      if (_type.tauxAnnuel != null) ...[
                        const SizedBox(width: 8),
                        Chip(
                          label: Text('${_type.tauxAnnuel}%/an',
                              style: const TextStyle(fontSize: 11)),
                          backgroundColor: cs.primaryContainer,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                      if (_type.plafond != null) ...[
                        const SizedBox(width: 4),
                        Chip(
                          label: Text('max ${(_type.plafond! / 1000).toStringAsFixed(0)}k€',
                              style: const TextStyle(fontSize: 11)),
                          backgroundColor: cs.secondaryContainer,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              TextFormField(
                controller: _nomCtrl,
                decoration: const InputDecoration(labelText: 'Nom personnalisé', border: OutlineInputBorder(),
                    hintText: 'ex: Livret A Crédit Agricole'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _soldeCtrl,
                decoration: const InputDecoration(
                    labelText: 'Solde actuel (€)', border: OutlineInputBorder(), suffixText: '€'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Invalide';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _banqueCtrl,
                decoration: const InputDecoration(
                    labelText: 'Établissement (optionnel)', border: OutlineInputBorder(),
                    hintText: 'ex: BNP Paribas, Boursorama...'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _dateOuverture ?? DateTime.now(),
                    firstDate: DateTime(1980),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _dateOuverture = d);
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(_dateOuverture != null
                    ? 'Ouvert le ${DateFormat('dd/MM/yyyy').format(_dateOuverture!)}'
                    : 'Date d\'ouverture (optionnel)'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submit,
                child: Text(isEdit ? 'Enregistrer' : 'Ajouter le compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
