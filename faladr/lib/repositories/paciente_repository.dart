import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faladr_shared/faladr_shared.dart';
import '../core/api_config.dart';

class PacienteRepository {
  final _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  Future<void> criarPaciente(PacienteModel paciente) async {
    try {
      final response = await _dio.post(
        '/pacientes',
        data: paciente.toMap(),
      );
      
      if (response.statusCode != 201) {
        throw Exception('Erro ao cadastrar paciente');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('CPF já cadastrado.');
      }
      throw Exception('Erro de rede ao cadastrar: ${e.message}');
    }
  }

  Future<List<PacienteModel>> getPacientes() async {
    try {
      final response = await _dio.get('/pacientes');
      
      if (response.statusCode == 200) {
        final data = response.data as List;
        return data.map((json) => PacienteModel.fromMap(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Erro ao buscar pacientes: ${e.message}');
    }
  }

  Future<void> atualizarPaciente(PacienteModel paciente) async {
    if (paciente.id == null) throw Exception('ID necessário para atualizar');

    try {
      final response = await _dio.put(
        '/pacientes/${paciente.id}',
        data: paciente.toMap(),
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao atualizar paciente');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Paciente não encontrado no banco.');
      }
      if (e.response?.statusCode == 409) {
        throw Exception('Este CPF já está a ser utilizado por outro paciente.');
      }
      throw Exception('Erro de rede ao atualizar: ${e.message}');
    }
  }

  Future<void> deletarPaciente(String id) async {
    try {
      final response = await _dio.delete('/pacientes/$id');
      
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Erro ao deletar paciente');
      }
    } on DioException catch (e) {
      throw Exception('Erro de rede ao deletar: ${e.message}');
    }
  }
}

final pacienteRepositoryProvider = Provider<PacienteRepository>((ref) {
  return PacienteRepository();
});