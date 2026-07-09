/// Testes de unidade do PomodoroProvider (o "cérebro" do timer Pomodoro).
///
/// Rede é isolada com fakes dos services; o Timer.periodic de 1s é
/// controlado com fakeAsync, então nenhum teste espera tempo real.
library;

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/models/agenda_model.dart';
import 'package:frontend/models/disciplina_model.dart';
import 'package:frontend/providers/pomodoro_provider.dart';
import 'package:frontend/services/agenda_service.dart';
import 'package:frontend/services/disciplina_service.dart';
import 'package:frontend/services/sessao_estudo_service.dart';

// ---------------------------------------------------------------------------
// Fakes dos services (sem rede)
// ---------------------------------------------------------------------------

final _disciplina = Disciplina(
  id: 'disc-1',
  aluno: 'aluno-1',
  nome: 'Matemática',
  cor: '#2196F3',
  metaHorasSemanais: 5,
  ativo: true,
);

final _segundaDisciplina = Disciplina(
  id: 'disc-2',
  aluno: 'aluno-1',
  nome: 'Historia',
  cor: '#009688',
  metaHorasSemanais: 3,
  ativo: true,
);

SessaoEstudoResumo _novaSessaoAgendada() => SessaoEstudoResumo(
  id: 'sessao-1',
  disciplinaId: 'disc-1',
  disciplinaNome: 'Matemática',
  inicio: DateTime(2026, 7, 10, 18, 0),
  fim: DateTime(2026, 7, 10, 20, 0),
  duracaoRealizada: 0,
  status: 'AGENDADO',
);

class FakeDisciplinaService extends DisciplinaService {
  final List<Disciplina> disciplinas;

  FakeDisciplinaService([List<Disciplina>? disciplinas])
    : disciplinas = disciplinas ?? [_disciplina];

  @override
  Future<List<Disciplina>> getDisciplinas() async => disciplinas;
}

class FakeAgendaService extends AgendaService {
  @override
  Future<AgendaResponse> getAgenda() async =>
      AgendaResponse(itens: [], recomendacoes: []);
}

/// Grava as chamadas de editarSessao para os testes inspecionarem o PATCH.
class FakeSessaoEstudoService extends SessaoEstudoService {
  final List<SessaoEstudoResumo> sessoes;
  final List<Map<String, Object?>> patches = [];
  final List<Map<String, Object?>> blocos = [];
  final List<Map<String, Object?>> avaliacoes = [];
  int listarChamadas = 0;

  FakeSessaoEstudoService({List<SessaoEstudoResumo>? sessoes})
    : sessoes = sessoes ?? [_novaSessaoAgendada()];

  @override
  Future<List<SessaoEstudoResumo>> listarSessoes() async {
    listarChamadas++;
    return List.of(sessoes);
  }

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
  }) async {
    patches.add({
      'sessaoId': sessaoId,
      'status': status,
      'duracaoRealizada': duracaoRealizada,
      'energiaInicial': energiaInicial,
      'interrupcoes': interrupcoes,
      'tipoAtividade': tipoAtividade,
    });
  }

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
    final id = 'bloco-${blocos.length + 1}';
    blocos.add({
      'id': id,
      'sessaoId': sessaoId,
      'numeroCiclo': numeroCiclo,
      'duracaoPlanejadaSegundos': duracaoPlanejadaSegundos,
      'duracaoRealizadaSegundos': duracaoRealizadaSegundos,
      'interrupcoes': interrupcoes,
      'status': status,
    });
    return id;
  }

  @override
  Future<void> avaliarBlocoPomodoro({
    required String blocoId,
    required int produtividade,
    String? status,
  }) async {
    avaliacoes.add({
      'blocoId': blocoId,
      'produtividade': produtividade,
      'status': status,
    });
  }
}

// ---------------------------------------------------------------------------
// Helper: cria o provider dentro do fakeAsync já carregado e com a sessão
// selecionada (pré-condição para iniciar o foco).
// ---------------------------------------------------------------------------

({PomodoroProvider provider, FakeSessaoEstudoService sessaoService})
_criarProviderCarregado(FakeAsync async, {bool selecionarSessao = true}) {
  final sessaoService = FakeSessaoEstudoService();
  final provider = PomodoroProvider(
    disciplinaService: FakeDisciplinaService(),
    agendaService: FakeAgendaService(),
    sessaoEstudoService: sessaoService,
    somAtivado: false, // sem plugin de áudio no ambiente de teste
  );
  async.flushMicrotasks(); // resolve os Futures dos fakes (carga inicial)

  if (selecionarSessao) {
    provider.selecionarDisciplina(_disciplina);
    provider.selecionarSessao(provider.sessoesDaDisciplinaSelecionada.first);
  }
  return (provider: provider, sessaoService: sessaoService);
}

