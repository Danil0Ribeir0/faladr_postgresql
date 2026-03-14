import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faladr_shared/faladr_shared.dart';
import '../repositories/medico_repository.dart';
import '../core/dio_provider.dart'; 

final medicoRepositoryProvider = Provider<MedicoRepository>((ref) {
  final dio = ref.watch(dioProvider);

  return MedicoRepository(dio);
});

final listaMedicosProvider = FutureProvider<List<MedicoModel>>((ref) async {
  final repository = ref.watch(medicoRepositoryProvider);
  
  return repository.getMedicos();
});