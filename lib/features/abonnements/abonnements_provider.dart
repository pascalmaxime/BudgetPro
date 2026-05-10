import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/abonnements_repository.dart';
import '../../domain/entities/abonnement.dart';

final abonnementsRepositoryProvider = Provider((_) => AbonnementsRepository());

final abonnementsProvider = AsyncNotifierProvider<AbonnementsNotifier, List<Abonnement>>(() {
  return AbonnementsNotifier();
});

class AbonnementsNotifier extends AsyncNotifier<List<Abonnement>> {
  AbonnementsRepository get _repo => ref.read(abonnementsRepositoryProvider);

  @override
  Future<List<Abonnement>> build() => _repo.getAll();

  Future<void> ajouter(Abonnement a) async {
    await _repo.insert(a);
    state = AsyncData([...state.value ?? [], a]);
  }

  Future<void> modifier(Abonnement a) async {
    await _repo.update(a);
    state = AsyncData(
      (state.value ?? []).map((e) => e.id == a.id ? a : e).toList(),
    );
  }

  Future<void> supprimer(String id) async {
    await _repo.delete(id);
    state = AsyncData((state.value ?? []).where((e) => e.id != id).toList());
  }

  Future<void> toggleActif(String id) async {
    final current = (state.value ?? []).firstWhere((e) => e.id == id);
    await modifier(current.copyWith(actif: !current.actif));
  }
}

final abonnementsActifsProvider = Provider<List<Abonnement>>((ref) {
  return ref.watch(abonnementsProvider).value?.where((a) => a.actif).toList() ?? [];
});

final coutMensuelAbonnementsProvider = Provider<double>((ref) {
  return ref
      .watch(abonnementsActifsProvider)
      .fold(0.0, (sum, a) => sum + a.montantMensuel);
});
