import 'package:faladr/views/detalhes_plano_page.dart';
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

final termoBuscaProvider = StateProvider<String>((ref) {
  return '';
});

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  Widget _buildSearchBar(WidgetRef ref) {
    return SearchBar(
      hintText: 'Pesquisar...',
      leading: const Icon(Icons.search, color: Colors.grey),
      elevation: const WidgetStatePropertyAll(1.0),
      backgroundColor: const WidgetStatePropertyAll(Colors.white),
      onChanged: (textoBusca) {
        ref.read(termoBuscaProvider.notifier).state = textoBusca;
      },
    );
  }

  Widget _buildLogo(bool isMobile) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: Colors.white,
          radius: isMobile ? 18 : 20,
          child: Icon(Icons.local_hospital, color: Colors.teal, size: isMobile ? 18 : 24),
        ),
        const SizedBox(width: 12.0),
        Text(
          'Fala Doutor!',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: isMobile ? 18.0 : 20.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipoAtual = ref.watch(tipoVisualizacaoProvider);

    final larguraTela = MediaQuery.sizeOf(context).width;
    final isMobile = larguraTela < 600;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90.0,
        backgroundColor: Colors.teal,
        leadingWidth: isMobile ? 0 : 250.0,
        leading: isMobile 
            ? null 
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildLogo(isMobile),
              ),
        title: isMobile 
            ? _buildLogo(isMobile)
            : ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: _buildSearchBar(ref),
              ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (isMobile)
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: _buildSearchBar(ref),
            ),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8.0 : 40.0, 
              vertical: 16.0
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown, 
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
                    ref.read(termoBuscaProvider.notifier).state = '';

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

          Expanded(
            child: switch (tipoAtual) {
              TipoVisualizacao.medicos => const _ListaMedicos(),
              TipoVisualizacao.pacientes => const _ListaPacientes(),
              TipoVisualizacao.planos => const _ListaPlanos(),
            },
          ),
        ],
      ),

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

    final termoBusca = ref.watch(termoBuscaProvider).toLowerCase();

    return medicosState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erro: $err')),
      data: (medicos) {
        final medicosFiltrados = termoBusca.isEmpty 
            ? medicos 
            : medicos.where((medico) {
                return medico.nome.toLowerCase().contains(termoBusca);
              }).toList();

        if (medicosFiltrados.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  termoBusca.isEmpty ? 'Nenhum médico cadastrado' : 'Nenhum médico encontrado na busca',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

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
          itemCount: medicosFiltrados.length,
          itemBuilder: (context, index) {
            final medico = medicosFiltrados[index];
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

    final termoBusca = ref.watch(termoBuscaProvider).toLowerCase();

    return pacientesState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erro: $err')),
      data: (pacientes) {
        final pacientesFiltrados = termoBusca.isEmpty
        ? pacientes 
            : pacientes.where((pacientes) {
                return pacientes.nome.toLowerCase().contains(termoBusca);
              }).toList();
        
        if (pacientesFiltrados.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  termoBusca.isEmpty ? 'Nenhum paciente cadastrado' : 'Nenhum paciente encontrado na busca',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

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
          itemCount: pacientesFiltrados.length,
          itemBuilder: (context, index) {
            final paciente = pacientesFiltrados[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
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

    final termoBusca = ref.watch(termoBuscaProvider).toLowerCase();

    return planosState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erro: $err')),
      data: (planos) {
        final planosFiltrados = termoBusca.isEmpty
        ? planos 
            : planos.where((planos) {
                return planos.nome.toLowerCase().contains(termoBusca);
              }).toList();
        
        if (planosFiltrados.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  termoBusca.isEmpty ? 'Nenhum plano cadastrado' : 'Nenhum plano encontrado na busca',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

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
          itemCount: planosFiltrados.length,
          itemBuilder: (context, index) {
            final plano = planosFiltrados[index];
            
            final String qtdMedicos = plano.quantidadeMedicos > 0 ? plano.quantidadeMedicos.toString() : '-';
            final String qtdPacientes = plano.quantidadePacientes > 0 ? plano.quantidadePacientes.toString() : '-';
            final String statusLabel = plano.ativo ? 'Ativo' : 'Inativo';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: plano.ativo ? Colors.teal.shade100 : Colors.grey.shade300,
                  child: Text(
                    plano.nome.isNotEmpty ? plano.nome[0] : '?',
                    style: TextStyle(color: plano.ativo ? Colors.black : Colors.grey.shade700),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DetalhesPlanoPage(plano: plano)),
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