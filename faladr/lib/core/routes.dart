import 'package:go_router/go_router.dart';
import '../views/dashboard_page.dart';
import '../views/cadastro_medico_page.dart';
import 'package:faladr_shared/faladr_shared.dart';
import '../views/cadastro_paciente_page.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/cadastro-medico',
      builder:(context, state) {
        final medico = state.extra as MedicoModel?;
        return CadastroMedicoPage(medicoParaEditar: medico);
      }
    ),
    GoRoute(
      path: '/cadastro-paciente',
      builder:(context, state) {
        final paciente = state.extra as PacienteModel?;
        return CadastroPacientePage(pacienteParaEditar: paciente);
      }
    )
  ]
);