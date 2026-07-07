import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.post) {
    return _salvarRelatorio(context);
  }
  return Response(statusCode: HttpStatus.methodNotAllowed);
}

Future<Response> _salvarRelatorio(RequestContext context) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    
    final connection = context.read<Connection>();
    
    final dadosJson = jsonEncode(body['dados']);

    await connection.execute(
      Sql.named('''
        INSERT INTO relatorios (titulo, tipo, data_geracao, dados) 
        VALUES (@titulo, @tipo, @data_geracao, @dados::jsonb)
      '''),
      parameters: {
        'titulo': body['titulo'],
        'tipo': body['tipo'],
        'data_geracao': body['data_geracao'],
        'dados': dadosJson,
      },
    );

    return Response.json(
      statusCode: HttpStatus.created,
      body: {'message': 'Relatório salvo com sucesso!'},
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro ao salvar relatório no banco: $e'},
    );
  }
}