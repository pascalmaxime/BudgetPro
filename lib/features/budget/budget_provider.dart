import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/transactions_repository.dart';
import '../../domain/entities/transaction.dart';

final transactionsRepositoryProvider = Provider((_) => TransactionsRepository());

final moisSelectionneProvider = StateProvider<String>((ref) {
  return DateFormat('yyyy-MM').format(DateTime.now());
});

final transactionsMoisProvider = AsyncNotifierProviderFamily<TransactionsMoisNotifier, List<Transaction>, String>(() {
  return TransactionsMoisNotifier();
});

class TransactionsMoisNotifier extends FamilyAsyncNotifier<List<Transaction>, String> {
  TransactionsRepository get _repo => ref.read(transactionsRepositoryProvider);

  @override
  Future<List<Transaction>> build(String arg) => _repo.getByMois(arg);

  Future<void> ajouter(Transaction t) async {
    await _repo.insert(t);
    state = AsyncData([t, ...state.value ?? []]);
  }

  Future<void> modifier(Transaction t) async {
    await _repo.update(t);
    state = AsyncData(
      (state.value ?? []).map((e) => e.id == t.id ? t : e).toList(),
    );
  }

  Future<void> supprimer(String id) async {
    await _repo.delete(id);
    state = AsyncData((state.value ?? []).where((e) => e.id != id).toList());
  }
}

final moisDisponiblesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.read(transactionsRepositoryProvider);
  return repo.getMoisDisponibles();
});

class ResumeMois {
  final double totalRevenus;
  final double totalDepensesFixes;
  final double totalDepensesVariables;
  final double totalEpargne;

  const ResumeMois({
    required this.totalRevenus,
    required this.totalDepensesFixes,
    required this.totalDepensesVariables,
    required this.totalEpargne,
  });

  double get totalDepenses => totalDepensesFixes + totalDepensesVariables;
  double get solde => totalRevenus - totalDepenses - totalEpargne;
}

final resumeMoisProvider = Provider.family<ResumeMois, String>((ref, mois) {
  final transactions = ref.watch(transactionsMoisProvider(mois)).value ?? [];
  double revenus = 0, fixes = 0, variables = 0, epargne = 0;
  for (final t in transactions) {
    switch (t.type) {
      case TransactionType.revenu:
        revenus += t.montant;
      case TransactionType.depenseFixe:
        fixes += t.montant;
      case TransactionType.depenseVariable:
        variables += t.montant;
      case TransactionType.epargne:
        epargne += t.montant;
    }
  }
  return ResumeMois(
    totalRevenus: revenus,
    totalDepensesFixes: fixes,
    totalDepensesVariables: variables,
    totalEpargne: epargne,
  );
});
