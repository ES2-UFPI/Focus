import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/insights_model.dart';

class EditorialBriefing {
  final String text;
  final String? ctaLabel;
  final Insight? anchor;

  const EditorialBriefing({required this.text, this.ctaLabel, this.anchor});
}

EditorialBriefing buildEditorialBriefing({
  required List<Insight> insights,
  required InsightsDashboard dashboard,
  Insight? anchor,
}) {
  final eligible = insights
      .where((insight) => insight.confianca != 'insuficiente')
      .toList();
  final criticalCount = eligible
      .where((insight) => insight.severidade == 'critico')
      .length;
  final attentionCount = eligible
      .where((insight) => insight.severidade == 'atencao')
      .length;
  final positiveCount = eligible
      .where((insight) => insight.severidade == 'positivo')
      .length;

  final period = dashboard.periodo.trim().isEmpty
      ? 'Neste período'
      : 'Entre ${dashboard.periodo}';
  final overview = _overviewSentence(
    period: period,
    criticalCount: criticalCount,
    attentionCount: attentionCount,
    positiveCount: positiveCount,
  );

  final resolvedAnchor = anchor ?? _mostRelevantInsight(eligible);
  final dimension = _mostRelevantDimension(dashboard.dimensoes);
  final reason = resolvedAnchor?.descricao.trim().isNotEmpty == true
      ? resolvedAnchor!.descricao.trim()
      : dimension == null
      ? ''
      : '${dimension.resumo.trim()} ${dimension.tendencia.trim()}'.trim();
  final text = reason.isEmpty ? overview : '$overview $reason';

  return EditorialBriefing(
    text: text,
    ctaLabel: resolvedAnchor == null ? null : 'Ver evidência',
    anchor: resolvedAnchor,
  );
}

String _overviewSentence({
  required String period,
  required int criticalCount,
  required int attentionCount,
  required int positiveCount,
}) {
  if (criticalCount > 0) {
    return '$period, seus registros apontam '
        '${_count(criticalCount, 'ponto crítico', 'pontos críticos')}, '
        '${_count(attentionCount, 'ajuste que merece atenção', 'ajustes que merecem atenção')} '
        'e ${_count(positiveCount, 'avanço consistente', 'avanços consistentes')}.';
  }
  if (attentionCount > 0) {
    return '$period, não há alertas críticos; aparecem '
        '${_count(attentionCount, 'ajuste que merece atenção', 'ajustes que merecem atenção')} '
        'e ${_count(positiveCount, 'avanço consistente', 'avanços consistentes')}.';
  }
  return '$period, seus registros não mostram alertas e reúnem '
      '${_count(positiveCount, 'avanço consistente', 'avanços consistentes')}.';
}

String _count(int value, String singular, String plural) {
  return '$value ${value == 1 ? singular : plural}';
}

Insight? _mostRelevantInsight(List<Insight> insights) {
  for (final severity in ['critico', 'atencao', 'positivo', 'info']) {
    for (final insight in insights) {
      if (insight.severidade == severity) return insight;
    }
  }
  return null;
}

StudyDimension? _mostRelevantDimension(List<StudyDimension> dimensions) {
  for (final severity in ['critico', 'atencao', 'positivo', 'info']) {
    for (final dimension in dimensions) {
      if (dimension.severidade == severity) return dimension;
    }
  }
  return dimensions.isEmpty ? null : dimensions.first;
}

class InsightEditorialSummary extends StatefulWidget {
  final EditorialBriefing briefing;
  final ValueChanged<Insight> onOpen;

  const InsightEditorialSummary({
    super.key,
    required this.briefing,
    required this.onOpen,
  });

  @override
  State<InsightEditorialSummary> createState() =>
      _InsightEditorialSummaryState();
}

class _InsightEditorialSummaryState extends State<InsightEditorialSummary> {
  late final TapGestureRecognizer _ctaRecognizer;

  @override
  void initState() {
    super.initState();
    _ctaRecognizer = TapGestureRecognizer()..onTap = _handleTap;
  }

  @override
  void didUpdateWidget(covariant InsightEditorialSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ctaRecognizer.onTap = _handleTap;
  }

  @override
  void dispose() {
    _ctaRecognizer.dispose();
    super.dispose();
  }

  void _handleTap() {
    final anchor = widget.briefing.anchor;
    if (anchor != null) widget.onOpen(anchor);
  }

  @override
  Widget build(BuildContext context) {
    final ctaLabel = widget.briefing.ctaLabel;
    final anchor = widget.briefing.anchor;

    return Semantics(
      container: true,
      label: 'Resumo da semana',
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: widget.briefing.text),
            if (ctaLabel != null && anchor != null) ...[
              const TextSpan(text: ' '),
              TextSpan(
                text: ctaLabel,
                recognizer: _ctaRecognizer,
                style: AppTypography.bodyStrong.copyWith(
                  color: AppColors.subjectTeal,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.subjectTeal,
                ),
              ),
            ],
          ],
        ),
        key: const ValueKey('insight-editorial-summary'),
        style: AppTypography.body.copyWith(
          color: AppColors.textSecondary,
          fontSize: 16,
          height: 1.65,
        ),
      ),
    );
  }
}
