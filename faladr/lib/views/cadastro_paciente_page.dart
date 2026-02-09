import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/paciente_model.dart';
import '../../models/plano_model.dart';
import '../../controller/cadastro_paciente_controller.dart';
import '../../controller/plano_controller.dart';

final planosSelecionadosProvider = StateProvider<List<PlanoModel>>((ref) => []);

class CadastroPacientePage extends ConsumerStatefulWidget {
  final PacienteModel? pacienteParaEditar;

  const CadastroPacientePage({super.key, this.pacienteParaEditar});

  @override
  ConsumerState<CadastroPacientePage> createState() => _CadastroPacientePageState();
}

class _CadastroPacientePageState extends ConsumerState<CadastroPacientePage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores de Texto
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _dataController = TextEditingController();

  // Helper para saber se é Edição
  bool get _editando => widget.pacienteParaEditar != null;

  @override
  void initState() {
    super.initState();
    
    if (_editando) {
      final p = widget.pacienteParaEditar!;
      _nomeController.text = p.nome;
      _cpfController.text = p.cpf;

      // CONVERSÃO DATA: Banco (YYYY-MM-DD) -> Tela (DD/MM/AAAA)
      try {
        final dataIso = p.dataNascimento.toString().split(' ')[0];
        final partes = dataIso.split('-');
        _dataController.text = '${partes[2]}/${partes[1]}/${partes[0]}';
      } catch (_) {
        _dataController.text = "";
      }

      // Preenche os planos que o paciente já tem
      Future.microtask(() {
        ref.read(planosSelecionadosProvider.notifier).state = p.planos;
      });
    } else {
      // Se for novo, limpa a seleção de planos
      Future.microtask(() {
        ref.read(planosSelecionadosProvider.notifier).state = [];
      });
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  // Lógica do Calendário
  Future<void> _selecionarData() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900), // Ninguém nasceu antes de 1900
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'), // Calendário em Português
    );

    if (picked != null) {
      final dia = picked.day.toString().padLeft(2, '0');
      final mes = picked.month.toString().padLeft(2, '0');
      final ano = picked.year;
      setState(() {
        _dataController.text = '$dia/$mes/$ano';
      });
    }
  }

  // Helper: Tela (DD/MM/AAAA) -> Banco (YYYY-MM-DD)
  String _converterDataParaIso(String dataBr) {
    try {
      final partes = dataBr.split('/');
      return '${partes[2]}-${partes[1]}-${partes[0]}';
    } catch (e) {
      return dataBr;
    }
  }

  // Ação de Salvar
  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final dataParaBanco = _converterDataParaIso(_dataController.text);
    final planosSelecionados = ref.read(planosSelecionadosProvider);

    try {
      // Chama a função global do Controller de Cadastro
      await salvarPaciente(
        ref: ref,
        id: widget.pacienteParaEditar?.id,
        nome: _nomeController.text,
        cpf: _cpfController.text,
        dataNascimento: dataParaBanco,
        planos: planosSelecionados,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editando ? 'Paciente atualizado!' : 'Paciente cadastrado!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Ação de Deletar
  Future<void> _onDelete() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Paciente?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
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
        await excluirPaciente(ref: ref, id: widget.pacienteParaEditar!.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paciente excluído!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // Lógica dos Chips de Planos
  void _togglePlano(PlanoModel plano, bool selecionado) {
    final atual = ref.read(planosSelecionadosProvider);
    final novo = [...atual]; // Cria cópia da lista
    if (selecionado) {
      novo.add(plano);
    } else {
      novo.removeWhere((p) => p.id == plano.id);
    }
    
    ref.read(planosSelecionadosProvider.notifier).state = novo;
  }

  @override
  Widget build(BuildContext context) {
    // Escuta o estado de loading do Controller
    final isLoading = ref.watch(cadastrandoPacienteProvider);
    
    // Escuta a lista de planos disponíveis
    final listaPlanosAsync = ref.watch(listaPlanosProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar Paciente' : 'Novo Paciente'),
        actions: [
          if (_editando)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: isLoading ? null : _onDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. NOME
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              
              // 2. CPF BLINDADO (Igual ao do Médico)
              TextFormField(
                controller: _cpfController,
                decoration: const InputDecoration(
                  labelText: 'CPF (Apenas números)', 
                  border: OutlineInputBorder(),
                  counterText: "",
                ),
                keyboardType: TextInputType.number,
                maxLength: 11, // Trava no 11º dígito
                inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Só aceita números
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo obrigatório';
                  if (v.length != 11) return 'CPF deve ter 11 dígitos';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 3. DATA COM CALENDÁRIO
              TextFormField(
                controller: _dataController,
                readOnly: true, // Bloqueia digitação manual
                onTap: _selecionarData, // Abre calendário
                decoration: const InputDecoration(
                  labelText: 'Data Nascimento',
                  hintText: 'DD/MM/AAAA',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 24),
              
              // 4. PLANOS DE SAÚDE
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Planos de Saúde', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              
              listaPlanosAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (err, stack) => Text('Erro ao carregar planos: $err'),
                data: (planosDisponiveis) {
                  final selecionados = ref.watch(planosSelecionadosProvider);
                  return Wrap(
                    spacing: 8.0,
                    children: planosDisponiveis.map((plano) {
                      final isSelected = selecionados.any((p) => p.id == plano.id);
                      return FilterChip(
                        label: Text(plano.nome),
                        selected: isSelected,
                        onSelected: (bool selected) => _togglePlano(plano, selected),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 32),
              
              // BOTÃO SALVAR
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: isLoading ? null : _onSubmit,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_editando ? 'Salvar Alterações' : 'Salvar Paciente'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}