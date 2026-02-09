import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medico_model.dart';
import '../models/plano_model.dart';

class MedicoRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> criarMedico(MedicoModel medico) async {
    try {
      final response = await _client.from('medicos').insert({
        'nome': medico.nome,
        'crm': medico.crm,
        'cpf': medico.cpf,
        'data_nascimento': medico.dataNascimento.toIso8601String(),
      }).select().single();

      final novoIdMedico = response['id'];

      if (medico.planos.isNotEmpty) {
        await _vincularPlanos(novoIdMedico, medico.planos);
      }
      
    } catch (e) {
      throw Exception('Erro ao criar médico: $e');
    }
  }

  Future<List<MedicoModel>> getMedicos() async {
    try {
      final response = await _client
          .from('medicos')
          .select('*, planos(*)'); 

      final data = response as List<dynamic>;
      return data.map((json) => MedicoModel.fromJson(json)).toList();
      
    } catch (e) {
      throw Exception('Erro ao buscar médicos: $e');
    }
  }

  Future<void> atualizarMedico(MedicoModel medico) async {
    if (medico.id == null) throw Exception('ID é obrigatório para atualização');

    try {
      await _client.from('medicos').update({
        'nome': medico.nome,
        'crm': medico.crm,
        'cpf': medico.cpf,
        'data_nascimento': medico.dataNascimento.toIso8601String(),
      }).eq('id', medico.id!);

      await _client.from('medico_planos').delete().eq('medico_id', medico.id!);
      
      if (medico.planos.isNotEmpty) {
        await _vincularPlanos(medico.id!, medico.planos);
      }

    } catch (e) {
      throw Exception('Erro ao atualizar médico: $e');
    }
  }

  Future<void> deletarMedico(String id) async {
    try {
      await _client.from('medicos').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar médico: $e');
    }
  }

  Future<void> _vincularPlanos(String medicoId, List<PlanoModel> planos) async {
    final listaParaInserir = planos.map((plano) {
      return {
        'medico_id': medicoId,
        'plano_id': plano.id,
      };
    }).toList();

    await _client.from('medico_planos').insert(listaParaInserir);
  }
}

final medicoRepositoryProvider = Provider<MedicoRepository>((ref) {
  return MedicoRepository();
});