import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/app_theme.dart';
import '../models/insights_model.dart';

class InsightCard extends StatelessWidget {
  final Insight insight;

  const InsightCard({super.key, required this.insight});

  bool get _dadosInsuficientes => insight.confianca == 'insuficiente';

  @override
  Widget build(BuildContext context) {
    final accentColor = _dadosInsuficientes
        ? AppColors.neutral
        : _severityColor();
    final heroMetric = _heroMetric();
    final secondaryMetrics = insight.numeros.entries
        .where((entry) => entry.key != heroMetric.key)
        .toList();

    return Opacity(
      opacity: _dadosInsuficientes ? 0.68 : 1,
      child: Container(
        width: double.infinity,
        padding: AppSpacing.card,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroMetric(
                  icon: _insightIcon(),
                  value: _heroValue(heroMetric),
                  label: _metricLabel(heroMetric.key),
                  color: accentColor,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.titulo,
                        style: AppTypography.cardTitle.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        insight.descricao,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (_dadosInsuficientes)
              _InsufficientNotice(color: accentColor)
            else if (secondaryMetrics.isNotEmpty)
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: secondaryMetrics
                    .map(
                      (entry) => _Metric(
                        label: _metricLabel(entry.key),
                        value: _metricValue(entry.key, entry.value),
                        color: accentColor,
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _Badge(
                  icon: LucideIcons.database,
                  label:
                      '${insight.amostra} ${insight.amostra == 1 ? 'sessão' : 'sessões'}',
                ),
                _Badge(
                  icon: _dadosInsuficientes
                      ? LucideIcons.circleAlert
                      : LucideIcons.shieldCheck,
                  label: _confidenceLabel(),
                  color: _confidenceColor(),
                ),
                _Badge(
                  icon: LucideIcons.telescope,
                  label: insight.natureza == 'comprovado'
                      ? 'Comprovado'
                      : 'Padrão observado',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  MapEntry<String, num> _heroMetric() {
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
    };

    final preferredKey = heroKeys[insight.tipo];
    if (preferredKey != null && insight.numeros.containsKey(preferredKey)) {
      return MapEntry(preferredKey, insight.numeros[preferredKey]!);
    }

    return insight.numeros.entries.first;
  }

  String _heroValue(MapEntry<String, num> metric) {
    final value = _metricValue(metric.key, metric.value);
    final isPositiveDelta =
        metric.key == 'delta_pct' &&
        (insight.tipo == 'melhor_horario' ||
            insight.tipo == 'melhor_dia_semana' ||
            insight.tipo == 'vies_estimativa');

    return isPositiveDelta ? '+$value' : value;
  }

  Color _severityColor() {
    switch (insight.severidade) {
      case 'positivo':
        return AppColors.success;
      case 'atencao':
        return AppColors.warning;
      case 'critico':
        return AppColors.danger;
      case 'info':
      default:
        return AppColors.info;
    }
  }

  Color _confidenceColor() {
    switch (insight.confianca) {
      case 'alta':
        return AppColors.success;
      case 'media':
        return AppColors.warningStrong;
      case 'insuficiente':
      default:
        return AppColors.neutral;
    }
  }

  String _confidenceLabel() {
    switch (insight.confianca) {
      case 'alta':
        return 'Confiança alta';
      case 'media':
        return 'Confiança média';
      case 'insuficiente':
      default:
        return 'Dados insuficientes';
    }
  }

  IconData _insightIcon() {
    switch (insight.tipo) {
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
      default:
        return LucideIcons.sparkles;
    }
  }

  String _metricLabel(String key) {
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
    };

    return labels[key] ?? key.replaceAll('_', ' ');
  }

  String _metricValue(String key, num value) {
    final formatted = value % 1 == 0
        ? value.toInt().toString()
        : value.toStringAsFixed(1).replaceAll('.', ',');

    if (key.endsWith('_pct')) return '$formatted%';
    if (key.endsWith('_min')) return '$formatted min';
    if (key.startsWith('horas_')) return '${formatted}h';
    if (key == 'intervalo_medio_dias') {
      return '$formatted ${value == 1 ? 'dia' : 'dias'}';
    }
    if (key == 'manha' ||
        key == 'noite' ||
        key == 'antes_limite' ||
        key == 'depois_limite' ||
        key == 'produtividade_quinta' ||
        key == 'media_outros_dias' ||
        key == 'produtividade_media' ||
        key == 'rendimento_pouco_sono' ||
        key == 'rendimento_bom_sono') {
      return '$formatted / 5';
    }
    if (key == 'sessoes_sexta_noite' ||
        key == 'canceladas' ||
        key == 'sequencia_sessoes' ||
        key == 'sessoes_registradas' ||
        key == 'minimo_sugerido') {
      return '$formatted sessões';
    }
    if (key == 'concluidas' || key == 'total_tarefas') {
      return '$formatted tarefas';
    }

    return formatted;
  }
}

class _HeroMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _HeroMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: AppSizes.iconLg),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({
    required this.icon,
    required this.label,
    this.color = AppColors.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsufficientNotice extends StatelessWidget {
  final Color color;

  const _InsufficientNotice({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.circleAlert, size: AppSizes.iconMd, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Dados insuficientes — continue registrando suas sessões.',
              style: AppTypography.bodyStrong.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
