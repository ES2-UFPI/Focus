import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../models/insights_model.dart';
import 'insight_presentation.dart';

class EvolutionCardPresentation {
  final String title;
  final String metricTitle;
  final String before;
  final String after;
  final String delta;
  final String relatedTitle;
  final String contextLabel;
  final String contextValue;
  final IconData icon;
  final Color accentColor;
  final Color deltaColor;

  const EvolutionCardPresentation({
    required this.title,
    required this.metricTitle,
    required this.before,
    required this.after,
    required this.delta,
    required this.relatedTitle,
    required this.contextLabel,
    required this.contextValue,
    required this.icon,
    required this.accentColor,
    required this.deltaColor,
  });
}

abstract class EvolutionCardStrategy {
  const EvolutionCardStrategy();

  bool supports(Insight insight);

  EvolutionCardPresentation build(Insight insight);
}

class EvolutionCardStrategyResolver {
  final List<EvolutionCardStrategy> strategies;

  const EvolutionCardStrategyResolver(this.strategies);

  static const defaults = EvolutionCardStrategyResolver([
    HealthRoutineEvolutionStrategy(),
    PhoneUsageEvolutionStrategy(),
    StudyManagementEvolutionStrategy(),
    DefaultEvolutionCardStrategy(),
  ]);

  EvolutionCardPresentation resolve(Insight insight) {
    for (final strategy in strategies) {
      if (strategy.supports(insight)) {
        return strategy.build(insight);
      }
    }
    return const DefaultEvolutionCardStrategy().build(insight);
  }
}

class HealthRoutineEvolutionStrategy extends EvolutionCardStrategy {
  const HealthRoutineEvolutionStrategy();

  @override
  bool supports(Insight insight) {
    return insight.tipo == 'desgaste' || insight.tipo == 'sono_x_rendimento';
  }

  @override
  EvolutionCardPresentation build(Insight insight) {
    if (insight.tipo == 'sono_x_rendimento') {
      return EvolutionCardPresentation(
        title: 'Sono melhor alinhado',
        metricTitle: 'Produtividade',
        before: '2,6',
        after: '4,0',
        delta: '+35%',
        relatedTitle: 'Sono curto antes de estudar',
        contextLabel: 'Fonte',
        contextValue: 'Sono e rotina',
        icon: LucideIcons.moon,
        accentColor: AppColors.success,
        deltaColor: AppColors.success,
      );
    }

    return EvolutionCardPresentation(
      title: 'Menos estudo tarde',
      metricTitle: 'Produtividade',
      before: '3,5',
      after: '4,2',
      delta: '+20%',
      relatedTitle: 'Cansaço no fim do dia',
      contextLabel: 'Fonte',
      contextValue: 'Sono e rotina',
      icon: LucideIcons.moon,
      accentColor: AppColors.success,
      deltaColor: AppColors.success,
    );
  }
}

class PhoneUsageEvolutionStrategy extends EvolutionCardStrategy {
  const PhoneUsageEvolutionStrategy();

  @override
  bool supports(Insight insight) => insight.tipo == 'tela_antes_sessao';

  @override
  EvolutionCardPresentation build(Insight insight) {
    return EvolutionCardPresentation(
      title: 'Menos tela antes de estudar',
      metricTitle: 'Pausas',
      before: '+100%',
      after: '+35%',
      delta: '-65%',
      relatedTitle: 'Celular antes da sessão',
      contextLabel: 'Fonte',
      contextValue: 'Uso do celular',
      icon: LucideIcons.smartphone,
      accentColor: AppColors.success,
      deltaColor: AppColors.success,
    );
  }
}

class StudyManagementEvolutionStrategy extends EvolutionCardStrategy {
  const StudyManagementEvolutionStrategy();

  @override
  bool supports(Insight insight) {
    return {
      'duracao_ideal',
      'taxa_furo',
      'cramming',
      'vies_estimativa',
      'ritmo_disciplina',
    }.contains(insight.tipo);
  }

  @override
  EvolutionCardPresentation build(Insight insight) {
    switch (insight.tipo) {
      case 'duracao_ideal':
        return EvolutionCardPresentation(
          title: 'Blocos mais curtos',
          metricTitle: 'Foco no bloco',
          before: '2,8',
          after: '4,0',
          delta: '+43%',
          relatedTitle: 'Blocos longos em Banco de Dados',
          contextLabel: 'Disciplina',
          contextValue: insight.disciplina ?? 'Sessões de estudo',
          icon: LucideIcons.batteryLow,
          accentColor: AppColors.success,
          deltaColor: AppColors.success,
        );
      case 'taxa_furo':
        return EvolutionCardPresentation(
          title: 'Sexta à noite evitada',
          metricTitle: 'Cancelamentos',
          before: '60%',
          after: '40%',
          delta: '-20%',
          relatedTitle: 'Sexta à noite frágil',
          contextLabel: 'Disciplina',
          contextValue: insight.disciplina ?? 'Sessões de estudo',
          icon: LucideIcons.calendarX,
          accentColor: AppColors.success,
          deltaColor: AppColors.success,
        );
      case 'cramming':
        return EvolutionCardPresentation(
          title: 'Menos estudo em cima da hora',
          metricTitle: 'Concentração final',
          before: _metricValue(insight, 'concentracao_pct', fallback: '78%'),
          after: '55%',
          delta: '-23%',
          relatedTitle: 'Estudo concentrado no fim',
          contextLabel: 'Contexto',
          contextValue: insight.disciplina ?? 'Planejamento',
          icon: LucideIcons.hourglass,
          accentColor: AppColors.success,
          deltaColor: AppColors.success,
        );
      default:
        return _defaultStudyPresentation(insight);
    }
  }

  EvolutionCardPresentation _defaultStudyPresentation(Insight insight) {
    final metric = heroMetric(insight);
    return EvolutionCardPresentation(
      title: 'Rotina mais ajustada',
      metricTitle: metric == null ? 'Indicador' : metricLabel(metric.key),
      before: 'Antes',
      after: metric == null ? 'Agora' : heroValue(insight, metric),
      delta: '+0%',
      relatedTitle: insight.titulo,
      contextLabel: insight.disciplina == null ? 'Contexto' : 'Disciplina',
      contextValue: insight.disciplina ?? categoryLabel(insight.categoria),
      icon: LucideIcons.trendingUp,
      accentColor: AppColors.success,
      deltaColor: AppColors.success,
    );
  }
}

class DefaultEvolutionCardStrategy extends EvolutionCardStrategy {
  const DefaultEvolutionCardStrategy();

  @override
  bool supports(Insight insight) => true;

  @override
  EvolutionCardPresentation build(Insight insight) {
    final metric = heroMetric(insight);
    return EvolutionCardPresentation(
      title: 'Melhoria observada',
      metricTitle: metric == null ? 'Indicador' : metricLabel(metric.key),
      before: 'Antes',
      after: metric == null ? 'Agora' : heroValue(insight, metric),
      delta: '+0%',
      relatedTitle: insight.titulo,
      contextLabel: insight.disciplina == null ? 'Contexto' : 'Disciplina',
      contextValue: insight.disciplina ?? categoryLabel(insight.categoria),
      icon: LucideIcons.trendingUp,
      accentColor: AppColors.success,
      deltaColor: AppColors.success,
    );
  }
}

String _metricValue(
  Insight insight,
  String key, {
  required String fallback,
}) {
  final value = insight.numeros[key];
  return value == null ? fallback : metricValue(key, value);
}
