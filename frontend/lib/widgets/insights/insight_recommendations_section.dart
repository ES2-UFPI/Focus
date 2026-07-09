import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../models/insights_model.dart';

enum InsightRecommendationKind { action, experiment }

class InsightRecommendationEntry {
  final String id;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final InsightRecommendationKind kind;
  final Insight? insight;
  final InsightExperiment? experiment;

  const InsightRecommendationEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.kind,
    this.insight,
    this.experiment,
  });
}

List<InsightRecommendationEntry> buildInsightRecommendationEntries({
  required List<Insight> insights,
  required List<InsightExperiment> experiments,
}) {
  final entries = <InsightRecommendationEntry>[];
  final actionTypes = <String>{};

  for (final insight in insights) {
    final action = insight.acao;
    if (action == null ||
        insight.confianca == 'insuficiente' ||
        !actionTypes.add(action.tipo)) {
      continue;
    }
    entries.add(
      InsightRecommendationEntry(
        id: 'action-${insight.tipo}',
        title: action.label,
        subtitle: insight.titulo,
        ctaLabel: 'Fazer agora',
        kind: InsightRecommendationKind.action,
        insight: insight,
      ),
    );
  }

  for (final experiment in experiments) {
    if (experiment.estado != 'pronto' && experiment.estado != 'testando') {
      continue;
    }
    entries.add(
      InsightRecommendationEntry(
        id: 'experiment-${experiment.id}',
        title: experiment.titulo,
        subtitle: experiment.estado == 'testando'
            ? 'Teste em andamento · ${experiment.hipotese}'
            : experiment.hipotese,
        ctaLabel: experiment.estado == 'testando'
            ? 'Acompanhar'
            : 'Começar teste',
        kind: InsightRecommendationKind.experiment,
        experiment: experiment,
      ),
    );
  }
  return List.unmodifiable(entries);
}

class InsightRecommendationsSection extends StatelessWidget {
  final List<InsightRecommendationEntry> entries;
  final ValueChanged<Insight> onOpenInsight;
  final ValueChanged<Insight> onAction;
  final ValueChanged<InsightExperiment> onOpenExperiment;

  const InsightRecommendationsSection({
    super.key,
    required this.entries,
    required this.onOpenInsight,
    required this.onAction,
    required this.onOpenExperiment,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🎯 Recomendações',
          style: AppTypography.cardTitle.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Próximos passos derivados dos padrões acima.',
          style: AppTypography.body.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var index = 0; index < entries.length; index++) ...[
          if (index > 0)
            const Divider(height: 1, color: AppColors.borderSubtle),
          _RecommendationRow(
            entry: entries[index],
            onOpenInsight: onOpenInsight,
            onAction: onAction,
            onOpenExperiment: onOpenExperiment,
          ),
        ],
      ],
    );
  }
}

class _RecommendationRow extends StatelessWidget {
  final InsightRecommendationEntry entry;
  final ValueChanged<Insight> onOpenInsight;
  final ValueChanged<Insight> onAction;
  final ValueChanged<InsightExperiment> onOpenExperiment;

  const _RecommendationRow({
    required this.entry,
    required this.onOpenInsight,
    required this.onAction,
    required this.onOpenExperiment,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ValueKey('recommendation-${entry.id}'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs),
            child: Icon(
              LucideIcons.target,
              size: AppSizes.iconMd,
              color: AppColors.warningStrong,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: AppTypography.bodyStrong.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  entry.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ShadButton.ghost(
            size: ShadButtonSize.sm,
            foregroundColor: AppColors.subjectTeal,
            onPressed: () {
              final insight = entry.insight;
              final experiment = entry.experiment;
              if (entry.kind == InsightRecommendationKind.action &&
                  insight != null) {
                onAction(insight);
              } else if (experiment != null) {
                onOpenExperiment(experiment);
              }
            },
            child: Text(entry.ctaLabel),
          ),
          if (entry.insight != null)
            IconButton(
              tooltip: 'Ver evidência',
              icon: const Icon(LucideIcons.chevronRight, size: AppSizes.iconSm),
              onPressed: () => onOpenInsight(entry.insight!),
            ),
        ],
      ),
    );
  }
}
