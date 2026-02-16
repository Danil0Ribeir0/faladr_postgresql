class PlanoModel {
  final String? id;
  final String nome;

  PlanoModel({
    this.id,
    required this.nome,
  });

  factory PlanoModel.fromMap(Map<String, dynamic> map) {
    return PlanoModel(
      id: map['id']?.toString(),
      nome: map['nome'] ?? '',
    );
  }

  factory PlanoModel.fromJson(Map<String, dynamic> json) => PlanoModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
    };
  }

  Map<String, dynamic> toJson() => toMap();
}