import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/app_theme.dart';
import '../models/insights_model.dart';

enum InsightFeedbackStatus { useful, rejected }

class InsightFeedbackState {
  final InsightFeedbackStatus status;
  final String? reason;

  const InsightFeedbackState({required this.status, this.reason});
}

class InsightCard extends StatelessWidget {
  final Insight insight;
  final String? disciplinaColorHex;
  final VoidCallback? onAction;
  final InsightFeedbackState? feedback;
  final bool showFeedbackReasons;
  final VoidCallback? onUseful;
  final VoidCallback? onNotUseful;
  final ValueChanged<String>? onSelectFeedbackReason;
  final VoidCallback? onClearFeedback;

  const InsightCard({
    super.key,
    required this.insight,
    this.disciplinaColorHex,
    this.onAction,
    this.feedback,
    this.showFeedbackReasons = false,
    this.onUseful,
    this.onNotUseful,
    this.onSelectFeedbackReason,
    this.onClearFeedback,
  });

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
      opacity: feedback?.status == InsightFeedbackStatus.rejected
          ? 0.58
          : _dadosInsuficientes
          ? 0.68
          : 1,
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
                      _SubjectBadge(
                        label: insight.disciplina ?? 'Geral',
                        color: insight.disciplina == null
                            ? AppColors.neutral
                            : _subjectColor(),
                      ),
                      const SizedBox(height: AppSpacing.sm),
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
                  icon: LucideIcons.telescope,
                  label: insight.natureza == 'comprovado'
                      ? 'Comprovado'
                      : 'Padrão observado',
                ),
              ],
            ),
            if (insight.acao != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ShadButton(
                key: ValueKey('action-${insight.tipo}'),
                width: double.infinity,
                backgroundColor: AppColors.brandPrimary,
                hoverBackgroundColor: AppColors.brandPrimaryDark,
                foregroundColor: AppColors.textInverted,
                expands: false,
                leading: const Icon(
                  LucideIcons.calendarPlus,
                  size: AppSizes.iconMd,
                ),
                onPressed: onAction,
                child: Flexible(
                  child: Text(
                    insight.acao!.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            if (onUseful != null ||
                onNotUseful != null ||
                feedback != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _InsightFeedbackControl(
                insightType: insight.tipo,
                feedback: feedback,
                showReasons: showFeedbackReasons,
                onUseful: onUseful,
                onNotUseful: onNotUseful,
                onSelectReason: onSelectFeedbackReason,
                onClear: onClearFeedback,
              ),
            ],
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

    return insight.numeros.entries.first;
  }

  String _heroValue(MapEntry<String, num> metric) {
    final value = _metricValue(metric.key, metric.value);
    final isPositiveDelta =
        metric.key == 'delta_pct' &&
        (insight.tipo == 'melhor_horario' ||
            insight.tipo == 'melhor_dia_semana' ||
            insight.tipo == 'vies_estimativa');

    return isPositiveDelta || metric.key == 'ganho_pct' ? '+$value' : value;
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

  Color _subjectColor() {
    final hex = disciplinaColorHex?.replaceFirst('#', '');
    if (hex == null || !RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
      return AppColors.brandPrimary;
    }

    return Color(int.parse('FF$hex', radix: 16));
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
        key == 'rendimento_bom_sono' ||
        key == 'foco_apos_tela' ||
        key == 'produtividade_antes' ||
        key == 'produtividade_depois') {
      return '$formatted / 5';
    }
    if (key == 'sessoes_sexta_noite' ||
        key == 'canceladas' ||
        key == 'sequencia_sessoes' ||
        key == 'sessoes_registradas' ||
        key == 'minimo_sugerido' ||
        key == 'sessoes_longas') {
      return '$formatted sessões';
    }
    if (key == 'concluidas' || key == 'total_tarefas') {
      return '$formatted tarefas';
    }

    return formatted;
  }
}

class _InsightFeedbackControl extends StatelessWidget {
  static const _reasons = [
    'Semana atípica',
    'Não concordo',
    'Já resolvi',
    'Pouco relevante',
  ];

  final String insightType;
  final InsightFeedbackState? feedback;
  final bool showReasons;
  final VoidCallback? onUseful;
  final VoidCallback? onNotUseful;
  final ValueChanged<String>? onSelectReason;
  final VoidCallback? onClear;

  const _InsightFeedbackControl({
    required this.insightType,
    required this.feedback,
    required this.showReasons,
    this.onUseful,
    this.onNotUseful,
    this.onSelectReason,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (feedback?.status == InsightFeedbackStatus.useful) {
      return _FeedbackNotice(
        icon: LucideIcons.thumbsUp,
        message: 'Valeu! Vamos priorizar insights assim.',
        color: AppColors.success,
        onClear: onClear,
      );
    }

    if (feedback?.status == InsightFeedbackStatus.rejected) {
      return _FeedbackNotice(
        icon: LucideIcons.eyeOff,
        message:
            'Marcado como não útil${feedback?.reason == null ? '' : ' · ${feedback!.reason}'}',
        color: AppColors.neutral,
        onClear: onClear,
      );
    }

    return Container(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Isso faz sentido pra você?',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Tooltip(
                message: 'Sim, foi útil',
                child: Semantics(
                  label: 'Marcar insight como útil',
                  button: true,
                  child: ShadButton.outline(
                    key: ValueKey('feedback-up-$insightType'),
                    size: ShadButtonSize.sm,
                    width: 34,
                    height: 30,
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.success,
                    onPressed: onUseful,
                    child: const Icon(LucideIcons.thumbsUp, size: 15),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Tooltip(
                message: 'Não bateu',
                child: Semantics(
                  label: 'Marcar insight como não útil',
                  button: true,
                  child: ShadButton.outline(
                    key: ValueKey('feedback-down-$insightType'),
                    size: ShadButtonSize.sm,
                    width: 34,
                    height: 30,
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.textMuted,
                    onPressed: onNotUseful,
                    child: const Icon(LucideIcons.thumbsDown, size: 15),
                  ),
                ),
              ),
            ],
          ),
          if (showReasons) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'O que não bateu?',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final reason in _reasons)
                  ShadButton.outline(
                    key: ValueKey('feedback-reason-$insightType-$reason'),
                    size: ShadButtonSize.sm,
                    height: 30,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    backgroundColor: AppColors.surface,
                    hoverBackgroundColor: AppColors.surfaceMuted,
                    pressedBackgroundColor: AppColors.surfaceSubtle,
                    foregroundColor: AppColors.textSecondary,
                    hoverForegroundColor: AppColors.textPrimary,
                    pressedForegroundColor: AppColors.textPrimary,
                    onPressed: () => onSelectReason?.call(reason),
                    child: Text(
                      reason,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedbackNotice extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final VoidCallback? onClear;

  const _FeedbackNotice({
    required this.icon,
    required this.message,
    required this.color,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, size: AppSizes.iconSm, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onClear != null)
            TextButton(onPressed: onClear, child: const Text('Desfazer')),
        ],
      ),
    );
  }
}

class _SubjectBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SubjectBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
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

  const _Badge({required this.icon, required this.label});

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
          Icon(icon, size: AppSizes.iconSm, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
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
