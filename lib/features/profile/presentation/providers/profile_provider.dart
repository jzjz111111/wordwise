import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/repositories/profile_repository_impl.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl();
});

final profileProvider = FutureProvider.family<Profile?, String>((ref, userId) async {
  final repository = ref.watch(profileRepositoryProvider);
  return await repository.getProfile(userId);
});