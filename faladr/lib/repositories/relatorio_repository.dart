import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/dio_provider.dart'; 
import 'package:faladr_shared/relatorio_model.dart';

final relatorioRepositoryProvider = Provider<RelatorioRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return RelatorioRepository(dio);
});

class RelatorioRepository {
  final Dio _dio;

  RelatorioRepository(this._dio);

  Future<void> salvar(RelatorioModel relatorio) async {
    try {
      await _dio.post(
        '/relatorios',
        data: relatorio.toMap(),
      );
    } on DioException catch (e) {
      throw Exception('Erro de conexão ao salvar relatório: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao salvar relatório: $e');
    }
  }
}