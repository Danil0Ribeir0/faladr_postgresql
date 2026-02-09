import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faladr_shared/faladr_shared.dart';

class PlanoRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<PlanoModel>> getPlanos() async {
    try {
      final response = await _client
          .from('planos')
          .select()
          .order('nome', ascending: true);

      final data = response as List<dynamic>;
      return data.map((json) => PlanoModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar lista de planos: $e');
    }
  }
}

final planoRepositoryProvider = Provider<PlanoRepository>((ref) {
  return PlanoRepository();
});