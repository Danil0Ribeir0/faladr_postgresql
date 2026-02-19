import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faladr_shared/faladr_shared.dart';
import '../repositories/paciente_repository.dart';
import '../controller/paciente_controller.dart';

final cadastrandoPacienteProvider = StateProvider<bool>((ref) => false);

Future<void> salvarPaciente({
  required WidgetRef ref,
  required String? id,
  required String nome,
  required String cpf,
  required String dataNascimento,
  PlanoModel? plano,
}) async {
  
  ref.read(cadastrandoPacienteProvider.notifier).state = true;

  try {
    final repository = ref.read(pacienteRepositoryProvider);

    final paciente = PacienteModel(
      id: id,
      nome: nome,
      cpf: cpf,
      dataNascimento: DateTime.parse(dataNascimento),
      plano: plano,
    );

    if (id == null) {
      await repository.criarPaciente(paciente);
    } else {
      await repository.atualizarPaciente(paciente);
    }

    ref.invalidate(listaPacientesProvider);

  } finally {
    ref.read(cadastrandoPacienteProvider.notifier).state = false;
  }
}

Future<void> excluirPaciente({
  required WidgetRef ref,
  required String id,
}) async {
  ref.read(cadastrandoPacienteProvider.notifier).state = true;

  try {
    final repository = ref.read(pacienteRepositoryProvider);
    await repository.deletarPaciente(id);
    
    ref.invalidate(listaPacientesProvider);
    
  } finally {
    ref.read(cadastrandoPacienteProvider.notifier).state = false;
  }
}