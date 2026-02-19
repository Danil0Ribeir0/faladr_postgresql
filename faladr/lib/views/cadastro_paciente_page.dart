import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faladr_shared/faladr_shared.dart';
import '../../controller/cadastro_paciente_controller.dart';
import '../../controller/plano_controller.dart';

final planoSelecionadoProvider = StateProvider<PlanoModel?>((ref) => null);

class CadastroPacientePage extends ConsumerStatefulWidget {
  final PacienteModel? pacienteParaEditar;

  const CadastroPacientePage({super.key, this.pacienteParaEditar});

  @override
  ConsumerState<CadastroPacientePage> createState() => _CadastroPacientePageState();
}

class _CadastroPacientePageState extends ConsumerState<CadastroPacientePage> {
  final _formKey = GlobalKey<FormState>();
  
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _dataController = TextEditingController();

  bool get _editando => widget.pacienteParaEditar != null;

  @override
  void initState() {
    super.initState();
    
    if (_editando) {
      final p = widget.pacienteParaEditar!;
      _nomeController.text = p.nome;
      _cpfController.text = p.cpf;

      try {
        final dataIso = p.dataNascimento.toString().split(' ')[0];
        final partes = dataIso.split('-');
        _dataController.text = '${partes[2]}/${partes[1]}/${partes[0]}';
      } catch (_) {
        _dataController.text = "";
      }

      Future.microtask(() {
        ref.read(planoSelecionadoProvider.notifier).state = p.plano;
      });
    } else {
      Future.microtask(() {
        ref.read(planoSelecionadoProvider.notifier).state = null;
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

  Future<void> _selecionarData() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900), 
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'), 
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

  String _converterDataParaIso(String dataBr) {
    try {
      final partes = dataBr.split('/');
      return '${partes[2]}-${partes[1]}-${partes[0]}';
    } catch (e) {
      return dataBr;
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final planoSelecionado = ref.read(planoSelecionadoProvider);
    
    if (planoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um plano de saúde.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final dataParaBanco = _converterDataParaIso(_dataController.text);

    try {
      await salvarPaciente(
        ref: ref,
        id: widget.pacienteParaEditar?.id,
        nome: _nomeController.text,
        cpf: _cpfController.text,
        dataNascimento: dataParaBanco,
        plano: planoSelecionado,
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

  void _togglePlano(PlanoModel plano, bool selecionado) {
    if (selecionado) {
      ref.read(planoSelecionadoProvider.notifier).state = plano;
    } else {
      ref.read(planoSelecionadoProvider.notifier).state = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(cadastrandoPacienteProvider);
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
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _cpfController,
                decoration: const InputDecoration(
                  labelText: 'CPF (Apenas números)', 
                  border: OutlineInputBorder(),
                  counterText: "",
                ),
                keyboardType: TextInputType.number,
                maxLength: 11,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo obrigatório';
                  if (v.length != 11) return 'CPF deve ter 11 dígitos';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _dataController,
                readOnly: true, 
                onTap: _selecionarData, 
                decoration: const InputDecoration(
                  labelText: 'Data Nascimento',
                  hintText: 'DD/MM/AAAA',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 24),
              
              const Align(
                alignment: Alignment.centerLeft,
                child: const Text('Plano de Saúde *', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              
              listaPlanosAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (err, stack) => Text('Erro ao carregar planos: $err'),
                data: (planosDisponiveis) {
                  final planoAtual = ref.watch(planoSelecionadoProvider);
                  return Wrap(
                    spacing: 8.0,
                    children: planosDisponiveis.map((plano) {
                      final isSelected = planoAtual?.id == plano.id;
                      
                      return ChoiceChip(
                        label: Text(plano.nome),
                        selected: isSelected,
                        onSelected: (bool selected) => _togglePlano(plano, selected),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 32),
              
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