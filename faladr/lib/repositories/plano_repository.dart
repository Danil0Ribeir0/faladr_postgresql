import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faladr_shared/faladr_shared.dart';
import '../core/dio_provider.dart';
import '../core/exceptions/repository_error_handler.dart';

class PlanoRepository with RepositoryErrorHandler {
  final Dio _dio;

  PlanoRepository(this._dio);

  Future<List<PlanoModel>> getPlanos() async {
    try {
      final response = await _dio.get('/planos');
      
      if (response.statusCode == 200) {
        final data = response.data as List;
        return data.map((json) => PlanoModel.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      handleError(e, 'Erro ao buscar planos');
    }
  }

  Future<void> criarPlano(PlanoModel plano) async {
    try {
      await _dio.post('/planos', data: plano.toMap());
    } catch (e) {
      handleError(e, 'Erro ao criar plano');
    }
  }

  Future<void> atualizarPlano(PlanoModel plano) async {
    if (plano.id == null) throw Exception('ID necessário para atualizar');
    try {
      await _dio.put('/planos/${plano.id}', data: plano.toMap());
    } catch (e) {
      handleError(e, 'Erro ao atualizar plano');
    }
  }

  Future<void> deletarPlano(String id) async {
    try {
      await _dio.delete('/planos/$id');
    } catch (e) {
      handleError(e, 'Erro ao deletar plano');
    }
  }
}

final planoRepositoryProvider = Provider<PlanoRepository>((ref) {
  return PlanoRepository(ref.watch(dioProvider));
});