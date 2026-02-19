import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

final env = DotEnv(includePlatformEnvironment: true)..load();

Connection? _db;

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
};

Handler middleware(Handler handler) {
  return (context) async {
    if (context.request.method == HttpMethod.options) {
      return Response(statusCode: 204, headers: _corsHeaders);
    }

    if (_db == null || !_db!.isOpen) {
      _db = await Connection.open(
        Endpoint(
          host: env['DB_HOST'] ?? 'localhost',
          database: env['DB_DATABASE'] ?? 'faladr_db',
          username: env['DB_USERNAME'] ?? 'postgres',
          password: env['DB_PASSWORD'],
        ),
        settings: const ConnectionSettings(sslMode: SslMode.disable),
      );
    }

    final response = await handler(
      context.provide<Connection>(() => _db!),
    );

    return response.copyWith(
      headers: {
        ...response.headers,
        ..._corsHeaders,
      },
    );
  };
}