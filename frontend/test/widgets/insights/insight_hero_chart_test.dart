import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/insights/insight_hero_chart.dart';

void main() {
  test('places a bar callout over the exact space-evenly center', () {
    final offset = calculateInsightCalloutOffset(
      size: const Size(600, 280),
      chartType: 'barras',
      pointCount: 6,
      highlightIndex: 1,
      highlightValue: 4.2,
      minY: 0,
      maxY: 5.25,
    );

    expect(offset.dx, closeTo(66, 0.001));
    expect(offset.dy, closeTo(38, 0.001));
  });

  test('clamps callouts at chart edges', () {
    final first = calculateInsightCalloutOffset(
      size: const Size(200, 200),
      chartType: 'linha',
      pointCount: 5,
      highlightIndex: 0,
      highlightValue: 10,
      minY: 0,
      maxY: 10,
    );
    final last = calculateInsightCalloutOffset(
      size: const Size(200, 200),
      chartType: 'linha',
      pointCount: 5,
      highlightIndex: 4,
      highlightValue: 0,
      minY: 0,
      maxY: 10,
    );

    expect(first.dx, 0);
    expect(last.dx, 32);
    expect(first.dy, greaterThanOrEqualTo(0));
    expect(last.dy, lessThanOrEqualTo(166));
  });
}
