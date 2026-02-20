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

  Future<void> _mostrarDialogSelecaoPlanos(BuildContext context, WidgetRef ref) async {
    final todosOsPlanos = ref.read(listaPlanosProvider).value ?? [];
    
    final selecionadosAtuais = ref.read(planosSelecionadosProvider);
    
    List<PlanoModel> selecaoTemporaria = List.from(selecionadosAtuais);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: const Text('Selecione até 3 planos'),
              content: SizedBox(
                width: double.maxFinite,
                child: todosOsPlanos.isEmpty 
                  ? const Text('Nenhum plano cadastrado no sistema.')
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: todosOsPlanos.length,
                      itemBuilder: (context, index) {
                        final plano = todosOsPlanos[index];
                        final isSelecionado = selecaoTemporaria.any((p) => p.id == plano.id);

                        return CheckboxListTile(
                          title: Text(plano.nome),
                          value: isSelecionado,
                          activeColor: Colors.teal,
                          onChanged: (bool? checked) {
                            setStateModal(() {
                              if (checked == true) {
                                if (selecaoTemporaria.length < 3) {
                                  selecaoTemporaria.add(plano);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Limite máximo de 3 planos atingido!'),
                                      backgroundColor: Colors.orange,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } else {
                                selecaoTemporaria.removeWhere((p) => p.id == plano.id);
                              }
                            });
                          },
                        );
                      },
                    ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    ref.read(planosSelecionadosProvider.notifier).state = selecaoTemporaria;
                    Navigator.pop(context);
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(cadastrandoProvider);

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
              
              Consumer(
                builder: (context, ref, child) {
                  final selecionados = ref.watch(planosSelecionadosProvider);
                  
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4), // Igual ao OutlineInputBorder
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: const Icon(Icons.medical_information, color: Colors.teal),
                      title: const Text('Planos de Saúde (Máx: 3)'),
                      subtitle: Text(
                        selecionados.isEmpty 
                          ? 'Nenhum plano selecionado' 
                          : '${selecionados.length} plano(s) selecionado(s) - Toque para alterar',
                        style: TextStyle(
                          color: selecionados.isEmpty ? Colors.red.shade700 : Colors.grey.shade700,
                          fontWeight: selecionados.isEmpty ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _mostrarDialogSelecaoPlanos(context, ref),
                    ),
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