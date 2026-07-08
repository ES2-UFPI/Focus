import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/insights_model.dart';
import 'insight_presentation.dart';

bool comparisonVariationIsPositive(InsightComparison comparison) {
  final variation = comparison.variacao.trim();
  final decreases = variation.startsWith('-');
  final increases = variation.startsWith('+');
  if (!decreases && !increases) return true;
  return comparison.melhoraQuandoDiminui ? decreases : increases;
}

class InsightKpiStrip extends StatelessWidget {
  final List<InsightComparison> comparisons;

  const InsightKpiStrip({super.key, required this.comparisons});

  @override
  Widget build(BuildContext context) {
    if (comparisons.isEmpty) return const SizedBox.shrink();
    final visible = comparisons.take(3).toList();

    return Semantics(
      container: true,
      label: 'Indicadores do período',
      child: IntrinsicHeight(
        child: Row(
          key: const ValueKey('insight-kpi-strip'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < visible.length; index++) ...[
              if (index > 0)
                const VerticalDivider(
                  width: AppSpacing.xxl,
                  thickness: 1,
                  color: AppColors.borderSubtle,
                ),
              Expanded(child: _KpiCell(comparison: visible[index])),
            ],
          ],
        ),
      ),
    );
  }
}

class _KpiCell extends StatelessWidget {
  final InsightComparison comparison;

  const _KpiCell({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final isPositive = comparisonVariationIsPositive(comparison);
    final color = isPositive ? AppColors.success : AppColors.danger;

    return Column(
      key: ValueKey('kpi-${comparison.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${formatInsightNumber(comparison.agora)}${comparison.unidade}',
          style: AppTypography.pageTitle.copyWith(
            color: AppColors.textPrimary,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          comparison.titulo,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            height: 1.3,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DecoratedBox(
          key: ValueKey('kpi-variation-${comparison.id}'),
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
              comparison.variacao,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
