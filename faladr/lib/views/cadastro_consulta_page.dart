import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faladr_shared/faladr_shared.dart';

import '../controller/plano_controller.dart';
import '../controller/paciente_controller.dart';
import '../controller/medico_controller.dart';
import '../controller/consulta_controller.dart';
import '../controller/cadastro_consulta_controller.dart';
import '../repositories/consulta_repository.dart'; 

class CadastroConsultaPage extends ConsumerStatefulWidget {
  final ConsultaModel? consultaParaEditar;
  const CadastroConsultaPage({super.key, this.consultaParaEditar});

  @override
  ConsumerState<CadastroConsultaPage> createState() => _CadastroConsultaPageState();
}

class _CadastroConsultaPageState extends ConsumerState<CadastroConsultaPage> {
  final TextEditingController observacoesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.consultaParaEditar != null) {
        final consulta = widget.consultaParaEditar!;
        ref.read(formPlanoProvider.notifier).state = consulta.plano;
        ref.read(formPacienteProvider.notifier).state = consulta.paciente;
        ref.read(formMedicoProvider.notifier).state = consulta.medico;
        ref.read(formDataProvider.notifier).state = consulta.dataHora;
        observacoesController.text = consulta.observacoes;
      } else {
        ref.invalidate(formPlanoProvider);
        ref.invalidate(formPacienteProvider);
        ref.invalidate(formMedicoProvider);
        ref.invalidate(formDataProvider);
        observacoesController.clear();
      }
    });
  }

  @override
  void dispose() {
    observacoesController.dispose();
    super.dispose();
  }

  Future<void> _excluirConsulta(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Consulta'),
        content: const Text('Tem certeza que deseja excluir esta consulta? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    ref.read(salvandoConsultaProvider.notifier).state = true;

    try {
      final repository = ref.read(consultaRepositoryProvider);
      
      await repository.deletarConsulta(widget.consultaParaEditar!.id!);

      ref.invalidate(listaConsultasProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consulta excluída com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      ref.read(salvandoConsultaProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final planosAsync = ref.watch(listaPlanosProvider);
    final pacientesAsync = ref.watch(listaPacientesProvider);
    final medicosAsync = ref.watch(listaMedicosProvider);

    final planoSelecionado = ref.watch(formPlanoProvider);
    final pacienteSelecionado = ref.watch(formPacienteProvider);
    final medicoSelecionado = ref.watch(formMedicoProvider);
    final dataHora = ref.watch(formDataProvider);
    
    final estaASalvar = ref.watch(salvandoConsultaProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.consultaParaEditar == null ? 'Agendar Nova Consulta' : 'Editar Consulta', 
          style: const TextStyle(color: Colors.white)
        ),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: widget.consultaParaEditar != null 
          ? [
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Excluir Consulta',
                onPressed: estaASalvar ? null : () => _excluirConsulta(context, ref),
              ),
            ] 
          : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('1. Selecione o Plano', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              planosAsync.when(
                data: (planos) => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Plano de Saúde'),
                  initialValue: planoSelecionado?.id, 
                  items: planos.map((plano) {
                    return DropdownMenuItem<String>(
                      value: plano.id,
                      child: Text(plano.nome),
                    );
                  }).toList(),
                  onChanged: (novoId) {
                    if (novoId != null) {
                      final objetoPlano = planos.firstWhere((p) => p.id == novoId);
                      ref.read(formPlanoProvider.notifier).state = objetoPlano;
                      
                      ref.read(formPacienteProvider.notifier).state = null;
                      ref.read(formMedicoProvider.notifier).state = null;
                    }
                  },
                  validator: (value) => value == null ? 'Selecione um plano' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => Text('Erro: $e'),
              ),
              const SizedBox(height: 24),

              if (planoSelecionado != null) ...[
                const Text('2. Selecione o Paciente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                pacientesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('Erro ao carregar pacientes: $e'),
                  data: (pacientes) {
                    final pacientesFiltrados = pacientes.where((p) => p.plano.id == planoSelecionado.id).toList();

                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      hint: const Text('Selecione um Paciente'),
                      initialValue: pacienteSelecionado?.id,
                      items: pacientesFiltrados.map((p) => DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(p.nome),
                      )).toList(),
                      onChanged: (novoId) {
                        if (novoId != null) {
                          final objetoPaciente = pacientesFiltrados.firstWhere((p) => p.id == novoId);
                          ref.read(formPacienteProvider.notifier).state = objetoPaciente;
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),

                const Text('3. Selecione o Médico', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                medicosAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('Erro ao carregar médicos: $e'),
                  data: (medicos) {
                    final medicosFiltrados = medicos.where((m) => m.planos.any((p) => p.id == planoSelecionado.id)).toList();

                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      hint: const Text('Selecione um Médico'),
                      initialValue: medicoSelecionado?.id,
                      items: medicosFiltrados.map((m) => DropdownMenuItem<String>(
                        value: m.id,
                        child: Text(m.nome),
                      )).toList(),
                      onChanged: (novoId) {
                        if (novoId != null) {
                          final objetoMedico = medicosFiltrados.firstWhere((m) => m.id == novoId);
                          ref.read(formMedicoProvider.notifier).state = objetoMedico;
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),

                const Text('4. Data e Hora', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text("${dataHora.day.toString().padLeft(2, '0')}/${dataHora.month.toString().padLeft(2, '0')}/${dataHora.year}"),
                        onPressed: () async {
                          final data = await showDatePicker(
                            context: context,
                            initialDate: dataHora,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (data != null) {
                            final novaData = DateTime(data.year, data.month, data.day, dataHora.hour, dataHora.minute);
                            ref.read(formDataProvider.notifier).state = novaData;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text("${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}"),
                        onPressed: () async {
                          final hora = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(hour: dataHora.hour, minute: dataHora.minute),
                          );
                          if (hora != null) {
                            final novaData = DateTime(dataHora.year, dataHora.month, dataHora.day, hora.hour, hora.minute);
                            ref.read(formDataProvider.notifier).state = novaData;
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text('Observações (Opcional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: observacoesController,
                  maxLines: 3,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Ex: Primeira consulta...'),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    onPressed: estaASalvar ? null : () async {
                      if (pacienteSelecionado == null || medicoSelecionado == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Por favor, selecione o Paciente e o Médico!'))
                        );
                        return;
                      }

                      ref.read(salvandoConsultaProvider.notifier).state = true;

                      final novaConsulta = ConsultaModel(
                        id: widget.consultaParaEditar?.id,
                        planoId: planoSelecionado.id!, 
                        pacienteId: pacienteSelecionado.id!,
                        medicoId: medicoSelecionado.id!,
                        dataHora: dataHora,
                        status: widget.consultaParaEditar?.status ?? 'Agendada',
                        observacoes: observacoesController.text,
                      );

                      try {
                        final repository = ref.read(consultaRepositoryProvider);
                        
                        if (widget.consultaParaEditar == null) {
                          await repository.criarConsulta(novaConsulta); 
                        } else {
                          await repository.editarConsulta(novaConsulta); 
                        }
                        
                        ref.invalidate(listaConsultasProvider);
                        
                        ref.read(formPlanoProvider.notifier).state = null;
                        ref.read(formPacienteProvider.notifier).state = null;
                        ref.read(formMedicoProvider.notifier).state = null;

                        if (context.mounted) {
                          final mensagemSucesso = widget.consultaParaEditar == null 
                              ? 'Consulta agendada com sucesso!' 
                              : 'Consulta atualizada com sucesso!';

                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(mensagemSucesso), 
                            backgroundColor: Colors.green
                          ));
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Erro: $e'), 
                            backgroundColor: Colors.red
                          ));
                        }
                      } finally {
                        ref.read(salvandoConsultaProvider.notifier).state = false;
                      }
                    },
                    child: estaASalvar 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Agendar Consulta', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}