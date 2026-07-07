import 'dart:convert';

class RelatorioModel {
  final String? id;
  final String titulo;
  final String tipo;
  final DateTime dataGeracao;
  final Map<String, dynamic> dados;

  RelatorioModel({
    this.id,
    required this.titulo,
    required this.tipo,
    required this.dataGeracao,
    required this.dados,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'titulo': titulo,
      'tipo': tipo,
      'data_geracao': dataGeracao.toIso8601String(),
      'dados': dados,
    };
  }

  factory RelatorioModel.fromMap(Map<String, dynamic> map) {
    return RelatorioModel(
      id: map['id'],
      titulo: map['titulo'],
      tipo: map['tipo'],
      dataGeracao: DateTime.parse(map['data_geracao']),
      dados: map['dados'] is String ? json.decode(map['dados']) : Map<String, dynamic>.from(map['dados']),
    );
  }
}