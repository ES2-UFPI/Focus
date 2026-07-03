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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(
                    _insightIcon(),
                    color: accentColor,
                    size: AppSizes.iconLg,
                  ),
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
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_dadosInsuficientes)
              _InsufficientNotice(color: accentColor)
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: insight.numeros.entries
                    .map(
                      (entry) => _Metric(
                        label: _metricLabel(entry.key),
                        value: _metricValue(entry.key, entry.value),
                        color: accentColor,
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: AppSpacing.lg),
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
      case 'duracao_ideal':
        return LucideIcons.batteryLow;
      case 'vies_estimativa':
        return LucideIcons.calculator;
      case 'taxa_furo':
        return LucideIcons.calendarX;
      case 'cramming':
        return LucideIcons.hourglass;
      default:
        return LucideIcons.sparkles;
    }
  }

  String _metricLabel(String key) {
    const labels = {
      'manha': 'Manhã',
      'noite': 'Noite',
      'delta_pct': 'Diferença',
      'limite_min': 'Ponto de queda',
      'antes_limite': 'Antes do limite',
      'depois_limite': 'Após o limite',
      'queda_pct': 'Queda',
      'estimado_min': 'Planejado',
      'real_min': 'Realizado',
      'sessoes_sexta_noite': 'Sextas à noite',
      'canceladas': 'Canceladas',
      'taxa_pct': 'Cancelamentos',
      'horas_totais': 'Total antes da prova',
      'horas_ultimas_48h': 'Últimas 48h',
      'concentracao_pct': 'Concentração',
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
    if (key == 'manha' ||
        key == 'noite' ||
        key == 'antes_limite' ||
        key == 'depois_limite') {
      return '$formatted / 5';
    }
    if (key == 'sessoes_sexta_noite' ||
        key == 'canceladas' ||
        key == 'sessoes_registradas' ||
        key == 'minimo_sugerido') {
      return '$formatted sessões';
    }

    return formatted;
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
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: AppTypography.bodyStrong.copyWith(color: color)),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
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
