import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:faladr_shared/faladr_shared.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final db = context.read<Connection>();
  final method = context.request.method;

  if (method == HttpMethod.put) {
    try {
      final json = await context.request.json() as Map<String, dynamic>;
      final medico = MedicoModel.fromMap(json);

      if (medico.planos.length > 3) {
        return Response.json(
          statusCode: 400, 
          body: {'error': 'Limite excedido: Máximo de 3 planos por médico.'}
        );
      }

      await db.runTx((session) async {
        final result = await session.execute(
          r'''
            UPDATE medicos 
            SET nome = $1, crm = $2, cpf = $3, data_nascimento = $4 
            WHERE id = $5 RETURNING id
          ''',
          parameters: [medico.nome, medico.crm, medico.cpf, medico.dataNascimento, id],
        );

        if (result.isEmpty) {
          throw Exception('MEDICO_NAO_ENCONTRADO');
        }

        await session.execute(
          r'DELETE FROM medico_planos WHERE medico_id = $1',
          parameters: [id],
        );

        for (var plano in medico.planos) {
          if (plano.id != null) {
            await session.execute(
              r'INSERT INTO medico_planos (medico_id, plano_id) VALUES ($1, $2)',
              parameters: [id, plano.id],
            );
          }
        }
      });

      return Response.json(body: {'message': 'Médico atualizado com sucesso!'});
    } catch (e) {
      if (e.toString() == 'Exception: MEDICO_NAO_ENCONTRADO') {
        return Response.json(statusCode: 404, body: {'error': 'Médico não encontrado.'});
      }
      if (e.toString().contains('unique constraint')) {
        return Response.json(statusCode: 409, body: {'error': 'CRM ou CPF já cadastrado por outro médico.'});
      }
      return Response.json(statusCode: 400, body: {'error': 'Erro ao atualizar médico: $e'});
    }
  }

  if (method == HttpMethod.delete) {
    try {
      final result = await db.execute(
        r'DELETE FROM medicos WHERE id = $1 RETURNING id',
        parameters: [id],
      );

      if (result.isEmpty) {
        return Response.json(statusCode: 404, body: {'error': 'Médico não encontrado.'});
      }

      return Response(statusCode: 204); 
    } catch (e) {
      return Response.json(statusCode: 400, body: {'error': 'Erro ao excluir médico: $e'});
    }
  }

  return Response(statusCode: 405);
}