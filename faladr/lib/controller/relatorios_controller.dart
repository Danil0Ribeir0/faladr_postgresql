import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/paciente_repository.dart';
import '../repositories/medico_repository.dart';
import '../repositories/consulta_repository.dart';
import '../repositories/relatorio_repository.dart';
import 'package:faladr_shared/relatorio_model.dart';

class RelatoriosState {
  final Map<String, int> pacientesPorPlano;
  final Map<String, int> pacientesPorFaixaEtaria;
  final Map<String, int> medicosPorPlano;
  final Map<String, int> medicosPorFaixaEtaria;
  final Map<String, int> medicosPorEstado;
  final Map<String, int> consultasPorMedico;
  final Map<String, int> consultasPorPaciente;
  final Map<String, int> consultasPorPlano;
  final bool isLoading;
  final String? error;

  RelatoriosState({
    this.pacientesPorPlano = const {},
    this.pacientesPorFaixaEtaria = const {},
    this.medicosPorPlano = const {},
    this.medicosPorFaixaEtaria = const {},
    this.medicosPorEstado = const {},
    this.consultasPorMedico = const {},
    this.consultasPorPaciente = const {},
    this.consultasPorPlano = const {},
    this.isLoading = true,
    this.error,
  });

  RelatoriosState copyWith({
    Map<String, int>? pacientesPorPlano,
    Map<String, int>? pacientesPorFaixaEtaria,
    Map<String, int>? medicosPorPlano,
    Map<String, int>? medicosPorFaixaEtaria,
    Map<String, int>? medicosPorEstado,
    Map<String, int>? consultasPorMedico,
    Map<String, int>? consultasPorPaciente,
    Map<String, int>? consultasPorPlano,
    bool? isLoading,
    String? error,
  }) {
    return RelatoriosState(
      pacientesPorPlano: pacientesPorPlano ?? this.pacientesPorPlano,
      pacientesPorFaixaEtaria: pacientesPorFaixaEtaria ?? this.pacientesPorFaixaEtaria,
      medicosPorPlano: medicosPorPlano ?? this.medicosPorPlano,
      medicosPorFaixaEtaria: medicosPorFaixaEtaria ?? this.medicosPorFaixaEtaria,
      medicosPorEstado: medicosPorEstado ?? this.medicosPorEstado,
      consultasPorMedico: consultasPorMedico ?? this.consultasPorMedico,
      consultasPorPaciente: consultasPorPaciente ?? this.consultasPorPaciente,
      consultasPorPlano: consultasPorPlano ?? this.consultasPorPlano,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final relatoriosControllerProvider = StateNotifierProvider<RelatoriosController, RelatoriosState>((ref) {
  return RelatoriosController(ref);
});

class RelatoriosController extends StateNotifier<RelatoriosState> {
  final Ref ref;

  RelatoriosController(this.ref) : super(RelatoriosState()) {
    carregarAgregacoes();
  }

  Future<void> carregarAgregacoes() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final pacientes = await ref.read(pacienteRepositoryProvider).getPacientes();
      final medicos = await ref.read(medicoRepositoryProvider).getMedicos();
      final consultas = await ref.read(consultaRepositoryProvider).getConsultas();

      final Map<String, int> aggPacientesPlano = {};
      final Map<String, int> aggPacientesFaixaEtaria = {};
      final Map<String, int> aggMedicosPlano = {};
      final Map<String, int> aggMedicosFaixaEtaria = {};
      final Map<String, int> aggMedicosEstado = {};
      final Map<String, int> aggConsultasMedico = {};
      final Map<String, int> aggConsultasPaciente = {};
      final Map<String, int> aggConsultasPlano = {};

      for (var paciente in pacientes) {
        final nomePlano = paciente.plano.nome;
        aggPacientesPlano[nomePlano] = (aggPacientesPlano[nomePlano] ?? 0) + 1;
         
        final faixa = _calcularFaixaEtaria(paciente.dataNascimento);
        aggPacientesFaixaEtaria[faixa] = (aggPacientesFaixaEtaria[faixa] ?? 0) + 1;
      }

      for (var medico in medicos) {
        for (var plano in medico.planos) {
            final nomePlano = plano.nome; 
            aggMedicosPlano[nomePlano] = (aggMedicosPlano[nomePlano] ?? 0) + 1;
        }

        final faixa = _calcularFaixaEtaria(medico.dataNascimento);
        aggMedicosFaixaEtaria[faixa] = (aggMedicosFaixaEtaria[faixa] ?? 0) + 1;   

        final estado = _extrairEstadoDoCRM(medico.crm);
        aggMedicosEstado[estado] = (aggMedicosEstado[estado] ?? 0) + 1;     
      }

      for (var consulta in consultas) {
        final nomeMedico = consulta.medico?.nome ?? 'Médico Desconhecido';
        aggConsultasMedico[nomeMedico] = (aggConsultasMedico[nomeMedico] ?? 0) + 1;

        final nomePaciente = consulta.paciente?.nome ?? 'Paciente Desconhecido';
        aggConsultasPaciente[nomePaciente] = (aggConsultasPaciente[nomePaciente] ?? 0) + 1;

        final nomePlano = consulta.plano?.nome ?? 'Particular';
        aggConsultasPlano[nomePlano] = (aggConsultasPlano[nomePlano] ?? 0) + 1;
      }

      state = state.copyWith(
        isLoading: false,
        pacientesPorPlano: aggPacientesPlano,
        pacientesPorFaixaEtaria: aggPacientesFaixaEtaria,
        medicosPorPlano: aggMedicosPlano,
        medicosPorFaixaEtaria: aggMedicosFaixaEtaria,
        medicosPorEstado: aggMedicosEstado,
        consultasPorMedico: aggConsultasMedico,
        consultasPorPaciente: aggConsultasPaciente,
        consultasPorPlano: aggConsultasPlano,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  String _calcularFaixaEtaria(DateTime? dataNascimento) {
    if (dataNascimento == null) return 'Desconhecida';
    final idade = DateTime.now().year - dataNascimento.year;
    if (idade < 18) return '0-17';
    if (idade < 30) return '18-29';
    if (idade < 50) return '30-49';
    if (idade < 65) return '50-64';
    return '65+';
  }

  String _extrairEstadoDoCRM(String crm) {
    if (crm.isEmpty || !crm.contains('/')) {
      return 'Não informado';
    }
    
    final partes = crm.split('/');
    if (partes.length == 2) {
      return partes[1].trim().toUpperCase(); 
    }
    
    return 'Formato Inválido';
  }

  Future<void> salvarSnapshotRelatorio() async {
    try {
      final repository = ref.read(relatorioRepositoryProvider);
      
      final dataAtual = DateTime.now();

      final dia = dataAtual.day.toString().padLeft(2, '0');
      final mes = dataAtual.month.toString().padLeft(2, '0');
      final ano = dataAtual.year;
      final hora = dataAtual.hour.toString().padLeft(2, '0');
      final minuto = dataAtual.minute.toString().padLeft(2, '0');
      
      final tituloDinamico = 'Fechamento Consolidado - $dia/$mes/$ano às $hora:$minuto';

      final relatorio = RelatorioModel(
        titulo: tituloDinamico, 
        tipo: 'MANUAL',
        dataGeracao: dataAtual,
        dados: {
          'pacientes': {
            'porPlano': state.pacientesPorPlano,
            'porFaixaEtaria': state.pacientesPorFaixaEtaria,
          },
          'medicos': {
            'porEstado': state.medicosPorEstado,
            'porFaixaEtaria': state.medicosPorFaixaEtaria,
            'porPlano': state.medicosPorPlano,
          },
          'consultas': {
            'porMedico': state.consultasPorMedico,
            'porPaciente': state.consultasPorPaciente,
            'porPlano': state.consultasPorPlano,
          }
        },
      );

      await repository.salvar(relatorio);
      
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

