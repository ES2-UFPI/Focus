/// Testes da tela de Atividades Acadêmicas.
///
/// - Unidade: AgendaProvider (carga, erro e separação pendentes/concluídas),
///   com a rede isolada por um fake do AgendaService.
/// - Integração (widget): AtividadesScreen renderizada com o provider real
///   alimentado pelo fake — resumo, agrupamento por urgência, filtros,
///   faixa de concluídas e to-do list inline.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/models/agenda_model.dart';
import 'package:frontend/providers/agenda_provider.dart';
import 'package:frontend/screens/atividades_screen.dart';
import 'package:frontend/services/agenda_service.dart';

// ---------------------------------------------------------------------------
// Dados e fakes (sem rede)
// ---------------------------------------------------------------------------

AgendaItem _evento({
  required String id,
  required String titulo,
  required String tipoEvento,
  required int diasRestantes,
  bool concluido = false,
  String? urgencia,
  String disciplina = 'Cálculo I',
}) {
  final data = DateTime.now().add(Duration(days: diasRestantes));
  return AgendaItem(
    tipo: 'EVENTO_ACADEMICO',
    id: id,
    titulo: titulo,
    data:
        '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}',
    timestamp: data,
    disciplinaNome: disciplina,
    tipoEvento: tipoEvento,
    urgencia: urgencia,
    diasRestantes: diasRestantes,
    concluido: concluido,
  );
}

List<AgendaItem> _agendaPadrao() => [
      _evento(
        id: 'ev-atrasada',
        titulo: 'Relatório de Cinemática',
        tipoEvento: 'TRABALHO',
        diasRestantes: -2,
        urgencia: 'ATRASADO',
      ),
      _evento(
        id: 'ev-semana',
        titulo: 'Prova de Cálculo I',
        tipoEvento: 'PROVA',
        diasRestantes: 2,
      ),
      _evento(
        id: 'ev-depois',
        titulo: 'Seminário de Modelagem ER',
        tipoEvento: 'SEMINARIO',
        diasRestantes: 12,
      ),
      _evento(
        id: 'ev-concluida',
        titulo: 'Trabalho de Química',
        tipoEvento: 'TRABALHO',
        diasRestantes: -5,
        concluido: true,
      ),
    ];

class FakeAgendaService extends AgendaService {
  List<AgendaItem> itens;
  bool falhar = false;
  int chamadas = 0;

  FakeAgendaService({List<AgendaItem>? itens}) : itens = itens ?? [];

  @override
  Future<AgendaResponse> getAgenda() async {
    chamadas++;
    if (falhar) {
      throw AgendaServiceException('Falha simulada de rede.');
    }
    return AgendaResponse(itens: itens, recomendacoes: []);
  }
}

Widget _appComTela(AgendaProvider provider) {
  return ChangeNotifierProvider<AgendaProvider>.value(
    value: provider,
    child: const MaterialApp(
      home: Scaffold(body: AtividadesScreen()),
    ),
  );
}

