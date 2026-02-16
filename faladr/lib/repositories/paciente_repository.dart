import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faladr_shared/faladr_shared.dart';

class PacienteRepository {
  // Se for testar no Android Emulator, use 'http://10.0.2.2:8080'
  // Se for iOS ou Web, use 'http://localhost:8080'
  final _dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));

  // CREATE
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
      throw Exception('Erro de rede ao cadastrar: ${e.message}');
    }
  }

  // READ
  Future<List<PacienteModel>> getPacientes() async {
    try {
      final response = await _dio.get('/pacientes');
      
      if (response.statusCode == 200) {
        final data = response.data as List;
        // Usamos o fromMap que está no seu shared
        return data.map((json) => PacienteModel.fromMap(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Erro ao buscar pacientes: ${e.message}');
    }
  }

  // UPDATE
  Future<void> atualizarPaciente(PacienteModel paciente) async {
    if (paciente.id == null) throw Exception('ID necessário para atualizar');

    try {
      // Passamos o ID na URL (padrão REST)
      final response = await _dio.put(
        '/pacientes/${paciente.id}',
        data: paciente.toMap(),
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao atualizar paciente');
      }
    } on DioException catch (e) {
      throw Exception('Erro de rede ao atualizar: ${e.message}');
    }
  }

  // DELETE
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

// Provedor para o Riverpod
final pacienteRepositoryProvider = Provider<PacienteRepository>((ref) {
  return PacienteRepository();
});