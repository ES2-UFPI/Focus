import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/app_theme.dart';
import '../models/insights_model.dart';
import '../widgets/insight_card.dart';

class InsightDetailScreen extends StatefulWidget {
  final Insight insight;
  final InsightFeedbackState? initialFeedback;
  final ValueChanged<InsightFeedbackState?>? onFeedbackChanged;
  final VoidCallback? onAction;

  const InsightDetailScreen({
    super.key,
    required this.insight,
    this.initialFeedback,
    this.onFeedbackChanged,
    this.onAction,
  });

  @override
  State<InsightDetailScreen> createState() => _InsightDetailScreenState();
}

class _InsightDetailScreenState extends State<InsightDetailScreen> {
  late InsightFeedbackState? _feedback;
  bool _showFeedbackReasons = false;

  Insight get _insight => widget.insight;

  Color get _accentColor {
    switch (_insight.severidade) {
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

  @override
  void initState() {
    super.initState();
    _feedback = widget.initialFeedback;
  }

  @override
  Widget build(BuildContext context) {
    final chart = _insight.grafico;
    final hasChart =
        chart != null && chart.labels.isNotEmpty && chart.valores.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Padding(
                  padding: AppSpacing.screen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverview(),
                      const SizedBox(height: AppSpacing.lg),
                      if (hasChart)
                        _SectionCard(
                          title: 'A evidência em gráfico',
                          icon: LucideIcons.chartNoAxesColumnIncreasing,
                          child: SizedBox(
                            height: 280,
                            child: _InsightChartView(
                              chart: chart,
                              color: _accentColor,
                            ),
                          ),
                        )
                      else
                        _SectionCard(
                          title: 'Números observados',
                          icon: LucideIcons.hash,
                          child: _NumbersFallback(
                            numeros: _insight.numeros,
                            color: _accentColor,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildEvidence(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildRecommendation(),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionCard(
                        title: 'Seu feedback',
                        icon: LucideIcons.messageCircle,
                        child: InsightFeedbackControl(
                          insightType: 'detail-${_insight.tipo}',
                          feedback: _feedback,
                          showReasons: _showFeedbackReasons,
                          onUseful: _markUseful,
                          onNotUseful: _toggleReasonPicker,
                          onSelectReason: _markNotUseful,
                          onClear: _clearFeedback,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 180,
      backgroundColor: AppColors.subjectTeal,
      foregroundColor: AppColors.textInverted,
      surfaceTintColor: Colors.transparent,
      title: const Text('Detalhe do insight'),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppGradients.reportsHeader),
          child: Stack(
            children: [
              Positioned(
                right: AppSpacing.xxl,
                bottom: AppSpacing.xxl,
                child: Icon(
                  LucideIcons.chartNoAxesCombined,
                  size: 96,
                  color: AppColors.textInverted.withValues(alpha: 0.14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverview() {
    return Container(
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
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _DetailBadge(
                label: _categoryLabel(_insight.categoria),
                icon: LucideIcons.layers3,
                color: _accentColor,
              ),
              if (_insight.disciplina != null)
                _DetailBadge(
                  label: _insight.disciplina!,
                  icon: LucideIcons.bookOpen,
                  color: AppColors.brandPrimary,
                ),
              _DetailBadge(
                label: _severityLabel(_insight.severidade),
                icon: LucideIcons.activity,
                color: _accentColor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _insight.titulo,
            style: AppTypography.pageTitle.copyWith(
              color: AppColors.textPrimary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _insight.descricao,
            style: AppTypography.body.copyWith(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Este é um padrão observacional dos seus registros, não uma '
            'relação comprovada de causa e efeito.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidence() {
    final sessions = _insight.sessoesEvidencia;

    return _SectionCard(
      title: 'Sessões que sustentam o padrão',
      icon: LucideIcons.listChecks,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _DetailBadge(
                label:
                    '${_insight.amostra} ${_insight.amostra == 1 ? 'sessão' : 'sessões'} na amostra',
                icon: LucideIcons.database,
                color: AppColors.textMuted,
              ),
              _DetailBadge(
                label: _confidenceLabel(_insight.confianca),
                icon: LucideIcons.shieldCheck,
                color: _confidenceColor(_insight.confianca),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (sessions.isEmpty)
            Text(
              'As sessões individuais ainda não estão disponíveis para este '
              'insight. Os números agregados acima resumem a evidência atual.',
              style: AppTypography.body.copyWith(
                color: AppColors.textMuted,
                height: 1.45,
              ),
            )
          else
            ...List.generate(
              sessions.length,
              (index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index == sessions.length - 1 ? 0 : AppSpacing.sm,
                ),
                child: _EvidenceRow(session: sessions[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendation() {
    return _SectionCard(
      title: 'Recomendação observacional',
      icon: LucideIcons.lightbulb,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _recommendation,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (_insight.acao != null) ...[
            const SizedBox(height: AppSpacing.lg),
            ShadButton(
              key: ValueKey('detail-action-${_insight.tipo}'),
              width: double.infinity,
              backgroundColor: AppColors.brandPrimary,
              hoverBackgroundColor: AppColors.brandPrimaryDark,
              foregroundColor: AppColors.textInverted,
              leading: const Icon(
                LucideIcons.calendarPlus,
                size: AppSizes.iconMd,
              ),
              onPressed: widget.onAction,
              child: Text(_insight.acao!.label),
            ),
          ],
        ],
      ),
    );
  }

  String get _recommendation {
    switch (_insight.tipo) {
      case 'melhor_horario':
        return 'Experimente reservar as tarefas que exigem mais concentração '
            'para o período da manhã e observe se o padrão se mantém.';
      case 'duracao_ideal':
        return 'Considere blocos de até 50 minutos, seguidos por uma pausa '
            'curta, e compare sua produtividade nas próximas sessões.';
      case 'vies_estimativa':
        return 'Ao planejar Cálculo, acrescente uma margem de aproximadamente '
            '40% ao tempo inicial e ajuste com seus próximos registros.';
      case 'taxa_furo':
        return 'Teste outro horário para as sessões de sexta e acompanhe se a '
            'taxa de cancelamento observada diminui.';
      case 'cramming':
        return 'Distribua uma parte do estudo nos dias anteriores à prova para '
            'reduzir a concentração de horas nas últimas 48h.';
      case 'sono_x_rendimento':
        return 'Observe seu rendimento após noites mais curtas e, quando '
            'possível, evite colocar tarefas mais exigentes nesses dias.';
      default:
        return 'Use este padrão como hipótese para organizar as próximas '
            'sessões e continue registrando os resultados para reavaliá-lo.';
    }
  }

  void _markUseful() {
    _updateFeedback(
      const InsightFeedbackState(status: InsightFeedbackStatus.useful),
    );
  }

  void _toggleReasonPicker() {
    setState(() => _showFeedbackReasons = !_showFeedbackReasons);
  }

  void _markNotUseful(String reason) {
    _updateFeedback(
      InsightFeedbackState(
        status: InsightFeedbackStatus.rejected,
        reason: reason,
      ),
    );
  }

  void _clearFeedback() {
    _updateFeedback(null);
  }

  void _updateFeedback(InsightFeedbackState? feedback) {
    setState(() {
      _feedback = feedback;
      _showFeedbackReasons = false;
    });
    widget.onFeedbackChanged?.call(feedback);
  }
}

class _InsightChartView extends StatelessWidget {
  final InsightChart chart;
  final Color color;

  const _InsightChartView({required this.chart, required this.color});

  @override
  Widget build(BuildContext context) {
    final length = math.min(chart.labels.length, chart.valores.length);
    if (length == 0) return const SizedBox.shrink();

    final labels = chart.labels.take(length).toList();
    final values = chart.valores
        .take(length)
        .map((value) => value.toDouble())
        .toList();

    if (chart.tipo == 'linha') {
      return _buildLineChart(labels, values);
    }
    return _buildBarChart(labels, values);
  }

  Widget _buildBarChart(List<String> labels, List<double> values) {
    final maxValue = values.reduce(math.max);
    final highlightIndex = _highlightIndex(values.length);

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxValue == 0 ? 1 : maxValue * 1.25,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.borderSubtle, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: _titles(labels),
        barTouchData: BarTouchData(enabled: true),
        barGroups: List.generate(
          values.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: values[index],
                width: values.length > 4 ? 18 : 28,
                color: index == highlightIndex
                    ? color
                    : color.withValues(alpha: 0.32),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadii.sm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<String> labels, List<double> values) {
    final maxValue = values.reduce(math.max);
    final minValue = values.reduce(math.min);
    final highlightIndex = _highlightIndex(values.length);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (values.length - 1).toDouble(),
        minY: math.max(0, minValue - 1),
        maxY: maxValue + 1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.borderSubtle, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: _titles(labels),
        lineTouchData: LineTouchData(enabled: true),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              values.length,
              (index) => FlSpot(index.toDouble(), values[index]),
            ),
            isCurved: true,
            color: color,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.1),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, _, _) {
                final highlighted = spot.x.toInt() == highlightIndex;
                return FlDotCirclePainter(
                  radius: highlighted ? 6 : 3,
                  color: highlighted ? color : AppColors.surface,
                  strokeWidth: 2,
                  strokeColor: color,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  FlTitlesData _titles(List<String> labels) {
    return FlTitlesData(
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          reservedSize: 52,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= labels.length || value != index) {
              return const SizedBox.shrink();
            }
            return SideTitleWidget(
              meta: meta,
              space: AppSpacing.sm,
              child: SizedBox(
                width: labels.length > 4 ? 54 : 84,
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: labels.length > 4 ? 9 : 11,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  int _highlightIndex(int length) {
    final requested = chart.destaqueIndex ?? length - 1;
    return requested.clamp(0, length - 1);
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            children: [
              Icon(icon, size: AppSizes.iconMd, color: AppColors.subjectTeal),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.cardTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _NumbersFallback extends StatelessWidget {
  final Map<String, num> numeros;
  final Color color;

  const _NumbersFallback({required this.numeros, required this.color});

  @override
  Widget build(BuildContext context) {
    if (numeros.isEmpty) {
      return Text(
        'Ainda não há números detalhados para este insight.',
        style: AppTypography.body.copyWith(color: AppColors.textMuted),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: numeros.entries
          .map(
            (entry) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: color.withValues(alpha: 0.16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatNumber(entry.value),
                    style: AppTypography.bodyStrong.copyWith(color: color),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    entry.key.replaceAll('_', ' '),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _EvidenceRow extends StatelessWidget {
  final InsightEvidenceSession session;

  const _EvidenceRow({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.subjectTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(
              LucideIcons.calendarCheck,
              size: AppSizes.iconMd,
              color: AppColors.subjectTeal,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.disciplina ?? 'Sessão geral',
                  style: AppTypography.bodyStrong.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  _formatDate(session.data),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                session.duracaoMin == 0
                    ? 'Cancelada'
                    : '${session.duracaoMin} min',
                style: AppTypography.bodyStrong.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (session.produtividade > 0)
                Text(
                  '${_formatNumber(session.produtividade)} / 5',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _DetailBadge({
    required this.label,
    required this.icon,
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
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: color.withValues(alpha: 0.18)),
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

String _formatDate(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _formatNumber(num value) {
  if (value % 1 == 0) return value.toInt().toString();
  return value.toStringAsFixed(1).replaceAll('.', ',');
}

String _categoryLabel(String value) {
  switch (value) {
    case 'tempo':
      return 'Tempo';
    case 'foco':
      return 'Foco';
    case 'planejamento':
      return 'Planejamento';
    case 'rotina':
      return 'Rotina';
    case 'saude':
      return 'Saúde';
    case 'metodo':
      return 'Método';
    default:
      return value;
  }
}

String _severityLabel(String value) {
  switch (value) {
    case 'positivo':
      return 'Conquista';
    case 'atencao':
      return 'Atenção';
    case 'critico':
      return 'Crítico';
    default:
      return 'Informativo';
  }
}

String _confidenceLabel(String value) {
  switch (value) {
    case 'alta':
      return 'Confiança alta';
    case 'media':
      return 'Confiança média';
    default:
      return 'Dados insuficientes';
  }
}

Color _confidenceColor(String value) {
  switch (value) {
    case 'alta':
      return AppColors.success;
    case 'media':
      return AppColors.warningStrong;
    default:
      return AppColors.neutral;
  }
}
