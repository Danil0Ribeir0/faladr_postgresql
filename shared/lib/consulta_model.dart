import 'medico_model.dart';
import 'paciente_model.dart';
import 'plano_model.dart';

class ConsultaModel {
  final String? id;
  final String planoId;
  final String medicoId;
  final String pacienteId;
  final DateTime dataHora;
  final String status;
  final String observacoes;
  
  final PlanoModel? plano;
  final MedicoModel? medico;
  final PacienteModel? paciente;

  ConsultaModel({
    this.id,
    required this.planoId,
    required this.medicoId,
    required this.pacienteId,
    required this.dataHora,
    this.status = 'Agendada',
    this.observacoes = '',
    this.plano,
    this.medico,
    this.paciente,
  });

  factory ConsultaModel.fromMap(Map<String, dynamic> map) {
    return ConsultaModel(
      id: map['id']?.toString(),
      planoId: map['plano_id']?.toString() ?? '',
      medicoId: map['medico_id']?.toString() ?? '',
      pacienteId: map['paciente_id']?.toString() ?? '',
      dataHora: map['data_hora'] != null ? DateTime.parse(map['data_hora'].toString()) : DateTime.now(),
      status: map['status'] ?? 'Agendada',
      observacoes: map['observacoes'] ?? '',
      
      plano: map['plano'] != null ? PlanoModel.fromMap(map['plano']) : null,
      medico: map['medico'] != null ? MedicoModel.fromMap(map['medico']) : null,
      paciente: map['paciente'] != null ? PacienteModel.fromMap(map['paciente']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'plano_id': planoId,
      'medico_id': medicoId,
      'paciente_id': pacienteId,
      'data_hora': dataHora.toIso8601String(),
      'status': status,
      'observacoes': observacoes,

      if (plano != null) 'plano': plano!.toMap(),
      if (medico != null) 'medico': medico!.toMap(),
      if (paciente != null) 'paciente': paciente!.toMap(),
    };
  }
}