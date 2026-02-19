import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:faladr_shared/faladr_shared.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final db = context.read<Connection>();
  final method = context.request.method;

  if (method == HttpMethod.put) {
    try {
      final json = await context.request.json() as Map<String, dynamic>;
      final paciente = PacienteModel.fromMap(json);

      final result = await db.execute(
        r'''
          UPDATE pacientes 
          SET nome = $1, cpf = $2, data_nascimento = $3, plano_id = $4 
          WHERE id = $5 RETURNING id
        ''',
        parameters: [
          paciente.nome,
          paciente.cpf,
          paciente.dataNascimento,
          paciente.plano.id,
          id
        ],
      );

      if (result.isEmpty) {
        return Response.json(statusCode: 404, body: {'error': 'Paciente não encontrado.'});
      }

      return Response.json(body: {'message': 'Paciente atualizado com sucesso!'});
    } catch (e) {
      if (e.toString().contains('unique constraint')) {
        return Response.json(statusCode: 409, body: {'error': 'CPF já cadastrado por outro paciente.'});
      }
      return Response.json(statusCode: 400, body: {'error': 'Erro ao atualizar: $e'});
    }
  }

  if (method == HttpMethod.delete) {
    try {
      final result = await db.execute(
        r'DELETE FROM pacientes WHERE id = $1 RETURNING id',
        parameters: [id],
      );

      if (result.isEmpty) {
        return Response.json(statusCode: 404, body: {'error': 'Paciente não encontrado.'});
      }

      return Response(statusCode: 204); 
    } catch (e) {
      return Response.json(statusCode: 400, body: {'error': 'Erro ao excluir: $e'});
    }
  }

  return Response(statusCode: 405);
}