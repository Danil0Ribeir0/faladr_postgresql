import 'package:google_fonts/google_fonts.dart';
import 'package:faladr/views/cadastro_paciente_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/medico_controller.dart';
import '../controller/paciente_controller.dart';
import '../views/cadastro_medico_page.dart';

enum TipoVisualizacao {medicos, pacientes}

class VisualizacaoNotifier extends Notifier<TipoVisualizacao> {
  @override
  TipoVisualizacao build() {
    return TipoVisualizacao.medicos;
  }

  void trocarPara(TipoVisualizacao novoTipo) {
    state = novoTipo;
  }
}

final tipoVisualizacaoProvider =
    NotifierProvider<VisualizacaoNotifier, TipoVisualizacao>(() {
  return VisualizacaoNotifier();
});

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipoAtual = ref.watch(tipoVisualizacaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Fala Doutor!',
          style: GoogleFonts.montserrat(
            color: Colors.teal,
            fontSize: 30.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            ),
          ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SegmentedButton<TipoVisualizacao>(
              segments: const [
                ButtonSegment(
                  value: TipoVisualizacao.medicos,
                  label: Text('Médicos'),
                  icon: Icon(Icons.medical_services),
                ),
                ButtonSegment(
                  value: TipoVisualizacao.pacientes,
                  label: Text('Pacientes'),
                  icon: Icon(Icons.person),
                ),
              ],
              selected: {tipoAtual},
              onSelectionChanged: (Set<TipoVisualizacao> newSelection) {
                ref
                  .read(tipoVisualizacaoProvider.notifier)
                  .trocarPara(newSelection.first);
              },
            ),
          ),
        ),
      ),

      body: tipoAtual == TipoVisualizacao.medicos
          ? const _ListaMedicos()
          : const _ListaPacientes(),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (tipoAtual == TipoVisualizacao.medicos) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CadastroMedicoPage())
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CadastroPacientePage())
              );
          }
        },
        label: Text(tipoAtual == TipoVisualizacao.medicos
            ? 'Novo Médico'
            : 'Novo Paciente'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _ListaMedicos extends ConsumerWidget {
  const _ListaMedicos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicosState = ref.watch(listaMedicosProvider);

    return medicosState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erro: $err')),
      data: (medicos) {
        if (medicos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medical_services_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Nenhum médico encontrado',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                const Text('Clique no + para cadastrar', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: medicos.length,
          itemBuilder: (context, index) {
            final medico = medicos[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
                  child: Text(medico.nome.isNotEmpty ? medico.nome[0] : '?'),
                ),
                title: Text(medico.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('CRM: ${medico.crm}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CadastroMedicoPage(medicoParaEditar: medico),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _ListaPacientes extends ConsumerWidget {
  const _ListaPacientes();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pacientesState = ref.watch(listaPacientesProvider);

    return pacientesState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erro: $err')),
      data: (pacientes) {
        if (pacientes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Nenhum paciente encontrado',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                const Text('Clique no + para cadastrar', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: pacientes.length,
          itemBuilder: (context, index) {
            final paciente = pacientes[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child: Text(paciente.nome.isNotEmpty ? paciente.nome[0] : '?'),
                ),
                title: Text(paciente.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('CPF: ${paciente.cpf}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CadastroPacientePage(pacienteParaEditar: paciente),
                    ),
                  );  
                },
              ),
            );
          },
        );
      },
    );
  }
}