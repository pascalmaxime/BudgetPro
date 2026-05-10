import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/transaction.dart';
import '../../features/budget/budget_provider.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  final TransactionType type;
  const AddTransactionSheet({super.key, required this.type});

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  CategorieTransaction _categorie = CategorieTransaction.autre;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _categorie = switch (widget.type) {
      TransactionType.revenu => CategorieTransaction.salaire,
      TransactionType.epargne => CategorieTransaction.epargne,
      _ => CategorieTransaction.autre,
    };
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _montantCtrl.dispose();
    super.dispose();
  }

  List<CategorieTransaction> get _categories => switch (widget.type) {
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final mois = ref.read(moisSelectionneProvider);
    final t = Transaction(
      id: const Uuid().v4(),
      mois: mois,
      montant: double.parse(_montantCtrl.text.replaceAll(',', '.')),
      description: _descCtrl.text.trim(),
      categorie: _categorie,
      date: _date,
      type: widget.type,
    );
    ref.read(transactionsMoisProvider(mois).notifier).ajouter(t);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = widget.type.label;
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
            Text('Ajouter — $typeLabel',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _montantCtrl,
              decoration: const InputDecoration(labelText: 'Montant (€)', border: OutlineInputBorder(), suffixText: '€'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requis';
                if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Montant invalide';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CategorieTransaction>(
              value: _categorie,
              decoration: const InputDecoration(labelText: 'Catégorie', border: OutlineInputBorder()),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
              onChanged: (v) => setState(() => _categorie = v!),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text('Date : ${DateFormat('dd/MM/yyyy').format(_date)}'),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _submit, child: Text('Ajouter $typeLabel')),
          ],
        ),
      ),
    );
  }
}
