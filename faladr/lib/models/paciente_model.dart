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

  factory PacienteModel.fromJson(Map<String, dynamic> json) {
    return PacienteModel(
      id: json['id'],
        nome: json['nome'],
        cpf: json['cpf'],
        dataNascimento: DateTime.parse(json['data_nascimento']),
        
        planos: json['planos'] != null
            ? (json['planos'] as List)
                .map((e) => PlanoModel.fromJson(e))
                .toList()
            : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'cpf': cpf,
      'data_nascimento': dataNascimento.toIso8601String(),
    };
  } 
}