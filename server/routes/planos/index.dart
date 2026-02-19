import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:faladr_shared/faladr_shared.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = context.read<Connection>();
  final method = context.request.method;

  // --- GET: Listar Todos os Planos ---
  if (method == HttpMethod.get) {
    try {
      final result = await db.execute('SELECT id, nome FROM planos ORDER BY nome ASC');
      
      final planos = result.map((row) {
        return PlanoModel(
          id: row[0].toString(),
          nome: row[1].toString(),
        ).toMap();
      }).toList();

      return Response.json(body: planos);
    } catch (e) {
      return Response.json(statusCode: 500, body: {'error': 'Erro ao buscar planos: $e'});
    }
  }

  // --- POST: Criar Novo Plano ---
  if (method == HttpMethod.post) {
    try {
      final json = await context.request.json() as Map<String, dynamic>;
      final plano = PlanoModel.fromMap(json);

      await db.execute(
        r'INSERT INTO planos (nome) VALUES ($1)',
        parameters: [plano.nome],
      );

      return Response.json(
        statusCode: 201, 
        body: {'message': 'Plano criado com sucesso!'}
      );
    } catch (e) {
      return Response.json(statusCode: 400, body: {'error': 'Erro ao salvar plano: $e'});
    }
  }

  return Response(statusCode: 405);
}