import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faladr_shared/faladr_shared.dart';

import '../controller/plano_controller.dart';
import '../controller/paciente_controller.dart';
import '../controller/medico_controller.dart';
import '../controller/consulta_controller.dart';
import '../controller/cadastro_consulta_controller.dart';

class CadastroConsultaPage extends ConsumerWidget {
  const CadastroConsultaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planosAsync = ref.watch(listaPlanosProvider);
    final pacientesAsync = ref.watch(listaPacientesProvider);
    final medicosAsync = ref.watch(listaMedicosProvider);

    final planoSelecionado = ref.watch(formPlanoProvider);
    final pacienteSelecionado = ref.watch(formPacienteProvider);
    final medicoSelecionado = ref.watch(formMedicoProvider);
    final dataHora = ref.watch(formDataProvider);
    
    final estaASalvar = ref.watch(salvandoConsultaProvider);

    final observacoesController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Nova Consulta', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
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
                loading: () => const CircularProgressIndicator(),
                error: (e, s) => Text('Erro ao carregar planos: $e'),
                data: (planos) => DropdownButtonFormField<PlanoModel>(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  hint: const Text('Escolha o Plano de Saúde'),
                  initialValue: planoSelecionado,
                  items: planos.map((p) => DropdownMenuItem(value: p, child: Text(p.nome))).toList(),
                  onChanged: (novoPlano) {
                    ref.read(formPlanoProvider.notifier).state = novoPlano;
                    ref.read(formPacienteProvider.notifier).state = null;
                    ref.read(formMedicoProvider.notifier).state = null;
                  },
                ),
              ),
              const SizedBox(height: 24),

              if (planoSelecionado != null) ...[
                const Text('2. Selecione o Paciente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                pacientesAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, s) => Text('Erro ao carregar pacientes: $e'),
                  data: (pacientes) {
                    final pacientesFiltrados = pacientes.where((p) => p.plano.id == planoSelecionado.id).toList();

                    return DropdownButtonFormField<PacienteModel>(
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      hint: const Text('Selecione um Paciente'),
                      initialValue: pacienteSelecionado,
                      items: pacientesFiltrados.map((p) => DropdownMenuItem(value: p, child: Text(p.nome))).toList(),
                      onChanged: (novo) => ref.read(formPacienteProvider.notifier).state = novo,
                    );
                  },
                ),
                const SizedBox(height: 24),

                const Text('3. Selecione o Médico', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                medicosAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, s) => Text('Erro ao carregar médicos: $e'),
                  data: (medicos) {
                    // FILTRO INTELIGENTE 2: Apenas médicos que atendem o plano selecionado
                    final medicosFiltrados = medicos.where((m) => m.planos.any((p) => p.id == planoSelecionado.id)).toList();

                    return DropdownButtonFormField<MedicoModel>(
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      hint: const Text('Selecione um Médico'),
                      initialValue: medicoSelecionado,
                      items: medicosFiltrados.map((m) => DropdownMenuItem(value: m, child: Text(m.nome))).toList(),
                      onChanged: (novo) => ref.read(formMedicoProvider.notifier).state = novo,
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
                        label: Text("${dataHora.day}/${dataHora.month}/${dataHora.year}"),
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

                // BOTÃO DE GUARDAR
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
                        planoId: planoSelecionado.id!, 
                        pacienteId: pacienteSelecionado.id!,
                        medicoId: medicoSelecionado.id!,
                        dataHora: dataHora,
                        status: 'Agendada',
                        observacoes: observacoesController.text,
                      );

                      try {
                        final repository = ref.read(consultaRepositoryProvider);
                        await repository.criarConsulta(novaConsulta);
                        
                        ref.invalidate(listaConsultasProvider);
                        
                        ref.read(formPlanoProvider.notifier).state = null;
                        ref.read(formPacienteProvider.notifier).state = null;
                        ref.read(formMedicoProvider.notifier).state = null;

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Consulta agendada com sucesso!'), backgroundColor: Colors.green));
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
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