import 'package:dio/dio.dart';
import 'package:faladr_shared/faladr_shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/dio_provider.dart';

class ConsultaRepository {
  final Dio _dio;
  
  ConsultaRepository(this._dio);

  Future<List<ConsultaModel>> buscarConsultas() async {
    try {
      final response = await _dio.get('/consultas');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = response.data;
        return jsonData.map((item) => ConsultaModel.fromMap(item)).toList();
      } else {
        throw Exception('Falha ao carregar as consultas. Código: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String mensagemErro = 'Erro de conexão';
      
      if (e.response?.data != null) {
        if (e.response!.data is Map) {
          mensagemErro = e.response!.data['error'] ?? 'Erro no servidor (500)';
        } else {
          mensagemErro = e.response!.data.toString();
          mensagemErro = mensagemErro.replaceAll('{"error":"', '').replaceAll('"}', ''); 
        }
      }
      throw Exception(mensagemErro);
    } catch (e) {
      throw Exception('Erro ao processar as consultas: $e');
    }
  }

  Future<bool> criarConsulta(ConsultaModel consulta) async {
    try {
      final response = await _dio.post(
        '/consultas',
        data: consulta.toMap(), 
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } on DioException catch (e) {
      String mensagemErro = 'Erro desconhecido';
      
      if (e.response?.data != null) {
        if (e.response!.data is Map) {
          mensagemErro = e.response!.data['error'] ?? 'Erro no servidor';
        } else {
          mensagemErro = e.response!.data.toString();
          mensagemErro = mensagemErro.replaceAll('{"error":"', '').replaceAll('"}', ''); 
        }
      }
      throw Exception(mensagemErro);
      
    } catch (e) {
      throw Exception('Erro ao agendar consulta: $e');
    }
  }
}

final consultaRepositoryProvider = Provider<ConsultaRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ConsultaRepository(dio);
});