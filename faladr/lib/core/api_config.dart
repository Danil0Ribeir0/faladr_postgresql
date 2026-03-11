import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _meuIpLocal = '192.168.199.236'; 
  static const String _porta = '8080';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:$_porta';
    }
    
    return 'http://$_meuIpLocal:$_porta'; 
  }

  static String get medicos => '$baseUrl/medicos';
  static String get pacientes => '$baseUrl/pacientes';
  static String get planos => '$baseUrl/planos';
}