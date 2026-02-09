import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plano_model.dart';
import '../repositories/plano_repository.dart';

final planoRepositoryProvider = Provider<PlanoRepository>((ref) {
  return PlanoRepository();
});

final listaPlanosProvider = FutureProvider<List<PlanoModel>>((ref) async {
  final repository = ref.watch(planoRepositoryProvider);
  return repository.getPlanos();
});