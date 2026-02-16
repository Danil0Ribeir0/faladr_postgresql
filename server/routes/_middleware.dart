import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

final env = DotEnv(includePlatformEnvironment: true)..load();

Connection? _db;

Handler middleware(Handler handler) {
  return (context) async {
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

    return handler(
      context.provide<Connection>(() => _db!),
    );
  };
}