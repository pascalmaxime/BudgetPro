import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../abonnements/abonnements_provider.dart';
import '../budget/budget_provider.dart';
import '../profile/profile_provider.dart';
import 'ia_service.dart';

final iaServiceProvider = Provider((_) => IaService());

final iaLoadingProvider = StateProvider<bool>((_) => false);
final iaResponseProvider = StateProvider<String?>((_) => null);
final iaErrorProvider = StateProvider<String?>((_) => null);

class IaActions {
  final Ref _ref;
  IaActions(this._ref);

  Future<void> analyser([String? question]) async {
    _ref.read(iaLoadingProvider.notifier).state = true;
    _ref.read(iaErrorProvider.notifier).state = null;

    try {
      final profile = _ref.read(profileProvider).value;
      if (profile == null) {
        _ref.read(iaErrorProvider.notifier).state =
            'Veuillez d\'abord configurer votre profil financier.';
        return;
      }

      final mois = _ref.read(moisSelectionneProvider);
      final transactions = _ref.read(transactionsMoisProvider(mois)).value ?? [];
      final abonnements = _ref.read(abonnementsProvider).value ?? [];

      final response = await _ref.read(iaServiceProvider).analyserBudget(
            profile: profile,
            transactions: transactions,
            abonnements: abonnements,
            mois: mois,
            questionUtilisateur: question,
          );

      _ref.read(iaResponseProvider.notifier).state = response;
    } catch (e) {
      _ref.read(iaErrorProvider.notifier).state = 'Erreur : $e';
    } finally {
      _ref.read(iaLoadingProvider.notifier).state = false;
    }
  }
}

final iaActionsProvider = Provider((ref) => IaActions(ref));
