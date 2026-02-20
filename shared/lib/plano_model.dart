class PlanoModel {
  final String? id;
  final String nome;
  final bool ativo;
  final int quantidadeMedicos;
  final int quantidadePacientes;

  PlanoModel({
    this.id,
    required this.nome,
    this.ativo = true,
    this.quantidadeMedicos = 0,
    this.quantidadePacientes = 0,
  });

  factory PlanoModel.fromMap(Map<String, dynamic> map) {
    return PlanoModel(
      id: map['id']?.toString(),
      nome: map['nome'] ?? '',
      ativo: map['ativo'] is bool ? map['ativo'] : (map['ativo'] == 1),
      quantidadeMedicos: int.tryParse(map['quantidade_medicos']?.toString() ?? '0') ?? 0,
      quantidadePacientes: int.tryParse(map['quantidade_pacientes']?.toString() ?? '0') ?? 0,
    );
  }

  factory PlanoModel.fromJson(Map<String, dynamic> json) => PlanoModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'ativo': ativo,
    };
  }

  Map<String, dynamic> toJson() => toMap();
}