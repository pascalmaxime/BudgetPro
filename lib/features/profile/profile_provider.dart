import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/services/recurring_service.dart';
import '../../domain/entities/user_profile.dart';

final profileRepositoryProvider = Provider((_) => ProfileRepository());

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile?>(() {
  return ProfileNotifier();
});

class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  @override
  Future<UserProfile?> build() => _repo.get();

  Future<void> save(UserProfile profile) async {
    final isFirstSave = state.value == null;
    final saved = await _repo.save(profile);
    state = AsyncData(saved);

    // Si c'est la première configuration du profil, réinitialiser le bootstrap
    // du mois courant pour que les transactions récurrentes soient injectées.
    if (isFirstSave) {
      final mois = DateFormat('yyyy-MM').format(DateTime.now());
      await RecurringService.resetBootstrap(mois);
    }
  }
}
