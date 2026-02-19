import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:faladr_shared/faladr_shared.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = context.read<Connection>();
  final method = context.request.method;

  if (method == HttpMethod.get) {
    try {
      final result = await db.execute(r'''
        SELECT 
          m.id, m.nome, m.crm, m.cpf, m.data_nascimento,
          COALESCE(
            json_agg(
              json_build_object('id', pl.id, 'nome', pl.nome)
            ) FILTER (WHERE pl.id IS NOT NULL), 
            '[]'
          ) as planos
        FROM medicos m
        LEFT JOIN medico_planos mp ON m.id = mp.medico_id
        LEFT JOIN planos pl ON mp.plano_id = pl.id
        GROUP BY m.id, m.nome, m.crm, m.cpf, m.data_nascimento
      ''');

      final listaMedicos = result.map((row) {
        return MedicoModel.fromMap({
          'id': row[0],
          'nome': row[1],
          'crm': row[2],
          'cpf': row[3],
          'data_nascimento': row[4].toString(),
          'planos': row[5],
        });
      }).toList();

      return Response.json(body: listaMedicos.map((m) => m.toMap()).toList());
    } catch (e) {
      return Response.json(statusCode: 500, body: {'error': 'Erro ao buscar médicos: $e'});
    }
  }

  if (method == HttpMethod.post) {
    try {
      final json = await context.request.json() as Map<String, dynamic>;
      final medico = MedicoModel.fromMap(json);

      if (medico.planos.isEmpty) {
        return Response.json(
          statusCode: 400, 
          body: {'error': 'O médico deve ter pelo menos 1 plano vinculado.'}
        );
      }

      if (medico.planos.length > 3) {
        return Response.json(
          statusCode: 400, 
          body: {'error': 'Limite excedido: Máximo de 3 planos por médico.'}
        );
      }

      await db.runTx((session) async {
        final result = await session.execute(
          r'INSERT INTO medicos (nome, crm, cpf, data_nascimento) VALUES ($1, $2, $3, $4) RETURNING id',
          parameters: [medico.nome, medico.crm, medico.cpf, medico.dataNascimento],
        );

        final novoId = result.first[0];

        for (var plano in medico.planos) {
          if (plano.id != null) {
            await session.execute(
              r'INSERT INTO medico_planos (medico_id, plano_id) VALUES ($1, $2)',
              parameters: [novoId, plano.id],
            );
          }
        }
      });

      return Response.json(statusCode: 201, body: {'message': 'Médico cadastrado com sucesso!'});
    } catch (e) {
      if (e.toString().contains('unique constraint')) {
        return Response.json(statusCode: 409, body: {'error': 'CRM ou CPF já cadastrado.'});
      }
      return Response.json(statusCode: 400, body: {'error': 'Erro ao salvar médico: $e'});
    }
  }

  return Response(statusCode: 405);
}