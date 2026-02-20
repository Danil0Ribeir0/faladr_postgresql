import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:faladr_shared/faladr_shared.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = context.read<Connection>();
  final method = context.request.method;

  if (method == HttpMethod.get) {
    try {
      final result = await db.execute('''
        SELECT 
          p.id, 
          p.nome, 
          p.ativo,
          -- CORREÇÃO: Agora contamos a partir da tabela intermediária medico_planos!
          (SELECT COUNT(*) FROM medico_planos mp WHERE mp.plano_id = p.id) as quantidade_medicos,
          (SELECT COUNT(*) FROM pacientes pac WHERE pac.plano_id = p.id) as quantidade_pacientes
        FROM planos p 
        ORDER BY p.nome ASC
      ''');
      
      final planos = result.map((row) {
        return {
          'id': row[0].toString(),
          'nome': row[1].toString(),
          'ativo': row[2] as bool? ?? true,
          'quantidade_medicos': row[3] as int? ?? 0,
          'quantidade_pacientes': row[4] as int? ?? 0,
        };
      }).toList();

      return Response.json(body: planos);
    } catch (e) {
      return Response.json(statusCode: 500, body: {'error': 'Erro ao buscar planos: $e'});
    }
  }

  if (method == HttpMethod.post) {
    try {
      final json = await context.request.json() as Map<String, dynamic>;
      final plano = PlanoModel.fromMap(json);

      await db.execute(
        r'INSERT INTO planos (nome, ativo) VALUES ($1, $2)',
        parameters: [plano.nome, plano.ativo],
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