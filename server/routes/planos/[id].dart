import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:faladr_shared/faladr_shared.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final db = context.read<Connection>();
  final method = context.request.method;

  if (method == HttpMethod.put) {
    try {
      final json = await context.request.json() as Map<String, dynamic>;
      final plano = PlanoModel.fromMap(json);

      final result = await db.execute(
        r'UPDATE planos SET nome = $1 WHERE id = $2 RETURNING id',
        parameters: [plano.nome, id],
      );

      if (result.isEmpty) {
        return Response.json(statusCode: 404, body: {'error': 'Plano não encontrado.'});
      }

      return Response.json(body: {'message': 'Plano atualizado com sucesso!'});
    } catch (e) {
      return Response.json(statusCode: 400, body: {'error': 'Erro ao atualizar plano: $e'});
    }
  }

  if (method == HttpMethod.delete) {
    try {
      final result = await db.execute(
        r'DELETE FROM planos WHERE id = $1 RETURNING id',
        parameters: [id],
      );

      if (result.isEmpty) {
        return Response.json(statusCode: 404, body: {'error': 'Plano não encontrado.'});
      }

      return Response(statusCode: 204); 
    } catch (e) {
      return Response.json(statusCode: 400, body: {'error': 'Erro ao excluir plano: $e'});
    }
  }

  return Response(statusCode: 405);
}