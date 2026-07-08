import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// Modelos de dados
// ─────────────────────────────────────────────

class DashboardData {
  final double indiceConsistencia;
  final int sessoesSemana;
  final double horasEstudadas;
  final double horasPlanejadas;
  final int streakDias;

  // Indicadores
  final FrequenciaData frequencia;
  final List<DiaConsistenciaData> diasConsistencia;
  final SemanaComparacaoData comparacao;
  final ComponentesIndiceData componentesIndice;

  // Metas
  final List<MetaDisciplinaData> metasDisciplinas;
  final List<DisciplinaData> distribuicao;

  // Alertas
  final List<AlertaData> alertas;
  final String severidadeAlertas;

  // Evolução
  final List<EvolucaoSemanaData> evolucao;

  const DashboardData({
    required this.indiceConsistencia,
    required this.sessoesSemana,
    required this.horasEstudadas,
    required this.horasPlanejadas,
    required this.streakDias,
    required this.frequencia,
    required this.diasConsistencia,
    required this.comparacao,
    required this.componentesIndice,
    required this.metasDisciplinas,
    required this.distribuicao,
    required this.alertas,
    required this.severidadeAlertas,
    required this.evolucao,
  });

  String get labelIndice {
    if (indiceConsistencia >= 80) return 'Excelente ritmo!';
    if (indiceConsistencia >= 50) return 'Bom desempenho';
    return 'Precisa focar mais';
  }

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final resumo = json['resumo'] as Map<String, dynamic>? ?? {};
    final indicadores = json['indicadores'] as Map<String, dynamic>? ?? {};
    final metas = json['metas'] as Map<String, dynamic>? ?? {};
    final analise = json['analise'] as Map<String, dynamic>? ?? {};
    final comparacao = json['comparacao'] as Map<String, dynamic>? ?? {};
    final evolucaoRaw = json['evolucao'] as Map<String, dynamic>? ?? {};

