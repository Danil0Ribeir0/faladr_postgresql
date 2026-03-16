import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/consulta_controller.dart';
import 'cadastro_consulta_page.dart';
import 'dashboard_page.dart';

class ConsultasDashboardPage extends ConsumerWidget {
  const ConsultasDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadoConsultas = ref.watch(listaConsultasProvider);
    final termoBusca = ref.watch(termoBuscaProvider).toLowerCase();
    final larguraTela = MediaQuery.sizeOf(context).width;

    int crossAxisCount = 1;
    if (larguraTela > 1200) {
      crossAxisCount = 3;
    } else if (larguraTela > 800) {
      crossAxisCount = 2;
    }

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: estadoConsultas.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (erro, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Erro: $erro', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(listaConsultasProvider),
                child: const Text('Tentar Novamente'),
              )
            ],
          ),
        ),
        data: (consultas) {
          final consultasFiltradas = termoBusca.isEmpty 
              ? consultas 
              : consultas.where((consulta) {
                  final nomePaciente = consulta.paciente?.nome.toLowerCase() ?? '';
                  final nomeMedico = consulta.medico?.nome.toLowerCase() ?? '';
                  
                  return nomePaciente.contains(termoBusca) || nomeMedico.contains(termoBusca);
                }).toList();

          if (consultasFiltradas.isEmpty) {
            return Center(
              child: Text(
                termoBusca.isEmpty 
                  ? 'Nenhuma consulta agendada ainda.\nClique no botão + para adicionar!'
                  : 'Nenhuma consulta encontrada para "$termoBusca".',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: consultasFiltradas.length,
            itemBuilder: (context, index) {
              final consulta = consultasFiltradas[index];
              final dataFormatada = "${consulta.dataHora.day.toString().padLeft(2, '0')}/${consulta.dataHora.month.toString().padLeft(2, '0')}/${consulta.dataHora.year}";
              final horaFormatada = "${consulta.dataHora.hour.toString().padLeft(2, '0')}:${consulta.dataHora.minute.toString().padLeft(2, '0')}";

              return Card(
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CadastroConsultaPage(consultaParaEditar: consulta),
                      ),
                    );
                  },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: consulta.status == 'Confirmada' ? Colors.orange.withValues() : Colors.green.withValues(),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              consulta.status,
                              style: TextStyle(
                                color: consulta.status == 'Confirmada' ? Colors.orange[800] : Colors.green[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('$dataFormatada às $horaFormatada', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.teal),
                          const SizedBox(width: 8),
                          Expanded(child: Text(consulta.paciente?.nome ?? 'Paciente Desconhecido', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.medical_services_outlined, color: Colors.blueGrey),
                          const SizedBox(width: 8),
                          Expanded(child: Text(consulta.medico?.nome ?? 'Médico Desconhecido', style: const TextStyle(fontSize: 14, color: Colors.blueGrey), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const CadastroConsultaPage())
          );
        },
        label: const Text('Nova Consulta'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }
}