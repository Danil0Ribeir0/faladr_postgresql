import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final connection = context.read<Connection>();
  final method = context.request.method;

  if (method == HttpMethod.put) {
    return await _updateConsulta(context, id, connection);
  } else if (method == HttpMethod.delete) {
    return await _deleteConsulta(id, connection);
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}

Future<Response> _updateConsulta(RequestContext context, String id, Connection connection) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    
    final result = await connection.execute(
      Sql.named('''
        UPDATE consultas
        SET plano_id = @plano_id,
            paciente_id = @paciente_id,
            medico_id = @medico_id,
            data_hora = @data_hora,
            status = @status,
            observacoes = @observacoes
        WHERE id = @id
        RETURNING *
      '''),
      parameters: {
        'id': id,
        'plano_id': body['plano_id'] ?? body['planoId'], 
        'paciente_id': body['paciente_id'] ?? body['pacienteId'],
        'medico_id': body['medico_id'] ?? body['medicoId'],
        'data_hora': body['data_hora'] ?? body['dataHora'],
        'status': body['status'],
        'observacoes': body['observacoes'],
      },
    );

    if (result.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound, 
        body: {'error': 'Consulta não encontrada para atualização'}
      );
    }

    final rawRow = result.first.toColumnMap();
    
    final Map<String, dynamic> safeRow = {};

    for (final entry in rawRow.entries) {
      if (entry.value is DateTime) {
        safeRow[entry.key] = (entry.value as DateTime).toIso8601String();
      } else {
        safeRow[entry.key] = entry.value;
      }
    }

    return Response.json(body: safeRow);

  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError, 
      body: {'error': 'Erro ao atualizar: $e'}
    );
  }
}

Future<Response> _deleteConsulta(String id, Connection connection) async {
  try {
    final result = await connection.execute(
      Sql.named('DELETE FROM consultas WHERE id = @id RETURNING id'),
      parameters: {'id': id},
    );

    if (result.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound, 
        body: {'error': 'Consulta não encontrada para exclusão'}
      );
    }

    return Response(statusCode: HttpStatus.noContent);
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError, 
      body: {'error': 'Erro ao deletar: $e'}
    );
  }
}