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

  factory MedicoModel.fromJson(Map<String, dynamic> json) {
    return MedicoModel(
      id: json['id'],
      nome: json['nome'],
      crm: json['crm'],
      cpf: json['cpf'],
      dataNascimento: DateTime.parse(json['data_nascimento']),
      
      planos: json['planos'] != null 
          ? (json['planos'] as List).map((e) => PlanoModel.fromJson(e)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'crm': crm,
      'cpf': cpf,
      'data_nascimento': dataNascimento.toIso8601String(),
    };
  }
}