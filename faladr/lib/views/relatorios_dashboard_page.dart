import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/relatorios_controller.dart';

class RelatoriosDashboardPage extends ConsumerWidget {
  const RelatoriosDashboardPage({super.key});

@override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(relatoriosControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios Gerenciais'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(relatoriosControllerProvider.notifier).carregarAgregacoes();
            },
          )
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(RelatoriosState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text('Erro ao carregar relatórios:\n${state.error}', textAlign: TextAlign.center),
          ],
        ),
      );
    }

    // Passo 5 e 6: Construção visual com blocos e áreas preparadas para gráficos
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSecao(
            titulo: 'Visão Geral - Médicos',
            icone: Icons.medical_services,
            dadosLista: state.medicosPorEstado, 
            rotuloDados: 'Médicos por Estado',
          ),
          const SizedBox(height: 24),
          _buildSecao(
            titulo: 'Visão Geral - Pacientes',
            icone: Icons.person,
            dadosLista: state.pacientesPorPlano, 
            rotuloDados: 'Pacientes por Plano',
          ),
          const SizedBox(height: 24),
          _buildSecao(
            titulo: 'Visão Geral - Consultas',
            icone: Icons.calendar_month,
            dadosLista: state.consultasPorMedico, 
            rotuloDados: 'Consultas por Médico',
          ),
        ],
      ),
    );
  }

  /// Método auxiliar para construir cada bloco de relatório
  Widget _buildSecao({
    required String titulo,
    required IconData icone,
    required Map<String, int> dadosLista,
    required String rotuloDados,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            
            // Área reservada para o Gráfico (Passo 6: Sem acoplamento)
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
              ),
              child: const Center(
                child: Text(
                  'Área reservada para o Gráfico\n(Barras, Pizza, etc.)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Lista Resumida dos Dados (Passo 5)
            Text(
              rotuloDados,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (dadosLista.isEmpty)
              const Text('Nenhum dado disponível para esta secção.')
            else
              ...dadosLista.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: const TextStyle(fontSize: 14)),
                      Text(
                        entry.value.toString(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}