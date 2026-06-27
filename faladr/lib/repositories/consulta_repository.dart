import 'package:dio/dio.dart';
import 'package:faladr_shared/faladr_shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/dio_provider.dart';
import '../core/exceptions/repository_error_handler.dart';

class ConsultaRepository with RepositoryErrorHandler{
  final Dio _dio;
  
  ConsultaRepository(this._dio);

  Future<List<ConsultaModel>> buscarConsultas() async {
    try {
      final response = await _dio.get('/consultas');

      if (response.data != null) {
        final List<dynamic> jsonData = response.data;
        return jsonData.map((item) => ConsultaModel.fromMap(item)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw RepositoryException('Já existe uma consulta marcada para este horário. Verifique os dados.');
      }
      handleError(e, 'Erro ao carregar as consultas');
    } catch (e) {
      handleError(e, 'Erro inesperado ao carregar as consultas'); 
    }
  }

  Future<bool> criarConsulta(ConsultaModel consulta) async {
    try {
      await _dio.post('/consultas', data: consulta.toMap());

      return true;
    } catch (e) {
      handleError(e, 'Erro ao agendar consulta');
    }
  }

  Future<bool> editarConsulta(ConsultaModel consulta) async {
    try {
      await _dio.put('/consultas/${consulta.id}', data: consulta.toMap());

      return true;
    } catch (e) {
      handleError(e, 'Erro ao atualizar consulta');
    }
  }

  Future<bool> deletarConsulta(String id) async {
    try {
      await _dio.delete('/consultas/$id');

      return true;
    } catch (e) {
      handleError(e, 'Erro ao deletar consulta');
    }
  }
}

final consultaRepositoryProvider = Provider<ConsultaRepository>((ref) {
  return ConsultaRepository(ref.watch(dioProvider));
});