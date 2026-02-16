import 'plano_model.dart';

class MedicoModel {
  final String? id;
  final String nome;
  final String crm;
  final String cpf;
  final DateTime dataNascimento;
  final List<PlanoModel> planos;

  MedicoModel({
    this.id,
    required this.nome,
    required this.crm,
    required this.cpf,
    required this.dataNascimento,
    required this.planos,
  });

  factory MedicoModel.fromMap(Map<String, dynamic> map) {
    return MedicoModel(
      id: map['id']?.toString(),
      nome: map['nome'] ?? '',
      crm: map['crm'] ?? '',
      cpf: map['cpf'] ?? '',
      dataNascimento: map['data_nascimento'] != null
          ? DateTime.parse(map['data_nascimento'].toString())
          : DateTime.now(),
      planos: map['planos'] != null
          ? (map['planos'] as List)
              .map((e) => PlanoModel.fromMap(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  factory MedicoModel.fromJson(Map<String, dynamic> json) => MedicoModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'crm': crm,
      'cpf': cpf,
      'data_nascimento': dataNascimento.toIso8601String().split('T')[0],
      'planos': planos.map((x) => x.toMap()).toList(),
    };
  }

  Map<String, dynamic> toJson() => toMap();
}