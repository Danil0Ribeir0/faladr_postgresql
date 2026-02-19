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
          p.id, p.nome, p.cpf, p.data_nascimento,
          pl.id as plano_id, pl.nome as plano_nome
        FROM pacientes p
        LEFT JOIN planos pl ON p.plano_id = pl.id
      ''');

      final listaPacientes = result.map((row) {
        return PacienteModel.fromMap({
          'id': row[0],
          'nome': row[1],
          'cpf': row[2],
          'data_nascimento': row[3].toString(),
          'plano': row[4] != null ? {'id': row[4], 'nome': row[5]} : null,
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

      await db.execute(
        r'INSERT INTO pacientes (nome, cpf, data_nascimento, plano_id) VALUES ($1, $2, $3, $4)',
        parameters: [
          paciente.nome,
          paciente.cpf,
          paciente.dataNascimento,
          paciente.plano?.id,
        ],
      );

      return Response.json(
        statusCode: 201, 
        body: {'message': 'Paciente cadastrado com sucesso!'}
      );

    } catch (e) {
      if (e.toString().contains('unique constraint')) {
        return Response.json(statusCode: 409, body: {'error': 'CPF já cadastrado.'});
      }
      return Response.json(statusCode: 400, body: {'error': 'Erro ao salvar: $e'});
    }
  }

  return Response(statusCode: 405);
}