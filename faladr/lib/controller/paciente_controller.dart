import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/paciente_model.dart';
import '../repositories/paciente_repository.dart';

final listaPacientesProvider = FutureProvider<List<PacienteModel>>((ref) async {
  final repository = ref.watch(pacienteRepositoryProvider);
  
  return repository.getPacientes();
});