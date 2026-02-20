import 'package:google_fonts/google_fonts.dart';
import 'package:faladr/views/cadastro_paciente_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/medico_controller.dart';
import '../controller/paciente_controller.dart';
import '../controller/plano_controller.dart';
import '../views/cadastro_medico_page.dart';
import 'package:faladr_shared/faladr_shared.dart';

enum TipoVisualizacao {medicos, pacientes, planos}

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
                ButtonSegment( 
                  value: TipoVisualizacao.planos,
                  label: Text('Planos'),
                  icon: Icon(Icons.description),
                ),
              ],
              selected: {tipoAtual},
              onSelectionChanged: (Set<TipoVisualizacao> newSelection) {
                final novoTipo = newSelection.first;
                
                ref.read(tipoVisualizacaoProvider.notifier).trocarPara(novoTipo);

                if (novoTipo == TipoVisualizacao.medicos) {
                  ref.invalidate(listaMedicosProvider);
                } else if (novoTipo == TipoVisualizacao.pacientes) {
                  ref.invalidate(listaPacientesProvider);
                } else if (novoTipo == TipoVisualizacao.planos) {
                  ref.invalidate(listaPlanosProvider);
                }
              },
            ),
          ),
        ),
      ),

      body: switch (tipoAtual) {
        TipoVisualizacao.medicos => const _ListaMedicos(),
        TipoVisualizacao.pacientes => const _ListaPacientes(),
        TipoVisualizacao.planos => const _ListaPlanos(),
      },

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (tipoAtual == TipoVisualizacao.medicos) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CadastroMedicoPage())
            );
          } else if (tipoAtual == TipoVisualizacao.pacientes) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CadastroPacientePage())
            );
          } else {
            _mostrarDialogNovoPlano(context, ref);
          }
        },
        label: Text(
          tipoAtual == TipoVisualizacao.medicos
              ? 'Novo Médico'
              : tipoAtual == TipoVisualizacao.pacientes
                  ? 'Novo Paciente'
                  : 'Novo Plano',
        ),
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

class _ListaPlanos extends ConsumerWidget {
  const _ListaPlanos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planosState = ref.watch(listaPlanosProvider);

    return planosState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erro: $err')),
      data: (planos) {
        if (planos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Nenhum plano encontrado',
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
          itemCount: planos.length,
          itemBuilder: (context, index) {
            final plano = planos[index];
            
            final String qtdMedicos = plano.quantidadeMedicos > 0 ? plano.quantidadeMedicos.toString() : '-';
            final String qtdPacientes = plano.quantidadePacientes > 0 ? plano.quantidadePacientes.toString() : '-';
            final String statusLabel = plano.ativo ? 'Ativo' : 'Inativo';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: plano.ativo ? Colors.blue.shade100 : Colors.grey.shade300,
                  child: Text(
                    plano.nome.isNotEmpty ? plano.nome[0] : '?',
                    style: TextStyle(color: plano.ativo ? Colors.blue.shade900 : Colors.grey.shade700),
                  ),
                ),
                title: Text(
                  plano.nome, 
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: plano.ativo ? Colors.black : Colors.grey,
                  )
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    'Médicos: $qtdMedicos      Pacientes: $qtdPacientes      Status: $statusLabel',
                    style: TextStyle(
                      fontSize: 12, 
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {
                  // TODO: Navegar para CadastroPlanoPage(planoParaEditar: plano)
                },
              ),
            );
          },
        );
      },
    );
  }
}

Future<void> _mostrarDialogNovoPlano(BuildContext context, WidgetRef ref) async {
  final nomeController = TextEditingController();

  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Cadastrar Novo Plano'),
        content: TextField(
          controller: nomeController,
          decoration: const InputDecoration(
            labelText: 'Nome do Plano',
            hintText: 'Ex: Unimed, Amil, SulAmérica',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final nome = nomeController.text.trim();
              
              if (nome.isNotEmpty) {
                final novoPlano = PlanoModel(nome: nome);

                final repository = ref.read(planoRepositoryProvider);
                
                try {
                  await repository.criarPlano(novoPlano); 
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Plano cadastrado com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                  
                  ref.invalidate(listaPlanosProvider);
                  
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao salvar plano: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      );
    },
  );
}