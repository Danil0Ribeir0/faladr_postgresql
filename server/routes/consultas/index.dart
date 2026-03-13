import 'dart:convert';
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
          c.id, c.plano_id, c.medico_id, c.paciente_id, c.data_hora, c.status, c.observacoes,
          row_to_json(pl) as plano,
          row_to_json(m) as medico,
          -- A MÁGICA ACONTECE AQUI: Fundimos o JSON do Paciente com o JSON do Plano dele!
          (row_to_json(p)::jsonb || jsonb_build_object('plano', row_to_json(pl)::jsonb)) as paciente
        FROM consultas c
        JOIN planos pl ON c.plano_id = pl.id
        JOIN medicos m ON c.medico_id = m.id
        JOIN pacientes p ON c.paciente_id = p.id
        ORDER BY c.data_hora ASC
      ''');

      final listaConsultas = result.map((row) {
        dynamic parseJson(dynamic val) {
          if (val == null) return null;
          if (val is String) return jsonDecode(val);
          return val;
        }

        return ConsultaModel.fromMap({
          'id': row[0].toString(),
          'plano_id': row[1].toString(),
          'medico_id': row[2].toString(),
          'paciente_id': row[3].toString(),
          'data_hora': row[4].toString(),
          'status': row[5],
          'observacoes': row[6] ?? '',
          'plano': parseJson(row[7]),
          'medico': parseJson(row[8]),
          'paciente': parseJson(row[9]),
        });
      }).toList();

      return Response.json(body: listaConsultas.map((c) => c.toMap()).toList());
    } catch (e) {
      return Response.json(statusCode: 500, body: {'error': 'Erro ao formatar o GET: $e'});
    }
  }

  if (method == HttpMethod.post) {
    try {
      final json = await context.request.json() as Map<String, dynamic>;
      final consulta = ConsultaModel.fromMap(json);

      final validacaoPlano = await db.execute(
        r'SELECT 1 FROM medico_planos WHERE medico_id = $1::uuid AND plano_id = $2::uuid',
        parameters: [consulta.medicoId, consulta.planoId],
      );

      if (validacaoPlano.isEmpty) {
        return Response.json(
          statusCode: 400, 
          body: {'error': 'Operação não permitida. O médico selecionado não atende a este plano.'}
        );
      }

      final result = await db.execute(
        r'''
        INSERT INTO consultas (plano_id, medico_id, paciente_id, data_hora, status, observacoes) 
        VALUES ($1::uuid, $2::uuid, $3::uuid, $4, $5, $6) 
        RETURNING id
        ''',
        parameters: [
          consulta.planoId, 
          consulta.medicoId, 
          consulta.pacienteId, 
          consulta.dataHora, 
          consulta.status, 
          consulta.observacoes
        ],
      );

      return Response.json(statusCode: 201, body: {
        'message': 'Consulta agendada com sucesso!',
        'id': result.first[0].toString()
      });
      
    } catch (e) {
      return Response.json(statusCode: 400, body: {'error': 'Erro ao agendar consulta: $e'});
    }
  }

  return Response(statusCode: 405);
}