import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/insights_model.dart';
import 'insight_presentation.dart';

const double _calloutHeight = 34;
const double _chartTopInset = 38;
const double _chartBottomInset = 52;

Offset calculateInsightCalloutOffset({
  required Size size,
  required String chartType,
  required int pointCount,
  required int highlightIndex,
  required double highlightValue,
  required double minY,
  required double maxY,
  double calloutWidth = 168,
}) {
  final safeCount = math.max(1, pointCount);
  final index = highlightIndex.clamp(0, safeCount - 1);
  final resolvedWidth = math.min(calloutWidth, size.width);
  final centerX = chartType == 'linha'
      ? safeCount == 1
            ? size.width / 2
            : index * size.width / (safeCount - 1)
      : (index + 0.5) * size.width / safeCount;
  final x = (centerX - resolvedWidth / 2)
      .clamp(0.0, math.max(0.0, size.width - resolvedWidth))
      .toDouble();

  final plotHeight = math.max(
    1.0,
    size.height - _chartTopInset - _chartBottomInset,
  );
  final range = math.max(0.0001, maxY - minY);
  final normalized = ((highlightValue - minY) / range).clamp(0.0, 1.0);
  final pointY = _chartTopInset + (1 - normalized) * plotHeight;
  final y = (pointY - _calloutHeight - AppSpacing.xs)
      .clamp(0.0, math.max(0.0, size.height - _calloutHeight))
      .toDouble();
  return Offset(x, y);
}

class AnnotatedInsightChart extends StatelessWidget {
  final InsightChart chart;
  final Color color;
  final String? semanticLabel;

  const AnnotatedInsightChart({
    super.key,
    required this.chart,
    required this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final length = math.min(chart.labels.length, chart.valores.length);
    if (length == 0) return const SizedBox.shrink();

    final labels = chart.labels.take(length).toList();
    final values = chart.valores
        .take(length)
        .map((value) => value.toDouble())
        .toList();
    final highlightIndex = (chart.destaqueIndex ?? length - 1).clamp(
      0,
      length - 1,
    );
    final isLine = chart.tipo == 'linha';
    final bounds = _chartBounds(values, isLine: isLine);
    final average = values.reduce((a, b) => a + b) / values.length;

    return Semantics(
      container: true,
      label: semanticLabel ?? 'Gráfico anotado do insight',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final calloutWidth = math.min(168.0, size.width);
          final calloutOffset = calculateInsightCalloutOffset(
            size: size,
            chartType: isLine ? 'linha' : 'barras',
            pointCount: values.length,
            highlightIndex: highlightIndex,
            highlightValue: values[highlightIndex],
            minY: bounds.$1,
            maxY: bounds.$2,
            calloutWidth: calloutWidth,
          );

          return Stack(
            key: const ValueKey('annotated-insight-chart'),
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                top: _chartTopInset,
                child: isLine
                    ? _buildLineChart(
                        labels,
                        values,
                        highlightIndex,
                        bounds,
                        average,
                      )
                    : _buildBarChart(
                        labels,
                        values,
                        highlightIndex,
                        bounds,
                        average,
                      ),
              ),
              Positioned(
                key: const ValueKey('chart-callout'),
                left: calloutOffset.dx,
                top: calloutOffset.dy,
                width: calloutWidth,
                height: _calloutHeight,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Center(
                        child: Text(
                          '${labels[highlightIndex]} · '
                          '${formatInsightNumber(values[highlightIndex])}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textInverted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBarChart(
    List<String> labels,
    List<double> values,
    int highlightIndex,
    (double, double) bounds,
    double average,
  ) {
    return BarChart(
      BarChartData(
        minY: bounds.$1,
        maxY: bounds.$2,
        alignment: BarChartAlignment.spaceEvenly,
        extraLinesData: _averageLine(average),
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
                    : color.withValues(alpha: 0.28),
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

  Widget _buildLineChart(
    List<String> labels,
    List<double> values,
    int highlightIndex,
    (double, double) bounds,
    double average,
  ) {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(1, values.length - 1).toDouble(),
        minY: bounds.$1,
        maxY: bounds.$2,
        extraLinesData: _averageLine(average),
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
              color: color.withValues(alpha: 0.08),
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

  ExtraLinesData _averageLine(double average) {
    return ExtraLinesData(
      horizontalLines: [
        HorizontalLine(
          y: average,
          color: AppColors.textMuted.withValues(alpha: 0.55),
          strokeWidth: 1,
          dashArray: [4, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
            labelResolver: (_) => 'Média ${formatInsightNumber(average)}',
          ),
        ),
      ],
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
          reservedSize: _chartBottomInset,
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

  (double, double) _chartBounds(List<double> values, {required bool isLine}) {
    final maxValue = values.reduce(math.max);
    if (!isLine) return (0, maxValue == 0 ? 1 : maxValue * 1.25);
    final minValue = values.reduce(math.min);
    final minY = math.max(0, minValue - 1).toDouble();
    final maxY = maxValue + 1;
    return (minY, maxY <= minY ? minY + 1 : maxY);
  }
}
