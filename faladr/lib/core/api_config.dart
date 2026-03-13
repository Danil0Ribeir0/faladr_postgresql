import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl => dotenv.env['API_URL'] ?? 'http://localhost:8080';

  static String get medicos => '$baseUrl/medicos';
  static String get pacientes => '$baseUrl/pacientes';
  static String get planos => '$baseUrl/planos';
}