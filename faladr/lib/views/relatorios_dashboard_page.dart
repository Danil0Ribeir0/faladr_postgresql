import 'dart:math'; // Necessário para calcular os ângulos do gráfico de pizza
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Substitua pelo caminho correto do seu controller
import '../controller/relatorios_controller.dart';

final selecaoPacientesProvider = StateProvider.autoDispose<int>((ref) => 0);
final selecaoMedicosProvider = StateProvider.autoDispose<int>((ref) => 0);
final selecaoConsultasProvider = StateProvider.autoDispose<int>((ref) => 0);

enum TipoGrafico { barras, linha, pizza }

final tipoGraficoPacientesProvider = StateProvider.autoDispose<TipoGrafico>((ref) => TipoGrafico.barras);
final tipoGraficoMedicosProvider = StateProvider.autoDispose<TipoGrafico>((ref) => TipoGrafico.barras);
final tipoGraficoConsultasProvider = StateProvider.autoDispose<TipoGrafico>((ref) => TipoGrafico.barras);

class AnaliseData {
  final String titulo;
  final IconData icone;
  final Map<String, int> dados;

  AnaliseData({required this.titulo, required this.icone, required this.dados});
}

class RelatoriosPage extends ConsumerWidget {
  const RelatoriosPage({super.key});

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
            icon: const Icon(Icons.save),
            tooltip: 'Salvar Snapshot no Banco',
            onPressed: () async {
              await ref.read(relatoriosControllerProvider.notifier).salvarSnapshotRelatorio();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Relatório salvo com sucesso!')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(relatoriosControllerProvider.notifier).carregarAgregacoes();
            },
          )
        ],
      ),
      body: _buildBody(state, ref),
    );
  }

  Widget _buildBody(RelatoriosState state, WidgetRef ref) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());

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

    final analisesPacientes = [
      AnaliseData(titulo: 'Por Plano', icone: Icons.health_and_safety, dados: state.pacientesPorPlano),
      AnaliseData(titulo: 'Por Faixa Etária', icone: Icons.people, dados: state.pacientesPorFaixaEtaria),
    ];

    final analisesMedicos = [
      AnaliseData(titulo: 'Por Estado (UF)', icone: Icons.map, dados: state.medicosPorEstado),
      AnaliseData(titulo: 'Por Faixa Etária', icone: Icons.person_search, dados: state.medicosPorFaixaEtaria),
      AnaliseData(titulo: 'Por Plano Atendido', icone: Icons.list_alt, dados: state.medicosPorPlano),
    ];

    final analisesConsultas = [
      AnaliseData(titulo: 'Por Médico', icone: Icons.medical_services, dados: state.consultasPorMedico),
      AnaliseData(titulo: 'Por Paciente', icone: Icons.assignment_ind, dados: state.consultasPorPaciente),
      AnaliseData(titulo: 'Por Plano', icone: Icons.receipt_long, dados: state.consultasPorPlano),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGrupoDashboard(
            tituloGrupo: 'Pacientes',
            analises: analisesPacientes,
            indiceSelecionado: ref.watch(selecaoPacientesProvider),
            tipoGrafico: ref.watch(tipoGraficoPacientesProvider),
            onCardSelecionado: (index) => ref.read(selecaoPacientesProvider.notifier).state = index,
            onGraficoAlterado: (tipo) => ref.read(tipoGraficoPacientesProvider.notifier).state = tipo,
          ),
          const SizedBox(height: 32),
          
          _buildGrupoDashboard(
            tituloGrupo: 'Médicos',
            analises: analisesMedicos,
            indiceSelecionado: ref.watch(selecaoMedicosProvider),
            tipoGrafico: ref.watch(tipoGraficoMedicosProvider),
            onCardSelecionado: (index) => ref.read(selecaoMedicosProvider.notifier).state = index,
            onGraficoAlterado: (tipo) => ref.read(tipoGraficoMedicosProvider.notifier).state = tipo,
          ),
          const SizedBox(height: 32),
          
          _buildGrupoDashboard(
            tituloGrupo: 'Consultas',
            analises: analisesConsultas,
            indiceSelecionado: ref.watch(selecaoConsultasProvider),
            tipoGrafico: ref.watch(tipoGraficoConsultasProvider),
            onCardSelecionado: (index) => ref.read(selecaoConsultasProvider.notifier).state = index,
            onGraficoAlterado: (tipo) => ref.read(tipoGraficoConsultasProvider.notifier).state = tipo,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildGrupoDashboard({
    required String tituloGrupo,
    required List<AnaliseData> analises,
    required int indiceSelecionado,
    required TipoGrafico tipoGrafico,
    required Function(int) onCardSelecionado,
    required Function(TipoGrafico) onGraficoAlterado,
  }) {
    final analiseAtual = analises[indiceSelecionado];

    Widget graficoWidget;
    switch (tipoGrafico) {
      case TipoGrafico.barras:
        graficoWidget = GraficoBarrasAnimado(dados: analiseAtual.dados);
        break;
      case TipoGrafico.linha:
        graficoWidget = GraficoLinhaAnimado(dados: analiseAtual.dados);
        break;
      case TipoGrafico.pizza:
        graficoWidget = GraficoPizzaAnimado(dados: analiseAtual.dados);
        break;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tituloGrupo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)),
            const Divider(),
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Análise: ${analiseAtual.titulo}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                SegmentedButton<TipoGrafico>(
                  segments: const [
                    ButtonSegment(value: TipoGrafico.barras, icon: Icon(Icons.bar_chart), tooltip: 'Barras'),
                    ButtonSegment(value: TipoGrafico.linha, icon: Icon(Icons.show_chart), tooltip: 'Linha'),
                    ButtonSegment(value: TipoGrafico.pizza, icon: Icon(Icons.pie_chart), tooltip: 'Pizza'),
                  ],
                  selected: {tipoGrafico},
                  onSelectionChanged: (set) => onGraficoAlterado(set.first),
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              height: 220,
              child: graficoWidget,
            ),
            
            const SizedBox(height: 24),
            
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(analises.length, (index) {
                final analise = analises[index];
                final isSelected = index == indiceSelecionado;

                return InkWell(
                  onTap: () => onCardSelecionado(index),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.teal : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.teal.shade700 : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(analise.icone, color: isSelected ? Colors.white : Colors.teal, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          analise.titulo,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class GraficoBarrasAnimado extends StatelessWidget {
  final Map<String, int> dados;
  const GraficoBarrasAnimado({super.key, required this.dados});

  @override
  Widget build(BuildContext context) {
    if (dados.isEmpty) return const Center(child: Text('Sem dados', style: TextStyle(color: Colors.grey)));
    final maxValue = dados.values.reduce((a, b) => a > b ? a : b);

    return ListView.builder(
      itemCount: dados.length,
      itemBuilder: (context, index) {
        final key = dados.keys.elementAt(index);
        final value = dados.values.elementAt(index);
        final double factor = maxValue == 0 ? 0 : (value / maxValue);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(height: 24, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12))),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          height: 24,
                          width: constraints.maxWidth * factor,
                          decoration: BoxDecoration(color: Colors.teal.shade400, borderRadius: BorderRadius.circular(12)),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(width: 30, child: Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
            ],
          ),
        );
      },
    );
  }
}

class GraficoLinhaAnimado extends StatelessWidget {
  final Map<String, int> dados;
  const GraficoLinhaAnimado({super.key, required this.dados});

  @override
  Widget build(BuildContext context) {
    if (dados.isEmpty) return const Center(child: Text('Sem dados', style: TextStyle(color: Colors.grey)));
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) {
        return CustomPaint(
          size: const Size(double.infinity, 220),
          painter: _LinhaPainter(dados: dados, progress: progress),
        );
      },
    );
  }
}

