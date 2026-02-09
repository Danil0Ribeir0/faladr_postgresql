import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/paciente_model.dart';
import '../models/plano_model.dart';

class PacienteRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> criarPaciente(PacienteModel paciente) async {
    try {
      final response = await _client.from('pacientes').insert({
        'nome': paciente.nome,
        'cpf': paciente.cpf,
        'data_nascimento': paciente.dataNascimento.toIso8601String(),
      }).select().single();

      final novoIdPaciente = response['id'];

      if (paciente.planos.isNotEmpty) {
        await _vincularPlanos(novoIdPaciente, paciente.planos);
      }
    } catch (e) {
      throw Exception('Erro ao criar paciente: $e');
    }
  }

  Future<List<PacienteModel>> getPacientes() async {
    try {
      final response = await _client
          .from('pacientes')
          .select('*, planos(*)');

      final data = response as List<dynamic>;
      return data.map((json) => PacienteModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar pacientes: $e');
    }
  }

  Future<void> atualizarPaciente(PacienteModel paciente) async {
    if (paciente.id == null) throw Exception('ID necessário para atualizar');

    try {
      await _client.from('pacientes').update({
        'nome': paciente.nome,
        'cpf': paciente.cpf,
        'data_nascimento': paciente.dataNascimento.toIso8601String(),
      }).eq('id', paciente.id!);

      await _client.from('paciente_planos').delete().eq('paciente_id', paciente.id!);

      if (paciente.planos.isNotEmpty) {
        await _vincularPlanos(paciente.id!, paciente.planos);
      }
    } catch (e) {
      throw Exception('Erro ao atualizar paciente: $e');
    }
  }

  Future<void> deletarPaciente(String id) async {
    try {
      await _client.from('pacientes').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar paciente: $e');
    }
  }

  Future<void> _vincularPlanos(String pacienteId, List<PlanoModel> planos) async {
    final listaParaInserir = planos.map((plano) {
      return {
        'paciente_id': pacienteId,
        'plano_id': plano.id,
      };
    }).toList();

    await _client.from('paciente_planos').insert(listaParaInserir);
  }
}

final pacienteRepositoryProvider = Provider<PacienteRepository>((ref) {
  return PacienteRepository();
});