void main() {
  group('PomodoroProvider —', () {
    test('iniciar uma sessão Pomodoro', () {
      fakeAsync((async) {
        final (:provider, :sessaoService) = _criarProviderCarregado(async);

        expect(provider.running, isFalse);
        provider.toggle();

        expect(provider.running, isTrue);
        // O timer decrementa segundo a segundo depois de iniciado.
        async.elapse(const Duration(seconds: 5));
        expect(provider.remainingSeconds, 25 * 60 - 5);

        provider.dispose();
      });
    });

    test('não inicia o foco sem sessão selecionada', () {
      fakeAsync((async) {
        final (:provider, :sessaoService) = _criarProviderCarregado(
          async,
          selecionarSessao: false,
        );

        provider.toggle();

        expect(provider.running, isFalse);
        expect(provider.error, contains('Selecione'));

        provider.dispose();
      });
    });

    test(
      'recarrega sessoes externas e mostra materia com sessao disponivel',
      () {
        fakeAsync((async) {
          final sessaoService = FakeSessaoEstudoService(sessoes: []);
          final provider = PomodoroProvider(
            disciplinaService: FakeDisciplinaService([
              _disciplina,
              _segundaDisciplina,
            ]),
            agendaService: FakeAgendaService(),
            sessaoEstudoService: sessaoService,
            somAtivado: false,
          );
          async.flushMicrotasks();

          expect(provider.disciplinaSelecionada?.id, 'disc-1');
          expect(provider.sessoesDaDisciplinaSelecionada, isEmpty);

          sessaoService.sessoes.add(
            SessaoEstudoResumo(
              id: 'sessao-2',
              disciplinaId: _segundaDisciplina.id,
              disciplinaNome: _segundaDisciplina.nome,
              inicio: DateTime(2026, 7, 11, 8),
              fim: DateTime(2026, 7, 11, 10),
              duracaoRealizada: 0,
              status: 'agendado',
            ),
          );

          provider.atualizarDadosExternos();
          async.flushMicrotasks();

          expect(sessaoService.listarChamadas, 2);
          expect(provider.disciplinaSelecionada?.id, 'disc-2');
          expect(provider.sessoesDaDisciplinaSelecionada, hasLength(1));
          expect(provider.sessoesDaDisciplinaSelecionada.single.id, 'sessao-2');
          expect(provider.sessaoSelecionada, isNull);

          provider.dispose();
        });
      },
    );

    test('pausar uma sessão Pomodoro', () {
      fakeAsync((async) {
        final (:provider, :sessaoService) = _criarProviderCarregado(async);

        provider.toggle();
        async.elapse(const Duration(seconds: 10));
        provider.toggle(); // pausa

        expect(provider.running, isFalse);
        final tempoNaPausa = provider.remainingSeconds;
        expect(tempoNaPausa, 25 * 60 - 10);

        // Pausado, o tempo não anda mais.
        async.elapse(const Duration(seconds: 30));
        expect(provider.remainingSeconds, tempoNaPausa);
        expect(sessaoService.blocos, isEmpty);
        expect(provider.produtividadePendente, isFalse);

        provider.dispose();
      });
    });

    test('retomar uma sessão pausada', () {
      fakeAsync((async) {
        final (:provider, :sessaoService) = _criarProviderCarregado(async);

        provider.toggle();
        async.elapse(const Duration(seconds: 10));
        provider.toggle(); // pausa
        async.elapse(const Duration(seconds: 30)); // parado

        provider.toggle(); // retoma
        expect(provider.running, isTrue);

        // Continua exatamente de onde parou.
        async.elapse(const Duration(seconds: 5));
        expect(provider.remainingSeconds, 25 * 60 - 10 - 5);

        provider.dispose();
      });
    });

    test('encerrar (reset) uma sessão Pomodoro', () {
      fakeAsync((async) {
        final (:provider, :sessaoService) = _criarProviderCarregado(async);

        provider.toggle();
        async.elapse(const Duration(seconds: 42));
        provider.reset();

        expect(provider.running, isFalse);
        expect(provider.remainingSeconds, 25 * 60); // tempo cheio de volta
        // Encerrar sem completar o ciclo não persiste nada no backend.
        expect(sessaoService.patches, isEmpty);
        expect(sessaoService.blocos, isEmpty);

        provider.dispose();
      });
    });

    test('tempo chega a zero: muda de fase, contabiliza e persiste o foco', () {
      fakeAsync((async) {
        final (:provider, :sessaoService) = _criarProviderCarregado(async);

        // Encurta o foco para 1 minuto para o teste.
        provider.ajustarDuracao(PomodoroMode.foco, -24);
        expect(provider.durations[PomodoroMode.foco], 1);

        provider.toggle();
        async.elapse(const Duration(seconds: 60)); // ciclo de foco completo
        async.flushMicrotasks(); // resolve o PATCH assíncrono

        // Passou para a pausa curta, parado (autoStartBreaks = false).
        expect(provider.mode, PomodoroMode.curta);
        expect(provider.running, isFalse);
        expect(
          provider.remainingSeconds,
          provider.durations[PomodoroMode.curta]! * 60,
        );
        expect(provider.sessionsToday, 1);

        // Persistiu os minutos de foco na sessão selecionada, sem mudar status.
        expect(sessaoService.patches, hasLength(1));
        expect(sessaoService.patches.single['sessaoId'], 'sessao-1');
        expect(sessaoService.patches.single['duracaoRealizada'], 1);
        expect(sessaoService.patches.single['status'], 'AGENDADO');
        expect(sessaoService.patches.single['interrupcoes'], 0);
        expect(sessaoService.blocos, hasLength(1));
        expect(sessaoService.blocos.single['status'], 'CONCLUIDO');
        expect(sessaoService.blocos.single['duracaoRealizadaSegundos'], 60);
        expect(provider.produtividadePendente, isTrue);

        provider.dispose();
      });
    });

    test('registra energia opcional antes do primeiro foco', () {
      fakeAsync((async) {
        final (:provider, :sessaoService) = _criarProviderCarregado(async);

        expect(provider.deveSolicitarEnergia, isTrue);
        provider.definirEnergiaInicial(4);
        expect(provider.energiaInicial, 4);
        expect(provider.deveSolicitarEnergia, isFalse);

        provider.dispose();
      });
    });

    test('envia interrupções e energia no mesmo PATCH da duração', () {
      fakeAsync((async) {
        final (:provider, :sessaoService) = _criarProviderCarregado(async);
        provider.ajustarDuracao(PomodoroMode.foco, -24);
        provider.definirEnergiaInicial(3);
        provider.toggle();
        provider.registrarInterrupcao();
        provider.registrarInterrupcao();

        async.elapse(const Duration(seconds: 60));
        async.flushMicrotasks();

        expect(sessaoService.patches, hasLength(1));
        expect(sessaoService.patches.single['duracaoRealizada'], 1);
        expect(sessaoService.patches.single['energiaInicial'], 3);
        expect(sessaoService.patches.single['interrupcoes'], 2);
        expect(sessaoService.blocos.single['interrupcoes'], 2);
        expect(provider.interrupcoesBloco, 0);

        provider.dispose();
      });
    });

    test('avalia produtividade opcional após conclusão natural', () {
      fakeAsync((async) {
        final (:provider, :sessaoService) = _criarProviderCarregado(async);
        provider.ajustarDuracao(PomodoroMode.foco, -24);
        provider.toggle();

        async.elapse(const Duration(seconds: 60));
        async.flushMicrotasks();
        expect(provider.produtividadePendente, isTrue);

        provider.responderProdutividade(4);
        async.flushMicrotasks();

        expect(provider.produtividadePendente, isFalse);
        expect(sessaoService.avaliacoes, [
          {'blocoId': 'bloco-1', 'produtividade': 4, 'status': null},
        ]);

        provider.dispose();
      });
    });

    test('permite ignorar produtividade sem perder o bloco concluído', () {
      fakeAsync((async) {
        final (:provider, :sessaoService) = _criarProviderCarregado(async);
        provider.ajustarDuracao(PomodoroMode.foco, -24);
        provider.toggle();

        async.elapse(const Duration(seconds: 60));
        async.flushMicrotasks();
        provider.responderProdutividade(null);
        async.flushMicrotasks();

        expect(sessaoService.blocos, hasLength(1));
        expect(sessaoService.blocos.single['status'], 'CONCLUIDO');
        expect(sessaoService.avaliacoes, isEmpty);
        expect(provider.produtividadePendente, isFalse);

        provider.dispose();
      });
    });

    test('ciclo pulado sem resposta permanece incompleto', () {
      fakeAsync((async) {
        final (:provider, :sessaoService) = _criarProviderCarregado(async);
        provider.toggle();
        async.elapse(const Duration(seconds: 10));

        provider.skip();
        async.flushMicrotasks();

        expect(sessaoService.patches, isEmpty);
        expect(sessaoService.blocos, hasLength(1));
        expect(sessaoService.blocos.single['status'], 'INCOMPLETO');
        expect(sessaoService.blocos.single['duracaoRealizadaSegundos'], 10);
        expect(provider.produtividadePendente, isTrue);
        expect(provider.produtividadePendenteAntecipada, isTrue);
        expect(provider.sessionsToday, 0);

        provider.responderProdutividade(null);
        async.flushMicrotasks();

        expect(provider.produtividadePendente, isFalse);
        expect(sessaoService.avaliacoes, isEmpty);

        provider.dispose();
      });
    });

    test('avaliar ciclo pulado promove para encerrado antecipadamente', () {
      fakeAsync((async) {
        final (:provider, :sessaoService) = _criarProviderCarregado(async);
        provider.toggle();
        async.elapse(const Duration(seconds: 10));
        provider.skip();
        async.flushMicrotasks();

        provider.responderProdutividade(4);
        async.flushMicrotasks();

        expect(sessaoService.avaliacoes, [
          {
            'blocoId': 'bloco-1',
            'produtividade': 4,
            'status': 'ENCERRADO_ANTECIPADAMENTE',
          },
        ]);
        expect(provider.produtividadePendente, isFalse);

        provider.dispose();
      });
    });
  });
}
