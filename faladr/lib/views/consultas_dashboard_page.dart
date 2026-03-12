import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConsultaResumo {
  final String id;
  final String nomePaciente;
  final String nomeMedico;
  final DateTime dataHora;
  final String status;

  ConsultaResumo({
    required this.id,
    required this.nomePaciente,
    required this.nomeMedico,
    required this.dataHora,
    required this.status,
  });
}

final listaConsultasMockProvider = FutureProvider<List<ConsultaResumo>>((ref) async {
  await Future.delayed(const Duration(seconds: 1));
  return [
    ConsultaResumo(id: '1', nomePaciente: 'Carlos Silva', nomeMedico: 'Dr. Danilo Ribeiro', dataHora: DateTime.now().add(const Duration(days: 1)), status: 'Confirmada'),
    ConsultaResumo(id: '2', nomePaciente: 'Ana Beatriz', nomeMedico: 'Dra. Júlia Mendes', dataHora: DateTime.now().add(const Duration(days: 2, hours: 4)), status: 'Aguardando'),
    ConsultaResumo(id: '3', nomePaciente: 'Marcos Paulo', nomeMedico: 'Dr. Danilo Ribeiro', dataHora: DateTime.now().add(const Duration(days: 3, hours: 1)), status: 'Confirmada'),
  ];
});

class ConsultasDashboardPage extends ConsumerWidget {
  const ConsultasDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadoConsultas = ref.watch(listaConsultasMockProvider);
    final larguraTela = MediaQuery.sizeOf(context).width;

    int crossAxisCount = 1;
    if (larguraTela > 1200) {
      crossAxisCount = 3;
    } else if (larguraTela > 800) {
      crossAxisCount = 2;
    }

    return estadoConsultas.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (erro, stack) => Center(child: Text('Erro: $erro')),
      data: (consultas) {
        if (consultas.isEmpty) return const Center(child: Text('Nenhuma consulta agendada.'));

        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 2.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: consultas.length,
          itemBuilder: (context, index) {
            final consulta = consultas[index];
            final dataFormatada = "${consulta.dataHora.day.toString().padLeft(2, '0')}/${consulta.dataHora.month.toString().padLeft(2, '0')}/${consulta.dataHora.year}";
            final horaFormatada = "${consulta.dataHora.hour.toString().padLeft(2, '0')}:${consulta.dataHora.minute.toString().padLeft(2, '0')}";

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            color: consulta.status == 'Confirmada' ? Colors.green.withValues() : Colors.orange.withValues(),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            consulta.status,
                            style: TextStyle(
                              color: consulta.status == 'Confirmada' ? Colors.green[800] : Colors.orange[800],
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
                        Expanded(child: Text(consulta.nomePaciente, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.medical_services_outlined, color: Colors.blueGrey),
                        const SizedBox(width: 8),
                        Expanded(child: Text(consulta.nomeMedico, style: const TextStyle(fontSize: 14, color: Colors.blueGrey), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}