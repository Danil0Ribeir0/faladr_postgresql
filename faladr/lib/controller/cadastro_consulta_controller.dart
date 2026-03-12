import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faladr_shared/faladr_shared.dart';

final formPlanoProvider = StateProvider<PlanoModel?>((ref) => null);
final formPacienteProvider = StateProvider<PacienteModel?>((ref) => null);
final formMedicoProvider = StateProvider<MedicoModel?>((ref) => null);

final formDataProvider = StateProvider<DateTime>((ref) {
  final amanha = DateTime.now().add(const Duration(days: 1));
  return DateTime(amanha.year, amanha.month, amanha.day, 8, 0);
});

final salvandoConsultaProvider = StateProvider<bool>((ref) => false);