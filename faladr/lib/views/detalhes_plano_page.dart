import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faladr_shared/faladr_shared.dart';
import '../controller/medico_controller.dart';
import '../controller/paciente_controller.dart';
import '../controller/plano_controller.dart';

class DetalhesPlanoPage extends ConsumerWidget {
  final PlanoModel plano;

  const DetalhesPlanoPage({super.key, required this.plano});

  Future<void> _editarPlano(BuildContext context, WidgetRef ref) async {
    final nomeController = TextEditingController(text: plano.nome);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Plano'),
          content: TextField(
            controller: nomeController,
            decoration: const InputDecoration(labelText: 'Nome do Plano', border: OutlineInputBorder()),
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
                  final novoNome = nomeController.text.trim();
                  if (novoNome.isNotEmpty && novoNome != plano.nome) {
                    try {
                      final planoAtualizado = PlanoModel(
                        id: plano.id,
                        nome: novoNome,
                      );

                      await ref.read(planoRepositoryProvider).atualizarPlano(planoAtualizado);
                      
                      ref.invalidate(listaPlanosProvider);
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Plano atualizado!'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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

  Future<void> _deletarPlano(BuildContext context, WidgetRef ref, int qtdVinculos) async {
    if (qtdVinculos > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não é possível excluir um plano que possui vínculos ativos.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Plano?'),
        content: Text('Tem certeza que deseja excluir o plano ${plano.nome}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmou == true) {
      try {
        await ref.read(planoRepositoryProvider).deletarPlano(plano.id!);
        
        ref.invalidate(listaPlanosProvider);
        
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plano excluído com sucesso!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicosState = ref.watch(listaMedicosProvider);
    final pacientesState = ref.watch(listaPacientesProvider);

    final medicosDoPlano = medicosState.value?.where((m) => m.planos.any((p) => p.id == plano.id)).toList() ?? [];
    final pacientesDoPlano = pacientesState.value?.where((p) => p.plano.id == plano.id).toList() ?? [];
    
    final totalVinculos = medicosDoPlano.length + pacientesDoPlano.length;

    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        appBar: AppBar(
          title: Text(plano.nome),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editarPlano(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              color: totalVinculos > 0 ? Colors.grey : Colors.red,
              onPressed: () => _deletarPlano(context, ref, totalVinculos),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.medical_services), text: 'Médicos'),
              Tab(icon: Icon(Icons.person), text: 'Pacientes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLista(medicosDoPlano, 'Nenhum médico vinculado.', Icons.medical_information, Colors.teal.shade100),
            
            _buildLista(pacientesDoPlano, 'Nenhum paciente vinculado.', Icons.personal_injury, Colors.teal.shade100),
          ],
        ),
      ),
    );
  }

  Widget _buildLista(List<dynamic> itens, String msgVazio, IconData iconeVazio, Color corAvatar) {
    if (itens.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconeVazio, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(msgVazio, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: itens.length,
      itemBuilder: (context, index) {
        final item = itens[index];
        final isMedico = item is MedicoModel;
        
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: corAvatar,
              child: Text(item.nome[0]),
            ),
            title: Text(item.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(isMedico ? 'CRM: ${item.crm}' : 'CPF: ${item.cpf}'),
          ),
        );
      },
    );
  }
}