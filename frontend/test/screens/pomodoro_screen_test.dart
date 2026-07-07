import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/models/agenda_model.dart';
import 'package:frontend/models/disciplina_model.dart';
import 'package:frontend/providers/pomodoro_provider.dart';
import 'package:frontend/screens/pomodoro_screen.dart';
import 'package:frontend/services/agenda_service.dart';
import 'package:frontend/services/disciplina_service.dart';
import 'package:frontend/services/sessao_estudo_service.dart';

final _disciplina = Disciplina(
  id: 'disc-1',
  aluno: 'aluno-1',
  nome: 'Matemática',
  cor: '#2196F3',
  metaHorasSemanais: 5,
  ativo: true,
);

final _sessao = SessaoEstudoResumo(
  id: 'sessao-1',
  disciplinaId: 'disc-1',
  disciplinaNome: 'Matemática',
  inicio: DateTime(2026, 7, 10, 18),
  fim: DateTime(2026, 7, 10, 20),
  duracaoRealizada: 0,
  status: 'AGENDADO',
);

class _DisciplinaService extends DisciplinaService {
  @override
  Future<List<Disciplina>> getDisciplinas() async => [_disciplina];
}

class _AgendaService extends AgendaService {
  @override
  Future<AgendaResponse> getAgenda() async {
    return AgendaResponse(itens: [], recomendacoes: []);
  }
}

class _SessaoService extends SessaoEstudoService {
  final List<int> produtividades = [];
  final List<String?> statusAvaliacoes = [];

  @override
  Future<List<SessaoEstudoResumo>> listarSessoes() async => [_sessao];

  @override
  Future<List<SessaoEstudoResumo>> getSemanaAtual() async => [];

  @override
  Future<void> editarSessao({
    required String sessaoId,
    required String disciplinaId,
    required DateTime inicio,
    required DateTime fim,
    String? descricao,
    required String status,
    required int duracaoRealizada,
    required int? energiaInicial,
    required int interrupcoes,
    required String? tipoAtividade,
  }) async {}

  @override
  Future<String> criarBlocoPomodoro({
    required String sessaoId,
    required int numeroCiclo,
    required DateTime inicio,
    required DateTime fim,
    required int duracaoPlanejadaSegundos,
    required int duracaoRealizadaSegundos,
    required int interrupcoes,
    required String status,
  }) async {
    return 'bloco-1';
  }

  @override
  Future<void> avaliarBlocoPomodoro({
    required String blocoId,
    required int produtividade,
    String? status,
  }) async {
    produtividades.add(produtividade);
    statusAvaliacoes.add(status);
  }
}

void main() {
  testWidgets('energia fica acessível e mostra a resposta selecionada', (
    tester,
  ) async {
    final provider = PomodoroProvider(
      disciplinaService: _DisciplinaService(),
      agendaService: _AgendaService(),
      sessaoEstudoService: _SessaoService(),
      somAtivado: false,
    );

    await tester.pumpWidget(
      MaterialApp(home: PomodoroScreen(provider: provider)),
    );
    await tester.pumpAndSettle();

    provider.selecionarDisciplina(_disciplina);
    provider.selecionarSessao(_sessao);
    await tester.pump();

    expect(find.text('Informar energia'), findsOneWidget);

    await tester.ensureVisible(find.text('Iniciar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar'));
    await tester.pumpAndSettle();
    expect(find.text('Como está sua energia agora?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('energia-4')));
    await tester.pumpAndSettle();

    expect(find.text('Energia inicial: 4/5 · Alterar'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();
  });

  testWidgets('fim natural pergunta produtividade com resposta de um toque', (
    tester,
  ) async {
    final sessaoService = _SessaoService();
    final provider = PomodoroProvider(
      disciplinaService: _DisciplinaService(),
      agendaService: _AgendaService(),
      sessaoEstudoService: sessaoService,
      somAtivado: false,
    );

    await tester.pumpWidget(
      MaterialApp(home: PomodoroScreen(provider: provider)),
    );
    await tester.pumpAndSettle();

    provider.selecionarDisciplina(_disciplina);
    provider.selecionarSessao(_sessao);
    provider.definirEnergiaInicial(3);
    provider.ajustarDuracao(PomodoroMode.foco, -24);
    provider.toggle();

    await tester.pump(const Duration(seconds: 60));
    await tester.pumpAndSettle();

    expect(find.text('Como foi seu foco neste bloco?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('produtividade-5')));
    await tester.pumpAndSettle();

    expect(sessaoService.produtividades, [5]);
    expect(find.text('Como foi seu foco neste bloco?'), findsNothing);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();
  });

  testWidgets('pular pergunta e uma nota valida o bloco antecipado', (
    tester,
  ) async {
    final sessaoService = _SessaoService();
    final provider = PomodoroProvider(
      disciplinaService: _DisciplinaService(),
      agendaService: _AgendaService(),
      sessaoEstudoService: sessaoService,
      somAtivado: false,
    );

    await tester.pumpWidget(
      MaterialApp(home: PomodoroScreen(provider: provider)),
    );
    await tester.pumpAndSettle();

    provider.selecionarDisciplina(_disciplina);
    provider.selecionarSessao(_sessao);
    provider.definirEnergiaInicial(3);
    provider.toggle();
    await tester.pump(const Duration(seconds: 5));

    provider.skip();
    await tester.pumpAndSettle();

    expect(find.text('Como foi seu foco neste bloco?'), findsOneWidget);
    expect(find.text('Não responder e descartar bloco'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('produtividade-4')));
    await tester.pumpAndSettle();

    expect(sessaoService.produtividades, [4]);
    expect(sessaoService.statusAvaliacoes, ['ENCERRADO_ANTECIPADAMENTE']);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();
  });
}