void main() {
  // -------------------------------------------------------------------------
  // Unidade — AgendaProvider
  // -------------------------------------------------------------------------
  group('AgendaProvider (unidade) —', () {
    test('fetchAgenda carrega os itens e limpa o erro', () async {
      final service = FakeAgendaService(itens: _agendaPadrao());
      final provider = AgendaProvider(service: service);

      await provider.fetchAgenda();

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.itens, hasLength(4));
      expect(service.chamadas, 1);
    });

    test('separa itens pendentes e concluídos', () async {
      final provider =
          AgendaProvider(service: FakeAgendaService(itens: _agendaPadrao()));

      await provider.fetchAgenda();

      expect(provider.itensPendentes, hasLength(3));
      expect(
        provider.itensPendentes.every((i) => i.concluido != true),
        isTrue,
      );
      expect(provider.itensConcluidos, hasLength(1));
      expect(provider.itensConcluidos.single.titulo, 'Trabalho de Química');
    });

    test('falha do service popula errorMessage', () async {
      final service = FakeAgendaService()..falhar = true;
      final provider = AgendaProvider(service: service);

      await provider.fetchAgenda();

      expect(provider.errorMessage, 'Falha simulada de rede.');
      expect(provider.itens, isEmpty);

      // Uma nova tentativa bem-sucedida limpa o erro.
      service.falhar = false;
      service.itens = _agendaPadrao();
      await provider.fetchAgenda();
      expect(provider.errorMessage, isNull);
      expect(provider.itens, hasLength(4));
    });
  });

  // -------------------------------------------------------------------------
  // Integração (widget) — AtividadesScreen
  // -------------------------------------------------------------------------
  group('AtividadesScreen (integração) —', () {
    testWidgets('mostra o resumo com pendentes, urgentes e concluídas',
        (tester) async {
      final provider =
          AgendaProvider(service: FakeAgendaService(itens: _agendaPadrao()));

      await tester.pumpWidget(_appComTela(provider));
      await tester.pumpAndSettle();

      expect(find.text('Atividades Acadêmicas'), findsOneWidget);
      expect(find.text('Pendentes'), findsOneWidget);
      expect(find.text('Até 3 dias'), findsOneWidget);
      expect(find.text('Concluídas'), findsOneWidget);
      // 3 pendentes; 2 urgentes (atrasada + prova em 2 dias); 1 concluída.
      expect(find.text('3'), findsWidgets);
      expect(find.text('2'), findsWidgets);
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('agrupa as atividades por urgência', (tester) async {
      final provider =
          AgendaProvider(service: FakeAgendaService(itens: _agendaPadrao()));

      await tester.pumpWidget(_appComTela(provider));
      await tester.pumpAndSettle();

      expect(find.text('Atrasadas'), findsOneWidget);
      expect(find.text('Esta semana'), findsOneWidget);
      expect(find.text('Depois'), findsOneWidget);

      expect(find.text('Relatório de Cinemática'), findsOneWidget);
      expect(find.text('Prova de Cálculo I'), findsOneWidget);
      expect(find.text('Seminário de Modelagem ER'), findsOneWidget);
      // Concluída não aparece nas colunas de urgência.
      expect(find.text('Trabalho de Química'), findsNothing);
    });

    testWidgets('filtro por tipo esconde os outros tipos', (tester) async {
      final provider =
          AgendaProvider(service: FakeAgendaService(itens: _agendaPadrao()));

      await tester.pumpWidget(_appComTela(provider));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Provas'));
      await tester.pumpAndSettle();

      expect(find.text('Prova de Cálculo I'), findsOneWidget);
      expect(find.text('Relatório de Cinemática'), findsNothing);
      expect(find.text('Seminário de Modelagem ER'), findsNothing);
      // Grupos sem itens mostram o placeholder.
      expect(find.text('Nada por aqui.'), findsWidgets);
    });

    testWidgets('switch "Mostrar concluídas" exibe a faixa de concluídas',
        (tester) async {
      final provider =
          AgendaProvider(service: FakeAgendaService(itens: _agendaPadrao()));

      await tester.pumpWidget(_appComTela(provider));
      await tester.pumpAndSettle();

      expect(find.text('Trabalho de Química'), findsNothing);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Trabalho de Química'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Trabalho de Química'), findsOneWidget);
      expect(find.byTooltip('Voltar para pendentes'), findsOneWidget);

      // Desligar o switch esconde a faixa de novo.
      await tester.scrollUntilVisible(
        find.byType(Switch),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('Trabalho de Química'), findsNothing);
    });

    testWidgets('to-do inline: expandir, adicionar e concluir tarefa',
        (tester) async {
      final provider = AgendaProvider(
        service: FakeAgendaService(itens: [
          _evento(
            id: 'ev-1',
            titulo: 'Prova de Cálculo I',
            tipoEvento: 'PROVA',
            diasRestantes: 2,
          ),
        ]),
      );

      await tester.pumpWidget(_appComTela(provider));
      await tester.pumpAndSettle();

      // Sem tarefas: progresso 0/0 e campo ainda oculto.
      expect(find.text('0/0'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Adicionar tarefa...'),
          findsNothing);

      // Expande o card (rola até o botão, que fica abaixo da dobra).
      await tester.ensureVisible(find.text('To-do'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('To-do'));
      await tester.pumpAndSettle();
      final campo = find.widgetWithText(TextField, 'Adicionar tarefa...');
      expect(campo, findsOneWidget);

      // Adiciona uma tarefa via Enter.
      await tester.enterText(campo, 'Revisar derivadas');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Revisar derivadas'), findsOneWidget);
      expect(find.text('0/1'), findsOneWidget);

      // Marca a tarefa como feita: o progresso vira 1/1.
      await tester.tap(find.text('Revisar derivadas'));
      // O toggle é no checkbox, não no texto — toca no quadrado ao lado.
      await tester.pumpAndSettle();
      final checkbox = find.descendant(
        of: find.byType(AtividadesScreen),
        matching: find.byWidgetPredicate(
          (w) => w is InkWell && w.borderRadius == BorderRadius.circular(6),
        ),
      );
      await tester.tap(checkbox.first);
      await tester.pumpAndSettle();
      expect(find.text('1/1'), findsOneWidget);
    });

    testWidgets('erro do provider mostra estado de erro com retry',
        (tester) async {
      final service = FakeAgendaService()..falhar = true;
      final provider = AgendaProvider(service: service);

      await tester.pumpWidget(_appComTela(provider));
      await tester.pumpAndSettle();

      expect(find.text('Falha simulada de rede.'), findsOneWidget);

      // Retry com o backend "de volta" recarrega a tela.
      service.falhar = false;
      service.itens = _agendaPadrao();
      await tester.tap(find.text('Tentar Novamente'));
      await tester.pumpAndSettle();

      expect(find.text('Prova de Cálculo I'), findsOneWidget);
    });

    testWidgets('sem atividades mostra o estado vazio', (tester) async {
      final provider = AgendaProvider(service: FakeAgendaService());

      await tester.pumpWidget(_appComTela(provider));
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma atividade encontrada.'), findsOneWidget);
      expect(find.text('Adicionar atividade'), findsOneWidget);
    });
  });
}
