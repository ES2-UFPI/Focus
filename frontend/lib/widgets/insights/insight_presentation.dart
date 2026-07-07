import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../models/insights_model.dart';

Color severityColor(String severity) {
  switch (severity) {
    case 'positivo':
      return AppColors.success;
    case 'atencao':
      return AppColors.warningStrong;
    case 'critico':
      return AppColors.danger;
    case 'info':
    default:
      return AppColors.info;
  }
}

String severityLabel(String severity) {
  switch (severity) {
    case 'positivo':
      return 'Conquista';
    case 'atencao':
      return 'Atenção';
    case 'critico':
      return 'Crítico';
    case 'info':
    default:
      return 'Informativo';
  }
}

String categoryLabel(String category) {
  switch (category) {
    case 'tempo':
      return 'Tempo';
    case 'foco':
      return 'Foco';
    case 'planejamento':
      return 'Planejamento';
    case 'rotina':
      return 'Rotina';
    case 'saude':
      return 'Saúde';
    case 'metodo':
      return 'Método';
    default:
      return category;
  }
}

IconData insightIcon(String type) {
  switch (type) {
    case 'melhor_horario':
      return LucideIcons.clock;
    case 'melhor_dia_semana':
      return LucideIcons.calendarCheck;
    case 'duracao_ideal':
      return LucideIcons.batteryLow;
    case 'foco_sem_interrupcoes':
      return LucideIcons.focus;
    case 'vies_estimativa':
      return LucideIcons.calculator;
    case 'tarefas_no_prazo':
      return LucideIcons.listChecks;
    case 'taxa_furo':
      return LucideIcons.calendarX;
    case 'sequencia_produtiva':
      return LucideIcons.flame;
    case 'cramming':
      return LucideIcons.hourglass;
    case 'sono_x_rendimento':
      return LucideIcons.moon;
    case 'tela_antes_sessao':
      return LucideIcons.smartphone;
    case 'equilibrio_metodo':
      return LucideIcons.bookOpenCheck;
    case 'efeito_acao':
      return LucideIcons.trendingUp;
    case 'progresso':
      return LucideIcons.award;
    case 'desgaste':
      return LucideIcons.batteryWarning;
    default:
      return LucideIcons.sparkles;
  }
}

String metricLabel(String key) {
  const labels = {
    'manha': 'Manhã',
    'noite': 'Noite',
    'delta_pct': 'Diferença',
    'produtividade_quinta': 'Quinta-feira',
    'media_outros_dias': 'Outros dias',
    'limite_min': 'Ponto de queda',
    'antes_limite': 'Antes do limite',
    'depois_limite': 'Após o limite',
    'queda_pct': 'Queda',
    'sessoes_sem_interrupcao_pct': 'Sem interrupção',
    'media_blocos_foco_min': 'Bloco médio',
    'interrupcoes_media': 'Interrupções',
    'estimado_min': 'Planejado',
    'real_min': 'Realizado',
    'concluidas': 'Concluídas',
    'total_tarefas': 'Tarefas',
    'sessoes_sexta_noite': 'Sextas à noite',
    'canceladas': 'Canceladas',
    'taxa_pct': 'Taxa',
    'sequencia_sessoes': 'Sequência',
    'produtividade_media': 'Produtividade',
    'intervalo_medio_dias': 'Intervalo médio',
    'horas_totais': 'Total antes da prova',
    'horas_ultimas_48h': 'Últimas 48h',
    'concentracao_pct': 'Concentração',
    'horas_sono_curto': 'Noite curta',
    'rendimento_pouco_sono': 'Após noite curta',
    'rendimento_bom_sono': 'Após noite longa',
    'sessoes_registradas': 'Registradas',
    'minimo_sugerido': 'Amostra sugerida',
    'tempo_tela_min': 'Tela antes da sessão',
    'aumento_pausas_pct': 'Mais pausas',
    'foco_apos_tela': 'Foco após tela',
    'leitura_pct': 'Leitura',
    'questoes_pct': 'Questões',
    'ganho_pct': 'Melhora observada',
    'produtividade_antes': 'Antes da mudança',
    'produtividade_depois': 'Após a mudança',
    'taxa_anterior_pct': 'Há duas semanas',
    'taxa_atual_pct': 'Agora',
    'reducao_pct': 'Redução',
    'sessoes_longas': 'Sessões longas',
    'horas_sono_media': 'Sono médio',
  };

  return labels[key] ?? key.replaceAll('_', ' ');
}

String metricValue(String key, num value) {
  final formatted = formatInsightNumber(value);

  if (key.endsWith('_pct')) return '$formatted%';
  if (key.endsWith('_min')) return '$formatted min';
  if (key.startsWith('horas_')) return '${formatted}h';
  if (key == 'intervalo_medio_dias') {
    return '$formatted ${value == 1 ? 'dia' : 'dias'}';
  }

  const productivityKeys = {
    'manha',
    'noite',
    'antes_limite',
    'depois_limite',
    'produtividade_quinta',
    'media_outros_dias',
    'produtividade_media',
    'rendimento_pouco_sono',
    'rendimento_bom_sono',
    'foco_apos_tela',
    'produtividade_antes',
    'produtividade_depois',
  };
  if (productivityKeys.contains(key)) return '$formatted / 5';

  const sessionKeys = {
    'sessoes_sexta_noite',
    'canceladas',
    'sequencia_sessoes',
    'sessoes_registradas',
    'minimo_sugerido',
    'sessoes_longas',
  };
  if (sessionKeys.contains(key)) return '$formatted sessões';
  if (key == 'concluidas' || key == 'total_tarefas') {
    return '$formatted tarefas';
  }
  return formatted;
}

MapEntry<String, num>? heroMetric(Insight insight) {
  const heroKeys = {
    'melhor_horario': 'delta_pct',
    'melhor_dia_semana': 'delta_pct',
    'duracao_ideal': 'limite_min',
    'foco_sem_interrupcoes': 'sessoes_sem_interrupcao_pct',
    'vies_estimativa': 'delta_pct',
    'tarefas_no_prazo': 'taxa_pct',
    'taxa_furo': 'taxa_pct',
    'sequencia_produtiva': 'sequencia_sessoes',
    'cramming': 'concentracao_pct',
    'sono_x_rendimento': 'queda_pct',
    'ritmo_disciplina': 'sessoes_registradas',
    'tela_antes_sessao': 'aumento_pausas_pct',
    'equilibrio_metodo': 'leitura_pct',
    'efeito_acao': 'ganho_pct',
    'progresso': 'taxa_atual_pct',
    'desgaste': 'queda_pct',
  };

  final preferredKey = heroKeys[insight.tipo];
  if (preferredKey != null && insight.numeros.containsKey(preferredKey)) {
    return MapEntry(preferredKey, insight.numeros[preferredKey]!);
  }
  return insight.numeros.isEmpty ? null : insight.numeros.entries.first;
}

String heroValue(Insight insight, [MapEntry<String, num>? metric]) {
  final resolvedMetric = metric ?? heroMetric(insight);
  if (resolvedMetric == null) return '—';

  final value = metricValue(resolvedMetric.key, resolvedMetric.value);
  final isPositiveDelta =
      resolvedMetric.key == 'delta_pct' &&
      {
        'melhor_horario',
        'melhor_dia_semana',
        'vies_estimativa',
      }.contains(insight.tipo);
  return isPositiveDelta || resolvedMetric.key == 'ganho_pct'
      ? '+$value'
      : value;
}

String formatInsightNumber(num value) {
  return value % 1 == 0
      ? value.toInt().toString()
      : value.toStringAsFixed(1).replaceAll('.', ',');
}
