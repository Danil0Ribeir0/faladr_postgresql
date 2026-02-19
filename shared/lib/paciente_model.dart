import 'plano_model.dart';

class PacienteModel {
  final String? id;
  final String nome;
  final String cpf;
  final DateTime dataNascimento;
  final PlanoModel plano;

  PacienteModel({
    this.id,
    required this.nome,
    required this.cpf,
    required this.dataNascimento,
    required this.plano,
  });

  factory PacienteModel.fromMap(Map<String, dynamic> map) {
    return PacienteModel(
      id: map['id']?.toString(),
      nome: map['nome'] ?? '',
      cpf: map['cpf'] ?? '',
      dataNascimento: map['data_nascimento'] != null
          ? DateTime.parse(map['data_nascimento'].toString())
          : DateTime.now(),
      plano: PlanoModel.fromMap(map['plano'] as Map<String, dynamic>),
    );
  }

  factory PacienteModel.fromJson(Map<String, dynamic> json) => PacienteModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'cpf': cpf,
      'data_nascimento': dataNascimento.toIso8601String().split('T')[0],
      'plano': plano.toMap(),
    };
  }

  Map<String, dynamic> toJson() => toMap();
}