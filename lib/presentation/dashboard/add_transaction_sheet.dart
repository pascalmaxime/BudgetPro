import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/transaction.dart';
import '../../features/budget/budget_provider.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  final TransactionType type;
  final Transaction? transaction; // non-null = mode édition

  const AddTransactionSheet({
    super.key,
    required this.type,
    this.transaction,
  });

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  late CategorieTransaction _categorie;
  late DateTime _date;
  late TransactionType _type;

  bool get _isEdit => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final t = widget.transaction!;
      _descCtrl.text = t.description;
      _montantCtrl.text = t.montant.toString();
      _categorie = t.categorie;
      _date = t.date;
      _type = t.type;
    } else {
      _type = widget.type;
      _date = DateTime.now();
      _categorie = switch (widget.type) {
        TransactionType.revenu => CategorieTransaction.salaire,
        TransactionType.epargne => CategorieTransaction.epargne,
        _ => CategorieTransaction.autre,
      };
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _montantCtrl.dispose();
    super.dispose();
  }

  List<CategorieTransaction> get _categories => switch (_type) {
        TransactionType.revenu => [
            CategorieTransaction.salaire,
            CategorieTransaction.apl,
            CategorieTransaction.autreRevenu,
          ],
        TransactionType.epargne => [CategorieTransaction.epargne],
        _ => CategorieTransaction.values
            .where((c) =>
                c != CategorieTransaction.salaire &&
                c != CategorieTransaction.apl &&
                c != CategorieTransaction.autreRevenu &&
                c != CategorieTransaction.epargne)
            .toList(),
      };

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _delete() async {
    final t = widget.transaction!;
    Navigator.of(context).pop();
    // Petite pause pour laisser le sheet se fermer proprement avant de supprimer
    await Future.delayed(const Duration(milliseconds: 150));
    ref.read(transactionsMoisProvider(t.mois).notifier).supprimer(t.id);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final mois = _isEdit
        ? widget.transaction!.mois
        : ref.read(moisSelectionneProvider);

    final t = Transaction(
      id: widget.transaction?.id ?? const Uuid().v4(),
      mois: mois,
      montant: double.parse(_montantCtrl.text.replaceAll(',', '.')),
      description: _descCtrl.text.trim(),
      categorie: _categorie,
      date: _date,
      type: _type,
    );

    final notifier = ref.read(transactionsMoisProvider(mois).notifier);
    if (_isEdit) {
      notifier.modifier(t);
    } else {
      notifier.ajouter(t);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Titre + sélecteur de type + bouton supprimer
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEdit ? 'Modifier la transaction' : 'Ajouter — ${_type.label}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (_isEdit) ...[
                    // Bouton supprimer
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error),
                      tooltip: 'Supprimer cette transaction',
                      onPressed: _delete,
                    ),
                    // Sélecteur de type en mode édition
                    DropdownButton<TransactionType>(
                      value: _type,
                      underline: const SizedBox(),
                      borderRadius: BorderRadius.circular(12),
                      items: TransactionType.values
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.label,
                                    style: TextStyle(
                                        fontSize: 13, color: cs.primary)),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _type = v;
                            // Réinitialiser la catégorie si elle n'existe plus
                            if (!_categories.contains(_categorie)) {
                              _categorie = _categories.first;
                            }
                          });
                        }
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // Description
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                    labelText: 'Description', border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 12),

              // Montant
              TextFormField(
                controller: _montantCtrl,
                decoration: const InputDecoration(
                    labelText: 'Montant (€)',
                    border: OutlineInputBorder(),
                    suffixText: '€'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  if (double.tryParse(v.replaceAll(',', '.')) == null) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Catégorie
              DropdownButtonFormField<CategorieTransaction>(
                initialValue: _categories.contains(_categorie)
                    ? _categorie
                    : _categories.first,
                decoration: const InputDecoration(
                    labelText: 'Catégorie', border: OutlineInputBorder()),
                items: _categories
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c.label)))
                    .toList(),
                onChanged: (v) => setState(() => _categorie = v!),
              ),
              const SizedBox(height: 12),

              // Date
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                    'Date : ${DateFormat('dd/MM/yyyy').format(_date)}'),
              ),
              const SizedBox(height: 20),

              FilledButton(
                onPressed: _submit,
                child: Text(_isEdit ? 'Enregistrer les modifications' : 'Ajouter ${_type.label}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
