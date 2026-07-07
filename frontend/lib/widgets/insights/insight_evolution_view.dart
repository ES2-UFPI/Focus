import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../models/insights_model.dart';
import 'insight_presentation.dart';

class InsightEvolutionView extends StatelessWidget {
  final InsightsDashboard dashboard;
  final List<Insight> insights;
  final List<InsightJourneyEvent> journey;
  final List<String> disciplinas;
  final String? selectedDisciplina;
  final ValueChanged<String> onSelectDisciplina;
  final ValueChanged<Insight> onOpenInsight;
  final ValueChanged<Insight> onAction;

  const InsightEvolutionView({
    super.key,
    required this.dashboard,
    required this.insights,
    required this.journey,
    required this.disciplinas,
    required this.selectedDisciplina,
    required this.onSelectDisciplina,
    required this.onOpenInsight,
    required this.onAction,
  });

  Insight? _insightByType(String? type) {
    if (type == null) return null;
    for (final insight in insights) {
      if (insight.tipo == type) return insight;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = selectedDisciplina;
    final subjectInsights = selected == null
        ? const <Insight>[]
        : insights.where((item) => item.disciplina == selected).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EvolutionHeading(
            eyebrow: 'EVOLUÇÃO',
            title: 'Antes × agora',
            description:
                'Mudanças observadas nas últimas semanas, sem transformar tudo em uma nota.',
            trailing: dashboard.periodo,
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 780
                  ? 3
                  : constraints.maxWidth >= 520
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - AppSpacing.md * (columns - 1)) /
                  columns;
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: dashboard.comparacoes.map((comparison) {
                  return SizedBox(
                    width: width,
                    child: _EvolutionComparison(
                      comparison: comparison,
                      onTap: () {
                        final insight = _insightByType(comparison.insightTipo);
                        if (insight != null) onOpenInsight(insight);
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
          if (dashboard.experimentos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxxl),
            const _EvolutionHeading(
              eyebrow: 'EXPERIMENTOS',
              title: 'Da hipótese ao resultado',
              description:
                  'Acompanhe o que foi detectado, testado e observado nas suas próprias sessões.',
            ),
            const SizedBox(height: AppSpacing.lg),
            for (
              var index = 0;
              index < dashboard.experimentos.length;
              index++
            ) ...[
              _EvolutionExperiment(
                experiment: dashboard.experimentos[index],
                onTap: () {
                  final insight = _insightByType(
                    dashboard.experimentos[index].insightTipo,
                  );
                  if (insight != null) onOpenInsight(insight);
                },
              ),
              if (index != dashboard.experimentos.length - 1)
                const Divider(
                  height: AppSpacing.xxl,
                  color: AppColors.borderSubtle,
                ),
            ],
          ],
          if (selected != null) ...[
            const SizedBox(height: AppSpacing.xxxl),
            const _EvolutionHeading(
              eyebrow: 'POR MATÉRIA',
              title: 'A história de cada disciplina',
              description:
                  'Concentre a leitura no momento atual, na melhor condição e no próximo passo.',
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: disciplinas.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final disciplina = disciplinas[index];
                  final isSelected = disciplina == selected;
                  return isSelected
                      ? ShadButton(
                          key: ValueKey('evolution-subject-$disciplina'),
                          size: ShadButtonSize.sm,
                          backgroundColor: AppColors.subjectTeal,
                          foregroundColor: AppColors.textInverted,
                          onPressed: () => onSelectDisciplina(disciplina),
                          child: Text(disciplina),
                        )
                      : ShadButton.ghost(
                          key: ValueKey('evolution-subject-$disciplina'),
                          size: ShadButtonSize.sm,
                          foregroundColor: AppColors.textSecondary,
                          onPressed: () => onSelectDisciplina(disciplina),
                          child: Text(disciplina),
                        );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SubjectJourney(
              insights: subjectInsights,
              onOpen: onOpenInsight,
              onAction: onAction,
            ),
          ],
          const SizedBox(height: AppSpacing.xxxl),
          Text(
            'Histórico das mudanças',
            style: AppTypography.pageTitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'O registro cronológico complementa as comparações acima e mostra '
            'quando cada ação aconteceu.',
            style: AppTypography.body.copyWith(
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (journey.isEmpty)
            Text(
              'Sua jornada aparecerá aqui conforme novos padrões forem observados.',
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            )
          else
            for (var index = 0; index < journey.length; index++)
              _EvolutionTimelineEvent(
                event: journey[index],
                relatedTitle: _insightByType(
                  journey[index].insightTipo,
                )?.titulo,
                isLast: index == journey.length - 1,
              ),
        ],
      ),
    );
  }
}

class _EvolutionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;
  final String? trailing;

  const _EvolutionHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: AppTypography.sectionTitle.copyWith(
                  color: AppColors.subjectTeal,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                title,
                style: AppTypography.pageTitle.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: AppTypography.body.copyWith(
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.md),
          Text(
            trailing!,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _EvolutionComparison extends StatelessWidget {
  final InsightComparison comparison;
  final VoidCallback onTap;

  const _EvolutionComparison({required this.comparison, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final improved = comparison.melhoraQuandoDiminui
        ? comparison.agora < comparison.antes
        : comparison.agora > comparison.antes;
    final color = improved ? AppColors.success : AppColors.warningStrong;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        key: ValueKey('comparison-${comparison.id}'),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comparison.titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyStrong.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                comparison.contexto,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  _ComparisonValue(
                    label: 'Antes',
                    value: comparison.antes,
                    unit: comparison.unidade,
                    muted: true,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Icon(
                      LucideIcons.arrowRight,
                      size: AppSizes.iconSm,
                      color: AppColors.textMuted,
                    ),
                  ),
                  _ComparisonValue(
                    label: 'Agora',
                    value: comparison.agora,
                    unit: comparison.unidade,
                    color: color,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 34,
                width: double.infinity,
                child: CustomPaint(
                  painter: _TrendPainter(comparison.serie, color),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                comparison.variacao,
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComparisonValue extends StatelessWidget {
  final String label;
  final num value;
  final String unit;
  final bool muted;
  final Color? color;

  const _ComparisonValue({
    required this.label,
    required this.value,
    required this.unit,
    this.muted = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
        Text(
          '${formatInsightNumber(value)}$unit',
          style: AppTypography.cardTitle.copyWith(
            color:
                color ?? (muted ? AppColors.textMuted : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<num> values;
  final Color color;

  const _TrendPainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final doubles = values.map((value) => value.toDouble()).toList();
    final minimum = doubles.reduce(math.min);
    final maximum = doubles.reduce(math.max);
    final range = math.max(0.001, maximum - minimum);
    final path = Path();
    for (var index = 0; index < doubles.length; index++) {
      final x = size.width * index / (doubles.length - 1);
      final y =
          size.height - ((doubles[index] - minimum) / range * size.height);
      index == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

class _EvolutionExperiment extends StatelessWidget {
  final InsightExperiment experiment;
  final VoidCallback onTap;

  const _EvolutionExperiment({required this.experiment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _experimentColor(experiment.estado);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        key: ValueKey('experiment-${experiment.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Text(
                        _experimentLabel(experiment.estado),
                        style: AppTypography.caption.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    experiment.disciplina,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    experiment.inicio,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                experiment.titulo,
                style: AppTypography.cardTitle.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                experiment.hipotese,
                style: AppTypography.body.copyWith(
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xxl,
                runSpacing: AppSpacing.sm,
                children: [
                  _ExperimentMetric(
                    label: 'Métrica',
                    value: experiment.metrica,
                  ),
                  _ExperimentMetric(
                    label: 'Antes',
                    value:
                        '${formatInsightNumber(experiment.valorInicial)}${experiment.unidade}',
                  ),
                  _ExperimentMetric(
                    label: experiment.valorAtual == null ? 'Status' : 'Agora',
                    value: experiment.valorAtual == null
                        ? experiment.variacao
                        : '${formatInsightNumber(experiment.valorAtual!)}${experiment.unidade}',
                    color: color,
                  ),
                  _ExperimentMetric(
                    label: 'Amostra',
                    value: '${experiment.amostra} sessões',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExperimentMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _ExperimentMetric({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: AppTypography.bodyStrong.copyWith(
            color: color ?? AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SubjectJourney extends StatelessWidget {
  final List<Insight> insights;
  final ValueChanged<Insight> onOpen;
  final ValueChanged<Insight> onAction;

  const _SubjectJourney({
    required this.insights,
    required this.onOpen,
    required this.onAction,
  });

  Insight? _first(bool Function(Insight) test) {
    for (final insight in insights) {
      if (test(insight)) return insight;
    }
    return null;
  }

  Insight? _byTypes(List<String> types) {
    for (final type in types) {
      final item = _first((insight) => insight.tipo == type);
      if (item != null) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final current =
        _byTypes([
          'progresso',
          'efeito_acao',
          'sequencia_produtiva',
          'tarefas_no_prazo',
        ]) ??
        _first((item) => item.severidade == 'positivo');
    final best =
        _byTypes([
          'melhor_horario',
          'melhor_dia_semana',
          'foco_sem_interrupcoes',
        ]) ??
        current;
    final next =
        _byTypes([
          'ritmo_disciplina',
          'vies_estimativa',
          'cramming',
          'equilibrio_metodo',
          'duracao_ideal',
        ]) ??
        _first((item) => item.acao != null) ??
        _first(
          (item) =>
              item.severidade == 'critico' || item.severidade == 'atencao',
        );
    final rows = <Widget>[
      if (current != null)
        _SubjectStoryRow(
          label: 'AGORA',
          icon: LucideIcons.trendingUp,
          color: AppColors.success,
          insight: current,
          onOpen: () => onOpen(current),
        ),
      if (best != null)
        _SubjectStoryRow(
          label: 'MELHOR CONDIÇÃO',
          icon: LucideIcons.circleCheck,
          color: AppColors.subjectTeal,
          insight: best,
          onOpen: () => onOpen(best),
        ),
      if (next != null)
        _SubjectStoryRow(
          label: 'PRÓXIMO PASSO',
          icon: LucideIcons.target,
          color: AppColors.warningStrong,
          insight: next,
          onOpen: () => onOpen(next),
          onAction: next.acao == null ? null : () => onAction(next),
        ),
    ];

    if (rows.isEmpty) {
      return Text(
        'Ainda não há dados suficientes para montar esta jornada.',
        style: AppTypography.body.copyWith(color: AppColors.textMuted),
      );
    }
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0)
                const Divider(
                  height: AppSpacing.xxl,
                  color: AppColors.borderSubtle,
                ),
              rows[index],
            ],
          ],
        ),
      ),
    );
  }
}

class _SubjectStoryRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Insight insight;
  final VoidCallback onOpen;
  final VoidCallback? onAction;

  const _SubjectStoryRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.insight,
    required this.onOpen,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppSizes.iconMd, color: color),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.sectionTitle.copyWith(color: color),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                insight.titulo,
                style: AppTypography.bodyStrong.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${insight.amostra} sessões · ${confidenceLabel(insight.confianca).toLowerCase()}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  TextButton(
                    onPressed: onOpen,
                    child: const Text('Ver evidência'),
                  ),
                  if (onAction != null)
                    FilledButton.tonal(
                      onPressed: onAction,
                      child: Text(insight.acao!.label),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EvolutionTimelineEvent extends StatelessWidget {
  final InsightJourneyEvent event;
  final String? relatedTitle;
  final bool isLast;

  const _EvolutionTimelineEvent({
    required this.event,
    required this.relatedTitle,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = _eventColor(event.tipo);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _eventIcon(event.tipo),
                    size: AppSizes.iconSm,
                    color: color,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      color: AppColors.borderSubtle,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: AppSpacing.xs,
                bottom: isLast ? 0 : AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      Text(
                        event.data,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _eventLabel(event.tipo),
                        style: AppTypography.caption.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    event.texto,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  if (relatedTitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Relacionado a: $relatedTitle',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _experimentColor(String state) {
  switch (state) {
    case 'resultado':
      return AppColors.success;
    case 'testando':
      return AppColors.info;
    case 'pronto':
    default:
      return AppColors.warningStrong;
  }
}

String _experimentLabel(String state) {
  switch (state) {
    case 'resultado':
      return 'RESULTADO OBSERVADO';
    case 'testando':
      return 'EM TESTE';
    case 'pronto':
    default:
      return 'PRONTO PARA TESTAR';
  }
}

Color _eventColor(String type) {
  switch (type) {
    case 'acao':
      return AppColors.info;
    case 'melhora':
      return AppColors.success;
    default:
      return AppColors.warningStrong;
  }
}

IconData _eventIcon(String type) {
  switch (type) {
    case 'acao':
      return LucideIcons.zap;
    case 'melhora':
      return LucideIcons.trendingUp;
    default:
      return LucideIcons.search;
  }
}

String _eventLabel(String type) {
  switch (type) {
    case 'acao':
      return 'Ação';
    case 'melhora':
      return 'Melhora observada';
    default:
      return 'Detectado';
  }
}
