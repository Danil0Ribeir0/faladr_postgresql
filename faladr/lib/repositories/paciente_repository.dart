import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faladr_shared/faladr_shared.dart';
import '../core/dio_provider.dart';
import '../core/exceptions/repository_error_handler.dart';

class PacienteRepository with RepositoryErrorHandler{
  final Dio _dio;

  PacienteRepository(this._dio);

  Future<void> criarPaciente(PacienteModel paciente) async {
    try {
      await _dio.post('/pacientes', data: paciente.toMap());
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('CPF já cadastrado.');
      }
      handleError(e, 'Erro ao cadastrar paciente');
    } catch (e) {
      handleError(e, 'Erro inesperado ao cadastrar paciente');
    }
  }

  Future<List<PacienteModel>> getPacientes() async {
    try {
      final response = await _dio.get('/pacientes');
      
      if (response.data != null) {
        final data = response.data as List;
        return data.map((json) => PacienteModel.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      handleError(e, 'Erro ao buscar a lista de pacientes');
    }
  }

  Future<void> atualizarPaciente(PacienteModel paciente) async {
    if (paciente.id == null) throw RepositoryException('ID necessário para atualizar');

    try {
      await _dio.put(
        '/pacientes/${paciente.id}',
        data: paciente.toMap(),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Paciente não encontrado no banco.');
      }
      if (e.response?.statusCode == 409) {
        throw Exception('Este CPF já está a ser utilizado por outro paciente.');
      }
      handleError(e, 'Erro ao atualizar paciente');
    } catch (e) {
      handleError(e, 'Erro inesperado ao atualizar paciente');
    }
  }

  Future<void> deletarPaciente(String id) async {
    try {
      await _dio.delete('/pacientes/$id');
    } catch (e) {
      handleError(e, 'Erro ao deletar paciente');
    }
  }
}

final pacienteRepositoryProvider = Provider<PacienteRepository>((ref) { 
  return PacienteRepository(ref.watch(dioProvider));
});