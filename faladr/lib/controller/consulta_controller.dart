import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faladr_shared/faladr_shared.dart';
import '../repositories/consulta_repository.dart';

final listaConsultasProvider = FutureProvider<List<ConsultaModel>>((ref) async {
  final repository = ref.watch(consultaRepositoryProvider);
  
  return repository.getConsultas();
});