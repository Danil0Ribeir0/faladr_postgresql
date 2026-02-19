import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faladr_shared/faladr_shared.dart';
import '../../controller/cadastro_medico_controller.dart';
import '../../controller/medico_controller.dart';
import '../../controller/plano_controller.dart';

const List<String> _listaUFs = [
  'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
  'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN',
  'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
];

class CadastroMedicoPage extends ConsumerStatefulWidget {
  final MedicoModel? medicoParaEditar;

  const CadastroMedicoPage({super.key, this.medicoParaEditar});

  @override
  ConsumerState<CadastroMedicoPage> createState() => _CadastroMedicoPageState();
}

class _CadastroMedicoPageState extends ConsumerState<CadastroMedicoPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _nomeController = TextEditingController();
  final _crmNumeroController = TextEditingController();
  final _cpfController = TextEditingController();
  final _dataController = TextEditingController();

  String? _ufSelecionada;

  bool get _editando => widget.medicoParaEditar != null;

  @override
  void initState() {
    super.initState();
    if (_editando) {
      final m = widget.medicoParaEditar!;
      _nomeController.text = m.nome;
      _cpfController.text = m.cpf;
      
      if (m.crm.contains('/')) {
        final partes = m.crm.split('/');
        
        _crmNumeroController.text = partes[0].trim(); 
        
        if (partes.length > 1) {
          final ufDoBanco = partes[1].trim().toUpperCase();
          if (_listaUFs.contains(ufDoBanco)) {
            _ufSelecionada = ufDoBanco;
          }
        }
      } else {
        _crmNumeroController.text = m.crm;
      }

      try {
        final dataIso = m.dataNascimento.toString().split(' ')[0];
        final partesData = dataIso.split('-');
        _dataController.text = '${partesData[2]}/${partesData[1]}/${partesData[0]}'; 
      } catch (e) {
        _dataController.text = "";
      }

      Future.microtask(() {
        ref.read(planosSelecionadosProvider.notifier).state = m.planos;
      });
    } else {
       Future.microtask(() {
        ref.read(planosSelecionadosProvider.notifier).state = [];
      });
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _crmNumeroController.dispose();
    _cpfController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  String _converterDataParaIso(String dataBr) {
    try {
      final partes = dataBr.split('/');
      return '${partes[2]}-${partes[1]}-${partes[0]}';
    } catch (e) {
      return dataBr;
    }
  }

  Future<void> _selecionarData() async {
    DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );

    if (dataEscolhida != null) {
      final dia = dataEscolhida.day.toString().padLeft(2, '0');
      final mes = dataEscolhida.month.toString().padLeft(2, '0');
      final ano = dataEscolhida.year;
      setState(() {
        _dataController.text = '$dia/$mes/$ano';
      });
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final planosSelecionados = ref.read(planosSelecionadosProvider);
    if (planosSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione pelo menos 1 plano de saúde.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final dataParaBanco = _converterDataParaIso(_dataController.text);
    final crmFinal = '${_crmNumeroController.text}/$_ufSelecionada';

    try {
      if (_editando) {
        await editarMedico(
          ref: ref,
          id: widget.medicoParaEditar!.id!,
          nome: _nomeController.text,
          crm: crmFinal,
          cpf: _cpfController.text,
          dataNascimento: dataParaBanco,
          planos: planosSelecionados,
        );
      } else {
        await cadastrarMedico(
          ref: ref,
          nome: _nomeController.text,
          crm: crmFinal,
          cpf: _cpfController.text,
          dataNascimento: dataParaBanco,
          planos: planosSelecionados,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editando ? 'Médico atualizado!' : 'Médico cadastrado!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        ref.invalidate(listaMedicosProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _onDelete() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Médico?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmou == true) {
      try {
        await excluirMedico(ref: ref, id: widget.medicoParaEditar!.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Médico excluído com sucesso!')),
          );
          Navigator.pop(context); 
          ref.invalidate(listaMedicosProvider); 
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
    final listaAtual = ref.read(planosSelecionadosProvider);
    List<PlanoModel> novaLista = [...listaAtual];
    if (selecionado) {
      novaLista.add(plano);
    } else {
      novaLista.removeWhere((p) => p.id == plano.id);
    }
    ref.read(planosSelecionadosProvider.notifier).state = novaLista;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(cadastrandoProvider);
    final listaPlanosAsync = ref.watch(listaPlanosProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar Médico' : 'Novo Médico'),
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
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3, 
                    child: TextFormField(
                      controller: _crmNumeroController,
                      decoration: const InputDecoration(
                        labelText: 'Número CRM', 
                        border: OutlineInputBorder(),
                        counterText: "",
                      ),
                      keyboardType: TextInputType.number,
                      
                      maxLength: 6, 
                      
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Obrigatório';
                        if (v.length < 4) return 'Mínimo 4 dígitos';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    flex: 2, 
                    child: DropdownButtonFormField<String>(
                      initialValue: _ufSelecionada,
                      decoration: const InputDecoration(
                        labelText: 'UF',
                        border: OutlineInputBorder(),
                      ),
                      items: _listaUFs.map((uf) {
                        return DropdownMenuItem(
                          value: uf,
                          child: Text(uf),
                        );
                      }).toList(),
                      onChanged: (valor) {
                        setState(() {
                          _ufSelecionada = valor;
                        });
                      },
                      validator: (v) => v == null ? 'Obrigatório' : null,
                    ),
                  ),
                ],
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
                child: Text('Selecione os Planos (Máx: 3)', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              
              listaPlanosAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (err, stack) => Text('Erro: $err'),
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
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: isLoading ? null : _onSubmit,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_editando ? 'Salvar Alterações' : 'Salvar Médico'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}