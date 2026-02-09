import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faladr_shared/faladr_shared.dart';
import '../repositories/medico_repository.dart';

final medicoRepositoryProvider = Provider<MedicoRepository>((ref) {
  return MedicoRepository();
});

final listaMedicosProvider = FutureProvider<List<MedicoModel>>((ref) async {
  final repository = ref.watch(medicoRepositoryProvider);
  
  return repository.getMedicos();
});