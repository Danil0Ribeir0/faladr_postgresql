import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faladr_shared/faladr_shared.dart';
import '../core/api_config.dart';

class PlanoRepository {
  final _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  Future<List<PlanoModel>> getPlanos() async {
    try {
      final response = await _dio.get('/planos');
      
      if (response.statusCode == 200) {
        final data = response.data as List;
        return data.map((json) => PlanoModel.fromMap(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Erro ao buscar planos: ${e.message}');
    }
  }

  Future<void> criarPlano(PlanoModel plano) async {
    try {
      final response = await _dio.post('/planos', data: plano.toMap());
      if (response.statusCode != 201) throw Exception('Erro ao criar plano');
    } on DioException catch (e) {
      throw Exception('Erro de rede: ${e.message}');
    }
  }

  Future<void> atualizarPlano(PlanoModel plano) async {
    if (plano.id == null) throw Exception('ID necessário para atualizar');
    try {
      final response = await _dio.put('/planos/${plano.id}', data: plano.toMap());
      if (response.statusCode != 200) throw Exception('Erro ao atualizar plano');
    } on DioException catch (e) {
      throw Exception('Erro de rede: ${e.message}');
    }
  }

  Future<void> deletarPlano(String id) async {
    try {
      final response = await _dio.delete('/planos/$id');
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Erro ao deletar plano');
      }
    } on DioException catch (e) {
      throw Exception('Erro de rede: ${e.message}');
    }
  }
}

final planoRepositoryProvider = Provider<PlanoRepository>((ref) {
  return PlanoRepository();
});