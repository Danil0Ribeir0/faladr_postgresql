import 'package:dio/dio.dart';
import 'repository_exception.dart';

export 'repository_exception.dart';

mixin RepositoryErrorHandler {
  Never handleError(Object e, String defaultMessage) {
    if (e is DioException) {
      final data = e.response?.data;

      if (data is Map && data['error'] != null) {
        throw RepositoryException(data['error'].toString());
      }
      throw RepositoryException('$defaultMessage: ${e.message}');
    }
    throw RepositoryException('Erro inesperado: $e');
  }
}