import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faladr_shared/faladr_shared.dart';
import '../repositories/paciente_repository.dart';

final listaPacientesProvider = FutureProvider<List<PacienteModel>>((ref) async {
  final repository = ref.watch(pacienteRepositoryProvider);
  
  return repository.getPacientes();
});