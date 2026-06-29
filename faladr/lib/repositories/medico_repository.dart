import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faladr_shared/faladr_shared.dart';
import '../core/dio_provider.dart';
import '../core/exceptions/repository_error_handler.dart';

class MedicoRepository with RepositoryErrorHandler{
  final Dio _dio;

  MedicoRepository(this._dio);

  Future<void> criarMedico(MedicoModel medico) async {
    try {
      await _dio.post('/medicos', data: medico.toMap());
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw RepositoryException('Já existe um médico cadastrado com este CPF ou CRM. Verifique os dados.');
      }
      handleError(e, 'Erro ao cadastrar médico');
    } catch (e) {
      handleError(e, 'Erro inesperado ao cadastrar médico');
    }
  }

  Future<List<MedicoModel>> getMedicos() async {
    try {
      final response = await _dio.get('/medicos');
      
      if (response.data != null) {
        final data = response.data as List;
        return data.map((json) => MedicoModel.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      handleError(e, 'Erro ao buscar a lista de médicos');
    }
  }

  Future<void> atualizarMedico(MedicoModel medico) async {
    if (medico.id == null) throw RepositoryException('ID é obrigatório para atualização');

    try {
      await _dio.put(
        '/medicos/${medico.id}',
        data: medico.toMap(),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw RepositoryException('Registro não encontrado.');
      }
      if (e.response?.statusCode == 409) {
        throw RepositoryException('Já existe um médico cadastrado com este CPF ou CRM. Verifique os dados.');
      }
      handleError(e, 'Erro ao atualizar médico');
    } catch (e) {
      handleError(e, 'Erro inesperado ao atuaizar médico');
    }
  }

  Future<void> deletarMedico(String id) async {
    try {
      await _dio.delete('/medicos/$id');
    } catch (e) {
      handleError(e, 'Erro ao deletar médico');
    }
  }
}

final medicoRepositoryProvider = Provider<MedicoRepository>((ref) { 
  return MedicoRepository(ref.watch(dioProvider));
});