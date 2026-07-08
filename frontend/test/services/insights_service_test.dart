import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/insights_model.dart';
import 'package:frontend/services/insights_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('fetchInsights parses the insights list from the API', () async {
    final client = MockClient((request) async {
      expect(request.url.path, endsWith('/api/insights/'));
      return http.Response(
        jsonEncode([
          {
            'id': 'melhor_horario',
            'tipo': 'melhor_horario',
            'titulo': 'Rende mais de manhã',
            'descricao': 'Produtividade maior pela manhã.',
            'numeros': {'manha': 4.1, 'noite': 2.4},
            'categoria': 'tempo',
            'amostra': 18,
            'confianca': 'alta',
            'natureza': 'observacional',
            'severidade': 'positivo',
          }
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = InsightsService(client: client);

    final insights = await service.fetchInsights();

    expect(insights, hasLength(1));
    expect(insights.first, isA<Insight>());
    expect(insights.first.tipo, 'melhor_horario');
  });

  test('fetchJourney parses the journey from the evolucao endpoint', () async {
    final client = MockClient((request) async {
      expect(request.url.path, endsWith('/api/insights/evolucao/'));
      return http.Response(
        jsonEncode({
          'periodo': '01/07 a 07/07',
          'atualizado_em': 'Atualizado em 07/07 19:30',
          'jornada': [
            {
              'data': 'Há 3 dias',
              'tipo': 'melhora',
              'texto': 'Os cancelamentos caíram de 60% para 25%.',
              'insight_tipo': 'taxa_furo',
            }
          ],
          'dimensoes': [],
          'comparacoes': [],
          'experimentos': [],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = InsightsService(client: client);

    final journey = await service.fetchJourney();

    expect(journey, hasLength(1));
    expect(journey.first.tipo, 'melhora');
    expect(journey.first.insightTipo, 'taxa_furo');
  });

  test('fetchJourney returns empty when there is no observed improvement',
      () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'periodo': '01/07 a 07/07',
          'atualizado_em': 'Atualizado em 07/07 19:30',
          'jornada': [],
          'dimensoes': [],
          'comparacoes': [],
          'experimentos': [],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = InsightsService(client: client);

    expect(await service.fetchJourney(), isEmpty);
  });

  test('fetchDashboard parses the evolution dashboard', () async {
    final client = MockClient((request) async {
      expect(request.url.path, endsWith('/api/insights/evolucao/'));
      return http.Response(
        jsonEncode({
          'periodo': '26/05 a 07/07',
          'atualizado_em': 'Atualizado hoje',
          'dimensoes': [
            {'id': 'tempo', 'titulo': 'Tempo', 'severidade': 'positivo'}
          ],
          'comparacoes': [],
          'experimentos': [],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = InsightsService(client: client);

    final dashboard = await service.fetchDashboard();

    expect(dashboard, isA<InsightsDashboard>());
    expect(dashboard.dimensoes, hasLength(1));
  });

  test('submitFeedback posts to the feedback endpoint', () async {
    var chamou = false;
    final client = MockClient((request) async {
      chamou = true;
      expect(request.method, 'POST');
      expect(request.url.path, endsWith('/api/insights/ins-123/feedback/'));
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['useful'], false);
      return http.Response('{}', 200);
    });
    final service = InsightsService(client: client);

    await expectLater(
      service.submitFeedback(insightId: 'ins-123', useful: false, reason: 'x'),
      completes,
    );
    expect(chamou, isTrue);
  });
}