class _LinhaPainter extends CustomPainter {
  final Map<String, int> dados;
  final double progress;

  _LinhaPainter({required this.dados, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double paddingBottom = 40.0;
    final double paddingTop = 20.0;
    final double chartHeight = size.height - paddingBottom - paddingTop;
    
    if (dados.isEmpty) return;

    final paintLinha = Paint()..color = Colors.teal..strokeWidth = 3.0..style = PaintingStyle.stroke;
    final paintPonto = Paint()..color = Colors.teal.shade800..style = PaintingStyle.fill;
    
    double maxVal = dados.values.fold(0, (m, v) => v > m ? v : m).toDouble();
    if (maxVal == 0) maxVal = 1;

    final stepX = dados.length > 1 ? size.width / (dados.length - 1) : size.width / 2;
    final chaves = dados.keys.toList();
    final valores = dados.values.toList();
    final path = Path();

    for (int i = 0; i < dados.length; i++) {
      double x = dados.length > 1 ? i * stepX : stepX;
      double valorAnimado = valores[i] * progress; 
      double y = paddingTop + chartHeight - ((valorAnimado / maxVal) * chartHeight);

      if (i == 0) {path.moveTo(x, y);}
      else {path.lineTo(x, y);}
    }

    canvas.drawPath(path, paintLinha);

    for (int i = 0; i < dados.length; i++) {
      double x = dados.length > 1 ? i * stepX : stepX;
      double y = paddingTop + chartHeight - (((valores[i] * progress) / maxVal) * chartHeight);
      
      canvas.drawCircle(Offset(x, y), 5, paintPonto);

      // Texto do Eixo X (Nome)
      final textSpanX = TextSpan(text: chaves[i], style: const TextStyle(color: Colors.black54, fontSize: 10));
      final textPainterX = TextPainter(text: textSpanX, textDirection: TextDirection.ltr, textAlign: TextAlign.center);
      textPainterX.layout(maxWidth: stepX > 50 ? stepX : 50);
      textPainterX.paint(canvas, Offset(x - (textPainterX.width / 2), size.height - paddingBottom + 10));

      // Texto do Valor (Em cima do ponto)
      if (progress > 0.8) { // Mostra o valor só no final da animação
        final textSpanY = TextSpan(text: valores[i].toString(), style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold));
        final textPainterY = TextPainter(text: textSpanY, textDirection: TextDirection.ltr);
        textPainterY.layout();
        textPainterY.paint(canvas, Offset(x - (textPainterY.width / 2), y - 20));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LinhaPainter oldDelegate) => oldDelegate.progress != progress;
}

class GraficoPizzaAnimado extends StatelessWidget {
  final Map<String, int> dados;
  const GraficoPizzaAnimado({super.key, required this.dados});

  @override
  Widget build(BuildContext context) {
    if (dados.isEmpty) return const Center(child: Text('Sem dados', style: TextStyle(color: Colors.grey)));

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, progress, child) {
              return CustomPaint(
                size: const Size.square(180),
                painter: _PizzaPainter(dados: dados, progress: progress),
              );
            },
          ),
        ),
        // Legenda (Outra Metade)
        Expanded(
          flex: 4,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: dados.length,
            itemBuilder: (context, index) {
              final key = dados.keys.elementAt(index);
              final value = dados.values.elementAt(index);
              final cores = [Colors.teal, Colors.amber, Colors.blue.shade400, Colors.red.shade400, Colors.purple.shade400, Colors.orange];
              final cor = cores[index % cores.length];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, color: cor),
                    const SizedBox(width: 8),
                    Expanded(child: Text(key, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                    Text(' ($value)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PizzaPainter extends CustomPainter {
  final Map<String, int> dados;
  final double progress;

  _PizzaPainter({required this.dados, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    double total = dados.values.fold(0, (sum, v) => sum + v).toDouble();
    if (total == 0) return;

    final double radius = (size.width < size.height ? size.width : size.height) / 2;
    final Rect rect = Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: radius * 0.9);
    
    double startAngle = -pi / 2; // Começa no topo
    final cores = [Colors.teal, Colors.amber, Colors.blue.shade400, Colors.red.shade400, Colors.purple.shade400, Colors.orange];
    int corIndex = 0;

    for (var valor in dados.values) {
      final sweepAngle = (valor / total) * 2 * pi * progress;
      final paint = Paint()..color = cores[corIndex % cores.length]..style = PaintingStyle.fill;
      
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      
      startAngle += sweepAngle;
      corIndex++;
    }
  }

  @override
  bool shouldRepaint(covariant _PizzaPainter oldDelegate) => oldDelegate.progress != progress;
}