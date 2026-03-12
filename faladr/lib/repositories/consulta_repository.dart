import 'package:dio/dio.dart';
import 'package:faladr_shared/faladr_shared.dart';
import '../core/api_config.dart';

class ConsultaRepository {
  final Dio _dio = Dio(); 
  final String _baseUrl = '${ApiConfig.baseUrl}/consultas';

  Future<List<ConsultaModel>> buscarConsultas() async {
    try {
      final response = await _dio.get(_baseUrl);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = response.data;
        return jsonData.map((item) => ConsultaModel.fromMap(item)).toList();
      } else {
        throw Exception('Falha ao carregar as consultas. Código: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Erro de ligação: ${e.message}');
    } catch (e) {
      throw Exception('Erro desconhecido: $e');
    }
  }

  Future<bool> criarConsulta(ConsultaModel consulta) async {
    try {
      final response = await _dio.post(
        _baseUrl,
        data: consulta.toMap(), 
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } on DioException catch (e) {
      final erro = e.response?.data['error'] ?? 'Erro desconhecido';
      throw Exception(erro);
    } catch (e) {
      throw Exception('Erro ao agendar consulta: $e');
    }
  }
}