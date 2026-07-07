import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/disciplina.dart';
import 'package:frontend/models/material_estudo.dart';
import 'package:frontend/providers/notas_provider.dart';
import 'package:frontend/services/api_service.dart';

/// Dublê do ApiService: guarda os "materiais" em memória e registra as
/// chamadas, sem tocar em HTTP.
class FakeApiService extends ApiService {
  final List<Disciplina> disciplinasFake;
  final List<MaterialEstudo> materiaisFake;
  String? ultimoTipoPedido;
  bool falharListagem = false;

  FakeApiService({
    this.disciplinasFake = const [],
    List<MaterialEstudo>? materiais,
  }) : materiaisFake = materiais ?? [];

  @override
  Future<List<Disciplina>> getDisciplinas() async => disciplinasFake;

  @override
  Future<List<MaterialEstudo>> getMateriais({
    String? disciplinaId,
    String? tipo,
    String? search,
  }) async {
    if (falharListagem) throw Exception('offline');
    ultimoTipoPedido = tipo;
    return materiaisFake.where((m) => tipo == null || m.tipo == tipo).toList();
  }

  @override
  Future<MaterialEstudo?> createMaterial(Map<String, dynamic> data) async {
    final novo = MaterialEstudo(
      id: 'novo-${materiaisFake.length}',
      titulo: data['titulo'] as String,
      tipo: data['tipo'] as String,
      descricao: data['descricao'] as String?,
      disciplinaId: data['disciplina'] as String,
      disciplinaNome: 'Engenharia de Software II',
      dataInsercao: DateTime(2026, 7, 6),
    );
    materiaisFake.insert(0, novo);
    return novo;
  }

  @override
  Future<MaterialEstudo?> updateMaterial(
    String id,
    Map<String, dynamic> data,
  ) async {
    final idx = materiaisFake.indexWhere((m) => m.id == id);
    if (idx < 0) return null;
    materiaisFake[idx] = materiaisFake[idx].copyWith(
      titulo: data['titulo'] as String?,
      descricao: data['descricao'] as String?,
    );
    return materiaisFake[idx];
  }

  @override
  Future<bool> deleteMaterial(String id) async {
    final before = materiaisFake.length;
    materiaisFake.removeWhere((m) => m.id == id);
    return materiaisFake.length < before;
  }
}

MaterialEstudo _resumo({
  required String id,
  required String titulo,
  String? descricao,
  String disciplinaId = 'd1',
  String disciplinaNome = 'Engenharia de Software II',
}) {
  return MaterialEstudo(
    id: id,
    titulo: titulo,
    tipo: 'Resumo',
    descricao: descricao ?? 'Observações importantes:\n- Um item.',
    disciplinaId: disciplinaId,
    disciplinaNome: disciplinaNome,
    dataInsercao: DateTime(2026, 7, 5),
  );
}

void main() {
  const disciplinas = [
    Disciplina(id: 'd1', nome: 'Engenharia de Software II', codigo: '', cor: '#6366F1'),
    Disciplina(id: 'd2', nome: 'Física', codigo: '', cor: '#009688'),
  ];

  group('NotasProvider.loadNotas', () {
    test('pede tipo=Resumo ao backend e seleciona a primeira nota', () async {
      final api = FakeApiService(
        disciplinasFake: disciplinas,
        materiais: [_resumo(id: 'n1', titulo: 'Requisitos')],
      );
      final provider = NotasProvider(api: api);

      await provider.init();

      expect(api.ultimoTipoPedido, 'Resumo');
      expect(provider.notasFiltradas, hasLength(1));
      expect(provider.selecionada?.titulo, 'Requisitos');
      expect(provider.view, NotasView.detalhe);
    });

    test('ignora Resumo sem cabeçalhos de seção (não é nota da tela)', () async {
      final api = FakeApiService(materiais: [
        _resumo(id: 'n1', titulo: 'Nota de verdade'),
        _resumo(id: 'x1', titulo: 'Resumo livre', descricao: 'Texto solto.'),
      ]);
      final provider = NotasProvider(api: api);

      await provider.loadNotas();

      expect(provider.notasFiltradas.map((n) => n.id), ['n1']);
    });

    test('falha de rede vira mensagem de erro, sem lançar', () async {
      final api = FakeApiService()..falharListagem = true;
      final provider = NotasProvider(api: api);

      await provider.loadNotas();

      expect(provider.error, isNotNull);
      expect(provider.isLoading, isFalse);
    });
  });

  group('NotasProvider filtros e busca (locais)', () {
    test('filtra por disciplina e mantém contagens dos chips', () async {
      final api = FakeApiService(disciplinasFake: disciplinas, materiais: [
        _resumo(id: 'n1', titulo: 'ES2', disciplinaId: 'd1'),
        _resumo(id: 'n2', titulo: 'Física', disciplinaId: 'd2',
            disciplinaNome: 'Física'),
      ]);
      final provider = NotasProvider(api: api);
      await provider.init();

      provider.setFiltroDisciplina('d2');

      expect(provider.notasFiltradas.map((n) => n.id), ['n2']);
      expect(provider.contagemPorDisciplina('d1'), 1);
      expect(provider.totalNotas, 2);
    });

    test('busca encontra pelo conteúdo das seções', () async {
      final api = FakeApiService(materiais: [
        _resumo(id: 'n1', titulo: 'Aula 3',
            descricao: 'Dicas para prova:\n- Saber explicar user story.'),
        _resumo(id: 'n2', titulo: 'Outra'),
      ]);
      final provider = NotasProvider(api: api);
      await provider.loadNotas();

      provider.setSearch('user story');

      expect(provider.notasFiltradas.map((n) => n.id), ['n1']);
    });
  });

  group('NotasProvider CRUD', () {
    test('salvar cria a nota, recarrega e abre o detalhe', () async {
      final api = FakeApiService(disciplinasFake: disciplinas);
      final provider = NotasProvider(api: api);
      await provider.init();
      provider.abrirNova();

      final ok = await provider.salvar(
        titulo: 'Nova nota',
        disciplinaId: 'd1',
        secoes: {
          'obs': ['Primeiro item.'],
        },
      );

      expect(ok, isTrue);
      expect(provider.view, NotasView.detalhe);
      expect(provider.selecionada?.titulo, 'Nova nota');
      expect(provider.selecionada?.itensDe('obs'), ['Primeiro item.']);
    });

    test('excluir remove a nota e volta para o estado vazio', () async {
      final api = FakeApiService(
        materiais: [_resumo(id: 'n1', titulo: 'Descartável')],
      );
      final provider = NotasProvider(api: api);
      await provider.init();
      expect(provider.selecionada, isNotNull);

      final ok = await provider.excluir('n1');

      expect(ok, isTrue);
      expect(provider.notasFiltradas, isEmpty);
      expect(provider.selecionada, isNull);
      expect(provider.view, NotasView.vazio);
    });
  });
}
