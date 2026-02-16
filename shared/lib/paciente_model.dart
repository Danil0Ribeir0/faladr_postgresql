import 'plano_model.dart';

class PacienteModel {
  final String? id;
  final String nome;
  final String cpf;
  final DateTime dataNascimento;
  final List<PlanoModel> planos;

  PacienteModel({
    this.id,
    required this.nome,
    required this.cpf,
    required this.dataNascimento,
    required this.planos,
  });

  factory PacienteModel.fromMap(Map<String, dynamic> map) {
    return PacienteModel(
      id: map['id']?.toString(),
      nome: map['nome'] ?? '',
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

  factory PacienteModel.fromJson(Map<String, dynamic> json) => PacienteModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'cpf': cpf,
      'data_nascimento': dataNascimento.toIso8601String().split('T')[0],
      'planos': planos.map((x) => x.toMap()).toList(),
    };
  }

  Map<String, dynamic> toJson() => toMap();
}