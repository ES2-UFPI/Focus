import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../models/insights_model.dart';
import 'insight_presentation.dart';

class InsightFeedRow extends StatelessWidget {
  final String id;
  final Color indicatorColor;
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;

  const InsightFeedRow({
    super.key,
    required this.id,
    required this.indicatorColor,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
  });

  factory InsightFeedRow.fromInsight({
    Key? key,
    required Insight insight,
    required VoidCallback onTap,
  }) {
    final metric = heroMetric(insight);
    final metadata = <String>[
      if (insight.disciplina != null) insight.disciplina!,
      confidenceLabel(insight.confianca),
    ].join(' · ');
    return InsightFeedRow(
      key: key,
      id: insight.tipo,
      indicatorColor: severityColor(insight.severidade),
      icon: insightIcon(insight.tipo),
      title: insight.titulo,
      subtitle: metadata,
      value: metric == null ? null : heroValue(insight, metric),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      child: InkWell(
        key: ValueKey('feed-row-$id'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: indicatorColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: AppSizes.iconSm, color: indicatorColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyStrong.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: AppSpacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    value!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: AppTypography.bodyStrong.copyWith(
                      color: indicatorColor,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                LucideIcons.chevronRight,
                size: AppSizes.iconSm,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudyDimensionFeedRow extends StatelessWidget {
  final StudyDimension dimension;
  final VoidCallback? onTap;

  const StudyDimensionFeedRow({super.key, required this.dimension, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InsightFeedRow(
      key: ValueKey('dimension-row-${dimension.id}'),
      id: 'dimension-${dimension.id}',
      indicatorColor: severityColor(dimension.severidade),
      icon: _dimensionIcon(dimension.id),
      title: dimension.titulo,
      subtitle: dimension.resumo,
      value: dimension.tendencia,
      onTap: onTap,
    );
  }

  IconData _dimensionIcon(String id) {
    switch (id) {
      case 'tempo':
        return LucideIcons.clock;
      case 'foco':
        return LucideIcons.focus;
      case 'planejamento':
        return LucideIcons.calendarRange;
      case 'consistencia':
        return LucideIcons.repeat2;
      case 'recuperacao':
        return LucideIcons.batteryCharging;
      default:
        return LucideIcons.activity;
    }
  }
}
