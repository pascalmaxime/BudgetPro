import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/compte_repository.dart';
import '../../domain/entities/compte.dart';

final compteRepositoryProvider = Provider((_) => CompteRepository());

final comptesProvider = AsyncNotifierProvider<ComptesNotifier, List<Compte>>(() {
  return ComptesNotifier();
});

class ComptesNotifier extends AsyncNotifier<List<Compte>> {
  CompteRepository get _repo => ref.read(compteRepositoryProvider);

  @override
  Future<List<Compte>> build() => _repo.getAll();

  Future<void> ajouter(Compte c) async {
    await _repo.insert(c);
    state = AsyncData([...state.value ?? [], c]);
  }

  Future<void> modifier(Compte c) async {
    await _repo.update(c);
    state = AsyncData(
      (state.value ?? []).map((e) => e.id == c.id ? c : e).toList(),
    );
  }

  Future<void> mettreAJourSolde(String id, double nouveauSolde) async {
    final current = (state.value ?? []).firstWhere((e) => e.id == id);
    await modifier(current.copyWith(solde: nouveauSolde));
  }

  Future<void> supprimer(String id) async {
    await _repo.delete(id);
    state = AsyncData((state.value ?? []).where((e) => e.id != id).toList());
  }
}

// Valeur totale par catégorie
final totalParCategorieProvider = Provider<Map<CategorieCompte, double>>((ref) {
  final comptes = ref.watch(comptesProvider).value ?? [];
  final Map<CategorieCompte, double> totaux = {};
  for (final c in comptes) {
    totaux[c.type.categorie] = (totaux[c.type.categorie] ?? 0) + c.solde;
  }
  return totaux;
});

// Patrimoine total
final patrimoineTotal = Provider<double>((ref) {
  return (ref.watch(comptesProvider).value ?? [])
      .fold(0.0, (sum, c) => sum + c.solde);
});

// Intérêts estimés annuels
final interetsEstimesAnnuels = Provider<double>((ref) {
  return (ref.watch(comptesProvider).value ?? [])
      .where((c) => c.type.tauxAnnuel != null)
      .fold(0.0, (sum, c) => sum + (c.interetsAnnuelsEstimes ?? 0));
});
