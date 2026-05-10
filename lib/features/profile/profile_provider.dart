import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/profile_repository.dart';
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
    final saved = await _repo.save(profile);
    state = AsyncData(saved);
  }
}
