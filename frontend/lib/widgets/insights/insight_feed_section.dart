import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/insights_model.dart';

class InsightFeedGroups {
  final List<Insight> attention;
  final List<Insight> discoveries;

  const InsightFeedGroups({required this.attention, required this.discoveries});
}

InsightFeedGroups groupInsightsByPriority(
  List<Insight> insights, {
  String? disciplina,
}) {
  final eligible = insights.where(
    (insight) =>
        insight.confianca != 'insuficiente' &&
        (disciplina == null || insight.disciplina == disciplina),
  );
  final attention =
      eligible
          .where(
            (insight) =>
                insight.severidade == 'critico' ||
                insight.severidade == 'atencao',
          )
          .toList()
        ..sort((a, b) {
          final aPriority = a.severidade == 'critico' ? 0 : 1;
          final bPriority = b.severidade == 'critico' ? 0 : 1;
          return aPriority.compareTo(bPriority);
        });
  final discoveries = eligible
      .where(
        (insight) =>
            insight.severidade == 'positivo' || insight.severidade == 'info',
      )
      .toList();
  return InsightFeedGroups(
    attention: List.unmodifiable(attention),
    discoveries: List.unmodifiable(discoveries),
  );
}

class InsightFeedSection extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const InsightFeedSection({
    super.key,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.cardTitle.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var index = 0; index < rows.length; index++) ...[
          if (index > 0)
            const Divider(height: 1, color: AppColors.borderSubtle),
          rows[index],
        ],
      ],
    );
  }
}
