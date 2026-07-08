import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/disciplina.dart';
import 'package:frontend/models/nota_estudo.dart';
import 'package:frontend/providers/notas_provider.dart';
import 'package:frontend/services/notas_service.dart';

class _FakeNotasService extends NotasService {
  List<Disciplina> disciplinas;
  List<NotaEstudo> notas;
  bool falharExclusao = false;
  int proximoId = 100;

  _FakeNotasService({this.disciplinas = const [], this.notas = const []});

  @override
  Future<List<Disciplina>> listarDisciplinas() async => disciplinas;

  @override
  Future<List<NotaEstudo>> listarNotas() async => notas;

  @override
  Future<NotaEstudo?> salvarNota(NotaEstudo nota) async {
    if (nota.id != null) return nota;
    return NotaEstudo(
      id: 'n${proximoId++}',
      disciplinaId: nota.disciplinaId,
      disciplinaNome: nota.disciplinaNome,
      titulo: nota.titulo,
      data: nota.data,
      secoes: nota.secoes,
    );
  }

  @override
  Future<bool> excluirNota(String id) async => !falharExclusao;
}

Disciplina _disciplina(String id, String nome) =>
    Disciplina(id: id, nome: nome, codigo: '', cor: '#6366f1');

NotaEstudo _nota(String id, String disciplinaId, String titulo) => NotaEstudo(
      id: id,
      disciplinaId: disciplinaId,
      disciplinaNome: 'Disciplina $disciplinaId',
      titulo: titulo,
      data: DateTime(2026, 7, 8),
      secoes: const {
        'obs': ['primeira observação'],
      },
    );

void main() {
  group('NotasProvider', () {
    test('carregar popula disciplinas e notas e seleciona a primeira',
        () async {
      final provider = NotasProvider(
        service: _FakeNotasService(
          disciplinas: [_disciplina('d1', 'Biologia')],
          notas: [_nota('n1', 'd1', 'Fotossíntese')],
        ),
      );
      await provider.carregar();

      expect(provider.erro, isNull);
      expect(provider.disciplinas, hasLength(1));
      expect(provider.todasNotas, hasLength(1));
      expect(provider.notaSelecionada?.titulo, 'Fotossíntese');
      expect(provider.modo, NotasModo.detalhe);
    });

    test(
        'novaNota e bloqueada sem disciplina e liberada com disciplina cadastrada',
        () async {
      final semDisciplina = NotasProvider(service: _FakeNotasService());
      await semDisciplina.carregar();
      expect(semDisciplina.podeCriarNota, isFalse);
      semDisciplina.novaNota();
      expect(semDisciplina.modo, NotasModo.vazio,
          reason: 'formulário não deve abrir sem disciplina');

      final comDisciplina = NotasProvider(
        service: _FakeNotasService(
          disciplinas: [_disciplina('d1', 'Biologia')],
        ),
      );
      await comDisciplina.carregar();
      expect(comDisciplina.podeCriarNota, isTrue);
      comDisciplina.novaNota();
      expect(comDisciplina.modo, NotasModo.formulario);
    });

    test('salvar adiciona a nota, seleciona e volta para o detalhe',
        () async {
      final provider = NotasProvider(
        service: _FakeNotasService(
          disciplinas: [_disciplina('d1', 'Biologia')],
        ),
      );
      await provider.carregar();
      provider.novaNota();

      final ok = await provider.salvar(NotaEstudo(
        disciplinaId: 'd1',
        disciplinaNome: 'Biologia',
        titulo: 'Célula animal',
        data: DateTime(2026, 7, 8),
        secoes: const {'obs': ['membrana e núcleo']},
      ));

      expect(ok, isTrue);
      expect(provider.todasNotas, hasLength(1));
      expect(provider.notaSelecionada?.titulo, 'Célula animal');
      expect(provider.modo, NotasModo.detalhe);
    });

    test('excluirNotaSelecionada remove a nota e volta ao estado vazio',
        () async {
      final provider = NotasProvider(
        service: _FakeNotasService(
          disciplinas: [_disciplina('d1', 'Biologia')],
          notas: [_nota('n1', 'd1', 'Fotossíntese')],
        ),
      );
      await provider.carregar();

      final ok = await provider.excluirNotaSelecionada();
      expect(ok, isTrue);
      expect(provider.todasNotas, isEmpty);
      expect(provider.notaSelecionada, isNull);
      expect(provider.modo, NotasModo.vazio);
    });

    test('busca e filtro por disciplina refinam a lista', () async {
      final provider = NotasProvider(
        service: _FakeNotasService(
          disciplinas: [
            _disciplina('d1', 'Biologia'),
            _disciplina('d2', 'Física'),
          ],
          notas: [
            _nota('n1', 'd1', 'Fotossíntese'),
            _nota('n2', 'd2', 'Leis de Newton'),
          ],
        ),
      );
      await provider.carregar();

      expect(provider.notasFiltradas, hasLength(2));

      provider.definirFiltroDisciplina('d2');
      expect(provider.notasFiltradas.single.titulo, 'Leis de Newton');
      expect(provider.contagemPorDisciplina('d1'), 1);
      expect(provider.contagemPorDisciplina(null), 2);

      provider.definirFiltroDisciplina(null);
      provider.definirBusca('fotos');
      expect(provider.notasFiltradas.single.titulo, 'Fotossíntese');

      provider.definirBusca('nada disso');
      expect(provider.notasFiltradas, isEmpty);
    });
  });
}
