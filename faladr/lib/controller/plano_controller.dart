import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faladr_shared/faladr_shared.dart';
import '../repositories/plano_repository.dart';
import '../core/dio_provider.dart'; 

final planoRepositoryProvider = Provider<PlanoRepository>((ref) {
  final dio = ref.watch(dioProvider);
  
  return PlanoRepository(dio);
});

final listaPlanosProvider = FutureProvider<List<PlanoModel>>((ref) async {
  final repository = ref.watch(planoRepositoryProvider);
  return repository.getPlanos();
});