    return DashboardData(
      indiceConsistencia: _toDouble(resumo['indice_consistencia']),
      sessoesSemana: _toInt(resumo['sessoes_semana']),
      horasEstudadas: _toDouble(resumo['horas_estudadas']?['horas']),
      horasPlanejadas: _toDouble(resumo['horas_planejadas']?['horas']),
      streakDias: _toInt(indicadores['streak']?['streak']),
      frequencia: FrequenciaData.fromJson(
        indicadores['frequencia'] as Map<String, dynamic>? ?? {},
      ),
      diasConsistencia: _parseDias(
        indicadores['consistencia_por_dia'] as Map<String, dynamic>? ?? {},
      ),
      comparacao: SemanaComparacaoData.fromJson(
        comparacao['semanas'] as Map<String, dynamic>? ?? {},
      ),
      componentesIndice: ComponentesIndiceData.fromJson(
        (analise['indice_detalhado']?['componentes']) as Map<String, dynamic>? ?? {},
      ),
      metasDisciplinas: _parseMetas(
        metas['por_disciplina'] as List<dynamic>? ?? [],
      ),
      distribuicao: _parseDistribuicao(
        metas['distribuicao'] as List<dynamic>? ?? [],
      ),
      alertas: _parseAlertas(
        (analise['alertas']?['alertas']) as List<dynamic>? ?? [],
      ),
      severidadeAlertas: analise['alertas']?['severidade'] as String? ?? 'baixa',
      evolucao: _parseEvolucao(
        evolucaoRaw['historico_12_semanas'] as List<dynamic>? ?? [],
      ),
    );
  }

  // ── helpers de parsing ──────────────────────

  static double _toDouble(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
  static int _toInt(dynamic v) => (v as num?)?.toInt() ?? 0;

  static List<DiaConsistenciaData> _parseDias(Map<String, dynamic> mapa) {
    const ordem = [
      ('segunda', 'Seg'),
      ('terça', 'Ter'),
      ('quarta', 'Qua'),
      ('quinta', 'Qui'),
      ('sexta', 'Sex'),
      ('sábado', 'Sáb'),
      ('domingo', 'Dom'),
    ];
    return ordem.map((e) {
      final estudou = mapa[e.$1] == true;
      return DiaConsistenciaData(abrev: e.$2, estudou: estudou);
    }).toList();
  }

  static List<MetaDisciplinaData> _parseMetas(List<dynamic> lista) {
    return lista
        .map((e) => MetaDisciplinaData.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static const _coresDisciplinas = [
    Color(0xFF7C6FFF),
    Color(0xFF2DD4A0),
    Color(0xFFFF8C42),
    Color(0xFFFF6B9D),
    Color(0xFF4FC3F7),
    Color(0xFFFFD166),
  ];

  static List<DisciplinaData> _parseDistribuicao(List<dynamic> lista) {
    return List.generate(lista.length, (i) {
      final item = lista[i] as Map<String, dynamic>;
      return DisciplinaData(
        nome: item['disciplina'] as String? ?? '',
        horas: _toDouble(item['horas']),
        percentual: _toDouble(item['percentual']),
        cor: _coresDisciplinas[i % _coresDisciplinas.length],
      );
    });
  }

  static List<AlertaData> _parseAlertas(List<dynamic> lista) {
    return lista.map((e) => AlertaData(mensagem: e.toString())).toList();
  }

  static List<EvolucaoSemanaData> _parseEvolucao(List<dynamic> lista) {
    return lista
        .map((e) => EvolucaoSemanaData.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ─────────────────────────────────────────────

class FrequenciaData {
  final double percentual;
  final int diasEstudados;
  final int diasTotais;

  const FrequenciaData({
    required this.percentual,
    required this.diasEstudados,
    required this.diasTotais,
  });

  factory FrequenciaData.fromJson(Map<String, dynamic> json) => FrequenciaData(
        percentual: (json['percentual'] as num?)?.toDouble() ?? 0,
        diasEstudados: (json['dias_estudados'] as num?)?.toInt() ?? 0,
        diasTotais: (json['dias_totais'] as num?)?.toInt() ?? 7,
      );
}

class DiaConsistenciaData {
  final String abrev;
  final bool estudou;
  const DiaConsistenciaData({required this.abrev, required this.estudou});
}

class SemanaComparacaoData {
  final double horasAtual;
  final int sessoesAtual;
  final double horasAnterior;
  final int sessoesAnterior;
  final double diferencaHoras;
  final int diferencaSessoes;

  const SemanaComparacaoData({
    required this.horasAtual,
    required this.sessoesAtual,
    required this.horasAnterior,
    required this.sessoesAnterior,
    required this.diferencaHoras,
    required this.diferencaSessoes,
  });

  factory SemanaComparacaoData.fromJson(Map<String, dynamic> json) {
    final atual = json['semana_atual'] as Map<String, dynamic>? ?? {};
    final anterior = json['semana_anterior'] as Map<String, dynamic>? ?? {};
    final diferenca = json['diferenca'] as Map<String, dynamic>? ?? {};
    return SemanaComparacaoData(
      horasAtual: (atual['horas'] as num?)?.toDouble() ?? 0,
      sessoesAtual: (atual['sessoes'] as num?)?.toInt() ?? 0,
      horasAnterior: (anterior['horas'] as num?)?.toDouble() ?? 0,
      sessoesAnterior: (anterior['sessoes'] as num?)?.toInt() ?? 0,
      diferencaHoras: (diferenca['horas'] as num?)?.toDouble() ?? 0,
      diferencaSessoes: (diferenca['sessoes'] as num?)?.toInt() ?? 0,
    );
  }
}

class ComponentesIndiceData {
  final double frequencia;
  final double metas;
  final double streak;

  const ComponentesIndiceData({
    required this.frequencia,
    required this.metas,
    required this.streak,
  });

  factory ComponentesIndiceData.fromJson(Map<String, dynamic> json) =>
      ComponentesIndiceData(
        frequencia: (json['frequencia'] as num?)?.toDouble() ?? 0,
        metas: (json['metas'] as num?)?.toDouble() ?? 0,
        streak: (json['streak'] as num?)?.toDouble() ?? 0,
      );
}

class MetaDisciplinaData {
  final String nome;
  final double horasEstudadas;
  final double meta;
  final bool atingiu;
  final double diferenca;

  const MetaDisciplinaData({
    required this.nome,
    required this.horasEstudadas,
    required this.meta,
    required this.atingiu,
    required this.diferenca,
  });

  double get percentual => meta > 0 ? (horasEstudadas / meta).clamp(0, 1) : 0;

  factory MetaDisciplinaData.fromJson(Map<String, dynamic> json) =>
      MetaDisciplinaData(
        nome: json['nome'] as String? ?? '',
        horasEstudadas: (json['horas_estudadas'] as num?)?.toDouble() ?? 0,
        meta: (json['meta'] as num?)?.toDouble() ?? 0,
        atingiu: json['atingiu'] as bool? ?? false,
        diferenca: (json['diferenca'] as num?)?.toDouble() ?? 0,
      );
}

class DisciplinaData {
  final String nome;
  final double horas;
  final double percentual;
  final Color cor;

  const DisciplinaData({
    required this.nome,
    required this.horas,
    required this.percentual,
    required this.cor,
  });
}

class AlertaData {
  final String mensagem;
  const AlertaData({required this.mensagem});
}

class EvolucaoSemanaData {
  final int semana;
  final double indice;
  final int sessoes;
  final double horas;

  const EvolucaoSemanaData({
    required this.semana,
    required this.indice,
    required this.sessoes,
    required this.horas,
  });

  factory EvolucaoSemanaData.fromJson(Map<String, dynamic> json) =>
      EvolucaoSemanaData(
        semana: (json['semana'] as num?)?.toInt() ?? 0,
        indice: (json['indice'] as num?)?.toDouble() ?? 0,
        sessoes: (json['sessoes'] as num?)?.toInt() ?? 0,
        horas: (json['horas'] as num?)?.toDouble() ?? 0,
      );
}