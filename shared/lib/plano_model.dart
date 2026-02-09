class PlanoModel {
  final int? id;
  final String nome;

  PlanoModel({
    this.id,
    required this.nome,
  });

  factory PlanoModel.fromJson(Map<String, dynamic> json) {
    return PlanoModel(
      id: json["id"],
      nome: json["nome"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id' : id,
      'nome': nome
    };
  }
}