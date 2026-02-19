import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faladr_shared/faladr_shared.dart';
import '../repositories/medico_repository.dart';

final planosSelecionadosProvider = StateProvider.autoDispose<List<PlanoModel>>((ref) {
  return [];
});

final cadastrandoProvider = StateProvider.autoDispose<bool>((ref) => false);

Future<bool> cadastrarMedico({
  required WidgetRef ref,
  required String nome,
  required String crm,
  required String cpf,
  required String dataNascimento,
  required List<PlanoModel> planos,
}) async {
  
  if (planos.isEmpty) throw Exception('Selecione pelo menos 1 plano de saúde.');
  if (planos.length > 3) throw Exception('Selecione no máximo 3 planos de saúde.');

  ref.read(cadastrandoProvider.notifier).state = true;

  try {
    final repository = ref.read(medicoRepositoryProvider);

    final novoMedico = MedicoModel(
      nome: nome,
      crm: crm,
      cpf: cpf,
      dataNascimento: DateTime.parse(dataNascimento),
      planos: planos,
    );

    await repository.criarMedico(novoMedico);
    return true;

  } catch (e) {
    rethrow;
  } finally {
    ref.read(cadastrandoProvider.notifier).state = false;
  }
}

Future<void> editarMedico({
  required WidgetRef ref,
  required String id,
  required String nome,
  required String crm,
  required String cpf,
  required String dataNascimento,
  required List<PlanoModel> planos,
}) async {
  
  if (planos.isEmpty) throw Exception('Selecione pelo menos 1 plano de saúde.');
  if (planos.length > 3) throw Exception('Selecione no máximo 3 planos de saúde.');

  ref.read(cadastrandoProvider.notifier).state = true;

  try {
    final repository = ref.read(medicoRepositoryProvider);
    
    final medicoEditado = MedicoModel(
      id: id, 
      nome: nome,
      crm: crm,
      cpf: cpf,
      dataNascimento: DateTime.parse(dataNascimento),
      planos: planos,
    );

    await repository.atualizarMedico(medicoEditado);
    
  } finally {
    ref.read(cadastrandoProvider.notifier).state = false;
  }
}

Future<void> excluirMedico({
  required WidgetRef ref,
  required String id,
}) async {
  ref.read(cadastrandoProvider.notifier).state = true;

  try {
    final repository = ref.read(medicoRepositoryProvider);
    await repository.deletarMedico(id);
  } finally {
    ref.read(cadastrandoProvider.notifier).state = false;
  }
}