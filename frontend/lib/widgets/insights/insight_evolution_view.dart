import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../models/insights_model.dart';
import 'insight_evolution_card_strategy.dart';

class InsightEvolutionView extends StatelessWidget {
  final List<Insight> insights;
  final List<InsightJourneyEvent> journey;
  final ValueChanged<Insight> onOpenInsight;

  const InsightEvolutionView({
    super.key,
    required this.insights,
    required this.journey,
    required this.onOpenInsight,
  });

  Insight? _insightByType(String? type) {
    if (type == null) return null;
    for (final insight in insights) {
      if (insight.tipo == type) return insight;
    }
    return null;
  }

  List<_ImprovementEntry> _improvementEntries() {
    final entries = <_ImprovementEntry>[];
    for (final event in journey) {
      if (event.tipo != 'melhora') continue;

      final insight = _insightByType(event.insightTipo);
      if (insight == null) continue;
      if (!_isProblemInsight(insight)) continue;

      entries.add(_ImprovementEntry(event: event, insight: insight));
    }
    return entries;
  }

  bool _isProblemInsight(Insight insight) {
    return insight.severidade == 'critico' || insight.severidade == 'atencao';
  }

  @override
  Widget build(BuildContext context) {
    final improvements = _improvementEntries().reversed.toList();

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
          const _EvolutionHeading(
            eyebrow: 'EVOLUÇÃO',
            title: 'Histórico das mudanças',
            description:
                'Melhorias observadas depois de ajustar hábitos que estavam atrapalhando seus estudos.',
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (improvements.isEmpty)
            Text(
              'As melhorias vão aparecer aqui conforme novos resultados forem observados.',
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            )
          else
            Column(
              children: [
                for (var index = 0; index < improvements.length; index++)
                  _ImprovementTimelineItem(
                    entry: improvements[index],
                    isLast: index == improvements.length - 1,
                    onTap: () => onOpenInsight(improvements[index].insight),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ImprovementEntry {
  final InsightJourneyEvent event;
  final Insight insight;

  const _ImprovementEntry({required this.event, required this.insight});
}

class _EvolutionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;

  const _EvolutionHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

class _ImprovementTimelineItem extends StatelessWidget {
  final _ImprovementEntry entry;
  final bool isLast;
  final VoidCallback onTap;

  const _ImprovementTimelineItem({
    required this.entry,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.trendingUp,
                    size: AppSizes.iconSm,
                    color: AppColors.success,
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
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: _ImprovementCard(entry: entry, onTap: onTap),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImprovementCard extends StatelessWidget {
  final _ImprovementEntry entry;
  final VoidCallback onTap;

  const _ImprovementCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final insight = entry.insight;
    final event = entry.event;
    final presentation = EvolutionCardStrategyResolver.defaults.resolve(
      insight,
    );
    final cardRadius = BorderRadius.circular(AppRadii.md);

    return DecoratedBox(
      decoration: AppDecorations.card(borderRadius: cardRadius),
      child: Material(
        color: Colors.transparent,
        borderRadius: cardRadius,
        child: InkWell(
          key: ValueKey(
            'evolution-improvement-${event.insightTipo ?? event.data}',
          ),
          borderRadius: cardRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: presentation.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Icon(
                        presentation.icon,
                        size: AppSizes.iconMd,
                        color: presentation.accentColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        presentation.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.cardTitle.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _DateBadge(date: event.data),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: AppSizes.iconSm,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _MetricStrip(presentation: presentation),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      LucideIcons.trendingUp,
                      size: AppSizes.iconSm,
                      color: presentation.accentColor,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Relacionado: ${presentation.relatedTitle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _ImprovementFact(
                      label: presentation.contextLabel,
                      value: presentation.contextValue,
                    ),
                    _ImprovementFact(
                      label: presentation.evidenceLabel,
                      value: presentation.evidenceValue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final String date;

  const _DateBadge({required this.date});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          date,
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MetricStrip extends StatelessWidget {
  final EvolutionCardPresentation presentation;

  const _MetricStrip({required this.presentation});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.softCard(
        color: presentation.accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    presentation.metricTitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      Text(
                        presentation.before,
                        style: AppTypography.cardTitle.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: Icon(
                          LucideIcons.arrowRight,
                          size: AppSizes.iconSm,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        presentation.after,
                        style: AppTypography.cardTitle.copyWith(
                          color: presentation.accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: presentation.deltaColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  presentation.delta,
                  style: AppTypography.caption.copyWith(
                    color: presentation.deltaColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImprovementFact extends StatelessWidget {
  final String label;
  final String value;

  const _ImprovementFact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 118),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
