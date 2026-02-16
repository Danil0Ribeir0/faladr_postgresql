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
          p.id, 
          p.nome, 
          p.cpf, 
          p.data_nascimento,
          COALESCE(
            json_agg(
              json_build_object('id', pl.id, 'nome', pl.nome)
            ) FILTER (WHERE pl.id IS NOT NULL), 
            '[]'
          ) as planos
        FROM pacientes p
        LEFT JOIN paciente_planos pp ON p.id = pp.paciente_id
        LEFT JOIN planos pl ON pp.plano_id = pl.id
        GROUP BY p.id, p.nome, p.cpf, p.data_nascimento
      ''');

      final listaPacientes = result.map((row) {
        return PacienteModel.fromMap({
          'id': row[0],
          'nome': row[1],
          'cpf': row[2],
          'data_nascimento': row[3].toString(),
          'planos': row[4],
        });
      }).toList();

      return Response.json(body: listaPacientes.map((p) => p.toMap()).toList());
    } catch (e) {
      return Response.json(statusCode: 500, body: {'error': 'Erro ao buscar: $e'});
    }
  }

  if (method == HttpMethod.post) {
    try {
      final json = await context.request.json() as Map<String, dynamic>;
      final paciente = PacienteModel.fromMap(json);

      if (paciente.planos.length > 3) {
        return Response.json(
          statusCode: 400, 
          body: {'error': 'Limite excedido: Máximo de 3 planos por paciente.'}
        );
      }

      await db.runTx((session) async {
        final result = await session.execute(
          r'INSERT INTO pacientes (nome, cpf, data_nascimento) VALUES ($1, $2, $3) RETURNING id',
          parameters: [
            paciente.nome,
            paciente.cpf,
            paciente.dataNascimento,
          ],
        );

        final novoId = result.first[0];

        for (var plano in paciente.planos) {
          if (plano.id != null) {
            await session.execute(
              r'INSERT INTO paciente_planos (paciente_id, plano_id) VALUES ($1, $2)',
              parameters: [novoId, plano.id],
            );
          }
        }
      });

      return Response.json(
        statusCode: 201, 
        body: {'message': 'Paciente cadastrado com sucesso!'}
      );

    } catch (e) {
      if (e.toString().contains('unique constraint')) {
        return Response.json(
          statusCode: 409,
          body: {'error': 'CPF já cadastrado.'}
        );
      }
      return Response.json(
        statusCode: 400, 
        body: {'error': 'Erro ao salvar: $e'}
      );
    }
  }

  return Response(statusCode: 405);
}