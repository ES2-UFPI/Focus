import 'package:flutter/material.dart';

class DashboardData {
  final int indiceConsistencia;
  final int sessoesSemana;
  final double horasEstudadas;
  final double horasPlanejadas;
  final int streakDias;
  final List<DiaConsistenciaData> diasConsistencia;
  final List<DisciplinaData> distribuicao;

  DashboardData({
    required this.indiceConsistencia,
    required this.sessoesSemana,
    required this.horasEstudadas,
    required this.horasPlanejadas,
    required this.streakDias,
    required this.diasConsistencia,
    required this.distribuicao,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final resumo = json['resumo'] ?? {};
    final indicadores = json['indicadores'] ?? {};
    final metas = json['metas'] ?? {};

    // 1. Traduz o mapa de booleanos do Django para a lista da nossa interface
    final mapaDias = indicadores['consistencia_por_dia'] ?? {};
    final listagemDias = [
      DiaConsistenciaData('Seg', mapaDias['segunda'] == true ? 'ok' : 'miss'),
      DiaConsistenciaData('Ter', mapaDias['terça'] == true ? 'ok' : 'miss'),
      DiaConsistenciaData('Qua', mapaDias['quarta'] == true ? 'ok' : 'miss'),
      DiaConsistenciaData('Qui', mapaDias['quinta'] == true ? 'ok' : 'miss'),
      DiaConsistenciaData('Sex', mapaDias['sexta'] == true ? 'ok' : 'miss'),
      DiaConsistenciaData('Sáb', mapaDias['sábado'] == true ? 'ok' : 'miss'),
      DiaConsistenciaData('Dom', mapaDias['domingo'] == true ? 'ok' : 'miss'),
    ];

    // 2. Mapeia a lista de distribuição de disciplinas gerando paleta de cores
    final listaDist = metas['distribuicao'] as List? ?? [];
    final coresPadrao = [
      const Color(0xFF5C6BC0),
      const Color(0xFF009688),
      const Color(0xFFFF7043),
      const Color(0xFFEC407A),
      const Color(0xFF7E57C2)
    ];

    final listagemDistribuicao = List<DisciplinaData>.generate(listaDist.length, (index) {
      final item = listaDist[index];
      return DisciplinaData(
        nome: item['disciplina'] ?? '',
        horas: (item['horas'] as num?)?.toDouble() ?? 0.0,
        cor: coresPadrao[index % coresPadrao.length],
      );
    });

    return DashboardData(
      indiceConsistencia: (resumo['indice_consistencia'] as num?)?.toInt() ?? 0,
      sessoesSemana: (resumo['sessoes_semana'] as num?)?.toInt() ?? 0,
      horasEstudadas: (resumo['horas_estudadas']?['horas'] as num?)?.toDouble() ?? 0.0,
      horasPlanejadas: (resumo['horas_planejadas']?['horas'] as num?)?.toDouble() ?? 0.0,
      streakDias: (indicadores['streak']?['streak'] as num?)?.toInt() ?? 0,
      diasConsistencia: listagemDias,
      distribuicao: listagemDistribuicao,
    );
  }
}

class DiaConsistenciaData {
  final String abrev;
  final String status; // 'ok' ou 'miss'
  DiaConsistenciaData(this.abrev, this.status);
}

class DisciplinaData {
  final String nome;
  final double horas;
  final Color cor;
  DisciplinaData({required this.nome, required this.horas, required this.cor});
}