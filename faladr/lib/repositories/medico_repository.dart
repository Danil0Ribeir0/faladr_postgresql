import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faladr_shared/faladr_shared.dart';
import '../core/api_config.dart';

class MedicoRepository {
  final _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  Future<void> criarMedico(MedicoModel medico) async {
    try {
      final response = await _dio.post('/medicos', data: medico.toMap());
      
      if (response.statusCode != 201) {
        throw Exception('Erro ao cadastrar médico');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('CRM ou CPF já cadastrado.');
      }
      throw Exception('Erro de rede ao cadastrar médico: ${e.message}');
    }
  }

  Future<List<MedicoModel>> getMedicos() async {
    try {
      final response = await _dio.get('/medicos');
      
      if (response.statusCode == 200) {
        final data = response.data as List;
        return data.map((json) => MedicoModel.fromMap(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Erro ao buscar médicos: ${e.message}');
    }
  }

  Future<void> atualizarMedico(MedicoModel medico) async {
    if (medico.id == null) throw Exception('ID é obrigatório para atualização');

    try {
      final response = await _dio.put(
        '/medicos/${medico.id}',
        data: medico.toMap(),
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao atualizar médico');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Médico não encontrado.');
      }
      if (e.response?.statusCode == 409) {
        throw Exception('CRM ou CPF já utilizado por outro médico.');
      }
      throw Exception('Erro de rede ao atualizar médico: ${e.message}');
    }
  }

  Future<void> deletarMedico(String id) async {
    try {
      final response = await _dio.delete('/medicos/$id');
      
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Erro ao deletar médico');
      }
    } on DioException catch (e) {
      throw Exception('Erro de rede ao deletar médico: ${e.message}');
    }
  }
}

final medicoRepositoryProvider = Provider<MedicoRepository>((ref) {
  return MedicoRepository();
});