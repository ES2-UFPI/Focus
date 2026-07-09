"""Popula o banco com um perfil de demonstração completo.

Cria um estudante "mediano" — com pontos fortes e pontos a melhorar — e dados
que cobrem todas as abas do app: Disciplinas, Agenda (eventos + sessões),
Atividades (eventos + to-dos), Pomodoro (blocos), Materiais, Notas,
Consistência e Insights.

Os Insights e a Consistência são *calculados* ao vivo a partir das sessões de
estudo e blocos Pomodoro (ver `insights/services.py` e
`services/consistencia_service.py`), então os dados aqui são desenhados para
disparar um conjunto rico e coerente de insights (forças e fraquezas).

Uso:
    python manage.py seed_demo
    python manage.py seed_demo --email aluno@x.com --senha Senha@1
    python manage.py seed_demo --keep         # não faz nada se o usuário existir
    python manage.py seed_demo --reset-senha  # redefine a senha do usuário existente
    python manage.py seed_demo --staff        # dá acesso ao /admin

O comando é idempotente e NÃO destrói a conta: se o usuário já existir, a
conta (id, senha e token) é preservada e apenas os dados de estudo dele são
recriados. A senha só é definida ao criar um usuário novo — ou com
`--reset-senha` num usuário existente.
"""

import datetime as dt
import json

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from alunos.models import Aluno
from disciplinas.models import Disciplina
from eventos_academicos.models import EventoAcademico
from feedback_sessao_estudo.models import FeedbackSessaoEstudo
from insights.models import InsightFeedback
from materiais_estudo.models import MaterialEstudo
from sessao_estudo.models import BlocoPomodoro, SessaoEstudo
from tarefas_disciplina.models import Prioridade, TarefaDisciplina

DEFAULT_EMAIL = 'samuelfurtadofortes@gmail.com'
DEFAULT_SENHA = 'Samuel@1'

FOCO_PADRAO_SEG = 25 * 60  # duração planejada de um ciclo Pomodoro (25 min)


class Command(BaseCommand):
    help = 'Cria um perfil de estudante de demonstração com dados em todas as abas.'

    def add_arguments(self, parser):
        parser.add_argument('--email', default=DEFAULT_EMAIL)
        parser.add_argument('--senha', '--password', dest='senha', default=DEFAULT_SENHA)
        parser.add_argument(
            '--keep',
            action='store_true',
            help='Não faz nada se o usuário já existir (não recria os dados).',
        )
        parser.add_argument(
            '--staff',
            action='store_true',
            help='Marca o usuário como staff (acesso ao /admin). Padrão: não.',
        )
        parser.add_argument(
            '--reset-senha',
            action='store_true',
            dest='reset_senha',
            help='Redefine a senha mesmo se o usuário já existir.',
        )

    # ------------------------------------------------------------------ #
    # Utilidades de tempo (datetimes "aware" no fuso local do projeto)
    # ------------------------------------------------------------------ #
    def _dt(self, days_ago, hour, minute=0):
        """Datetime local a `days_ago` dias atrás, no horário informado."""
        data = self._hoje - dt.timedelta(days=days_ago)
        naive = dt.datetime.combine(data, dt.time(hour, minute))
        return timezone.make_aware(naive, self._tz)

    def _data(self, days_from_now):
        """Data (date) deslocada de hoje (positivo = futuro)."""
        return self._hoje + dt.timedelta(days=days_from_now)

    # ------------------------------------------------------------------ #
    @transaction.atomic
    def handle(self, *args, **options):
        self._tz = timezone.get_current_timezone()
        self._hoje = timezone.localtime(timezone.now()).date()

        email = options['email']
        senha = options['senha']

        aluno = Aluno.objects.filter(email=email).first()

        if aluno and options['keep']:
            self.stdout.write(self.style.WARNING(
                f'Usuario {email} ja existe e --keep foi usado; nada a fazer.'
            ))
            return

        if aluno:
            # Reaproveita a conta existente (mantem id, senha e token).
            # Remove apenas os dados de dominio para poder repovoar de forma
            # idempotente, SEM apagar o usuario.
            InsightFeedback.objects.filter(aluno=aluno).delete()
            aluno.disciplinas.all().delete()  # cascata: sessoes, eventos, etc.
            if options['reset_senha']:
                aluno.set_password(senha)
            if options['staff'] and not aluno.is_staff:
                aluno.is_staff = True
            aluno.save()
            self.stdout.write(self.style.WARNING(
                f'Usuario {email} ja existia: dados de estudo recriados '
                f'(conta e senha preservadas).'
            ))
        else:
            aluno = Aluno.objects.create_user(
                email=email,
                password=senha,
                nome='Samuel Fortes',
                data_nascimento=dt.date(2003, 5, 14),
                is_staff=options['staff'],
            )
            self.stdout.write(self.style.SUCCESS(f'Usuario {email} criado.'))

        discs = self._criar_disciplinas(aluno)
        eventos = self._criar_eventos(discs)
        self._criar_sessoes(discs, eventos)
        self._criar_sessoes_futuras(discs)
        self._criar_tarefas(discs, eventos)
        self._criar_materiais(discs)
        self._criar_notas(discs)

        self._resumo(aluno)

    # ------------------------------------------------------------------ #
    def _criar_disciplinas(self, aluno):
        config = [
            # chave, nome, código, cor, meta_horas, descrição
            ('alg', 'Algoritmos e Estruturas de Dados', 'INF0234', '#43A047', 6,
             'Ponto forte: sessões curtas, focadas e produtivas pela manhã.'),
            ('calc', 'Cálculo Diferencial e Integral I', 'MAT0121', '#1E88E5', 6,
             'Ponto a melhorar: estudo concentrado na véspera e sessões longas à noite.'),
            ('fis', 'Física II', 'FIS0205', '#8E24AA', 4,
             'Disciplina que ficou de lado nas últimas semanas.'),
            ('bd', 'Banco de Dados', 'INF0311', '#FB8C00', 4,
             'Ritmo regular, com sessões de exercícios.'),
            ('ing', 'Inglês Instrumental', 'LET0102', '#E53935', 2,
             'Leitura de artigos aos fins de semana.'),
        ]
        discs = {}
        for chave, nome, codigo, cor, meta, desc in config:
            discs[chave] = Disciplina.objects.create(
                aluno=aluno, nome=nome, codigo=codigo, cor=cor,
                meta_horas_semanais=meta, descricao=desc,
            )
        return discs

    # ------------------------------------------------------------------ #
    def _criar_eventos(self, d):
        """Eventos acadêmicos: provas, trabalhos, seminários (passados e futuros)."""
        eventos = {}

        # Prova de Cálculo já realizada (alimenta o insight de "cramming").
        # Fica dentro da janela de 14 dias que o insight de cramming analisa.
        eventos['prova_calc'] = EventoAcademico.objects.create(
            disciplina=d['calc'], titulo='Prova 1 — Limites e Derivadas',
            tipo=EventoAcademico.TipoEvento.PROVA, data_evento=self._data(-9),
            hora_inicio=dt.time(10, 0), hora_fim=dt.time(12, 0),
            concluido=True, data_conclusao=self._data(-9),
            descricao='Prova cobrindo limites, continuidade e regras de derivação.',
        )
        # Trabalho de Algoritmos já entregue.
        eventos['trab_alg_ok'] = EventoAcademico.objects.create(
            disciplina=d['alg'], titulo='Lista 2 — Ordenação',
            tipo=EventoAcademico.TipoEvento.TRABALHO, data_evento=self._data(-20),
            concluido=True, data_conclusao=self._data(-21),
        )

        # Futuros (aparecem em Atividades e na Agenda).
        eventos['apres_ing'] = EventoAcademico.objects.create(
            disciplina=d['ing'], titulo='Apresentação — Paper Reading',
            tipo=EventoAcademico.TipoEvento.APRESENTACAO, data_evento=self._data(3),
            hora_inicio=dt.time(15, 0), hora_fim=dt.time(15, 30),
            descricao='Apresentar o resumo de um artigo em inglês.',
        )
        eventos['trab_alg'] = EventoAcademico.objects.create(
            disciplina=d['alg'], titulo='Projeto — Grafos',
            tipo=EventoAcademico.TipoEvento.TRABALHO, data_evento=self._data(6),
            descricao='Implementar Dijkstra e BFS/DFS com relatório.',
        )
        eventos['sem_bd'] = EventoAcademico.objects.create(
            disciplina=d['bd'], titulo='Seminário — Normalização',
            tipo=EventoAcademico.TipoEvento.SEMINARIO, data_evento=self._data(10),
            hora_inicio=dt.time(14, 0), hora_fim=dt.time(15, 0),
        )
        eventos['prova_fis'] = EventoAcademico.objects.create(
            disciplina=d['fis'], titulo='Prova 1 — Termodinâmica',
            tipo=EventoAcademico.TipoEvento.PROVA, data_evento=self._data(12),
            hora_inicio=dt.time(8, 0), hora_fim=dt.time(10, 0),
        )
        return eventos

    # ------------------------------------------------------------------ #
    def _nova_sessao(self, disc, inicio, dur_real_min, prod, interrupcoes,
                     tipo, status=SessaoEstudo.StatusSessao.CONCLUIDO,
                     planejado_min=None, energia=3, evento=None, feedback=False):
        """Cria uma sessão e (se concluída) seus blocos Pomodoro.

        A produtividade da sessão nos insights é a *média* das produtividades
        dos blocos — então todos os blocos recebem a nota `prod` alvo.
        """
        planejado_min = planejado_min or dur_real_min
        fim = inicio + dt.timedelta(minutes=planejado_min)
        realizada = dur_real_min if status == SessaoEstudo.StatusSessao.CONCLUIDO else 0

        sessao = SessaoEstudo.objects.create(
            disciplina=disc, evento_academico=evento, inicio=inicio, fim=fim,
            duracao_realizada=realizada, status=status, tipo_atividade=tipo,
            energia_inicial=energia, interrupcoes=interrupcoes,
            descricao=f'Sessão de {disc.nome}.',
        )

        if status == SessaoEstudo.StatusSessao.CONCLUIDO and prod is not None:
            n = max(1, round(dur_real_min / 25))
            passo = dur_real_min / n
            for i in range(n):
                b_ini = inicio + dt.timedelta(minutes=passo * i)
                b_fim = inicio + dt.timedelta(minutes=passo * (i + 1))
                BlocoPomodoro.objects.create(
                    sessao_estudo=sessao, numero_ciclo=i + 1,
                    inicio=b_ini, fim=b_fim,
                    duracao_planejada_segundos=FOCO_PADRAO_SEG,
                    duracao_realizada_segundos=int(passo * 60),
                    interrupcoes=interrupcoes if i == 0 else 0,
                    status=BlocoPomodoro.StatusBloco.CONCLUIDO,
                    produtividade=prod,
                )

        if feedback and status == SessaoEstudo.StatusSessao.CONCLUIDO:
            FeedbackSessaoEstudo.objects.create(
                sessao_estudo=sessao, produtividade=prod,
                descricao='Consegui manter o foco.' if prod >= 4
                else 'Me distraí algumas vezes.',
            )
        return sessao

    def _criar_sessoes(self, d, eventos):
        """Sessões dos últimos 42 dias, desenhadas para gerar insights coerentes.

        Padrão semanal (por dia da semana), modulado por semana:
        - Terça de manhã: Algoritmos, curto, alta produtividade  → força.
        - Quinta de manhã: Algoritmos, curto, boa produtividade   → força.
        - Segunda/Quinta à noite: Cálculo, longo, baixa prod       → fraqueza.
        - Quarta à noite: Física — só nas semanas mais antigas     → "ritmo".
        - Sexta à noite: sessão que costuma ser cancelada (cedo)   → "furo".
        - Sábado à tarde: Inglês, leitura.
        Os últimos ~8 dias têm apenas sessões fortes (sequência produtiva).
        """
        C = SessaoEstudo.StatusSessao.CONCLUIDO
        X = SessaoEstudo.StatusSessao.CANCELADO
        LEI = SessaoEstudo.TipoAtividade.LEITURA
        EXE = SessaoEstudo.TipoAtividade.EXERCICIO
        REV = SessaoEstudo.TipoAtividade.REVISAO

        for days_ago in range(41, 0, -1):
            data = self._hoje - dt.timedelta(days=days_ago)
            wd = data.weekday()  # 0=segunda ... 6=domingo

            # Janela recente (<= 8 dias): só sessões fortes, sem cancelamentos.
            recente = days_ago <= 8

            if wd == 1:  # terça — Algoritmos manhã, forte
                self._nova_sessao(d['alg'], self._dt(days_ago, 8, 0), 40, 5, 0, EXE,
                                  energia=5, feedback=True)
                if not recente:
                    self._nova_sessao(d['bd'], self._dt(days_ago, 10, 30), 40, 4, 0, EXE,
                                      energia=4)
            elif wd == 3:  # quinta — Algoritmos manhã (forte) + Cálculo noite (fraco)
                self._nova_sessao(d['alg'], self._dt(days_ago, 9, 0), 45, 4, 0, EXE,
                                  energia=4, feedback=True)
                if not recente:
                    self._nova_sessao(d['calc'], self._dt(days_ago, 22, 0), 75, 3, 2, LEI,
                                      planejado_min=55, energia=2)
            elif wd == 0 and not recente:  # segunda — Cálculo noite, longo, subestimado
                self._nova_sessao(d['calc'], self._dt(days_ago, 21, 0), 85, 2, 3, LEI,
                                  planejado_min=60, energia=2, feedback=True)
            elif wd == 2 and days_ago >= 16:  # quarta — Física (só semanas antigas)
                self._nova_sessao(d['fis'], self._dt(days_ago, 19, 0), 60, 3, 1, LEI,
                                  energia=3)
            elif wd == 4 and not recente:  # sexta à noite — slot que "fura"
                # Semanas antigas (>=21 dias): quase sempre cancelada.
                cancela = days_ago >= 19
                self._nova_sessao(
                    d['bd'], self._dt(days_ago, 20, 0), 50, 3, 1, EXE,
                    status=X if cancela else C, energia=3,
                )
            elif wd == 5 and days_ago >= 9:  # sábado — Inglês, leitura
                self._nova_sessao(d['ing'], self._dt(days_ago, 14, 0), 60, 3, 1, LEI,
                                  energia=3)
            elif wd == 6 and recente:  # domingo recente — revisão forte
                self._nova_sessao(d['bd'], self._dt(days_ago, 10, 0), 40, 4, 0, REV,
                                  energia=4)

        # Sessões fortes extras em dias consecutivos recentes → sequência produtiva.
        for days_ago, hora in ((2, 8), (3, 9), (4, 8)):
            self._nova_sessao(d['alg'], self._dt(days_ago, hora, 0), 40, 5, 0, EXE,
                              energia=5)

        # "Cramming" de Cálculo: quase todo o estudo nas 48h anteriores à prova
        # (prova em -9 dias). Pouco estudo antecipado, muito na véspera.
        self._nova_sessao(d['calc'], self._dt(13, 20, 0), 35, 3, 1, LEI,
                          planejado_min=35, energia=3, evento=eventos['prova_calc'])
        self._nova_sessao(d['calc'], self._dt(11, 20, 0), 95, 2, 3, LEI,
                          planejado_min=60, energia=2, evento=eventos['prova_calc'])
        self._nova_sessao(d['calc'], self._dt(10, 21, 0), 90, 2, 4, LEI,
                          planejado_min=60, energia=1, evento=eventos['prova_calc'],
                          feedback=True)

    def _criar_sessoes_futuras(self, d):
        """Sessões agendadas (aparecem na Agenda como próximos compromissos)."""
        A = SessaoEstudo.StatusSessao.AGENDADO
        EXE = SessaoEstudo.TipoAtividade.EXERCICIO
        LEI = SessaoEstudo.TipoAtividade.LEITURA
        REV = SessaoEstudo.TipoAtividade.REVISAO
        planos = [
            (d['alg'], 1, 8, 45, EXE),
            (d['fis'], 1, 19, 60, REV),   # retomar Física antes da prova
            (d['calc'], 2, 9, 50, EXE),
            (d['bd'], 4, 14, 40, EXE),
            (d['ing'], 5, 15, 45, LEI),
        ]
        for disc, dias, hora, dur, tipo in planos:
            inicio = self._dt(-dias, hora, 0)  # days_ago negativo = futuro
            SessaoEstudo.objects.create(
                disciplina=disc, inicio=inicio,
                fim=inicio + dt.timedelta(minutes=dur),
                duracao_realizada=0, status=A, tipo_atividade=tipo,
                energia_inicial=None, descricao=f'Sessão planejada de {disc.nome}.',
            )

    # ------------------------------------------------------------------ #
    def _criar_tarefas(self, d, eventos):
        """To-dos das atividades. Mistura concluídas (no prazo/atrasadas) e pendentes."""
        P = Prioridade

        def prazo(days_from_now, hour=23, minute=59):
            data = self._data(days_from_now)
            return timezone.make_aware(dt.datetime.combine(data, dt.time(hour, minute)), self._tz)

        # Concluídas (para o insight de "tarefas no prazo": ~75% no prazo).
        concluidas = [
            # (evento, título, dias_prazo, dias_conclusao, no_prazo?)
            (eventos['prova_calc'], 'Refazer lista de derivadas', -20, -21, True),
            (eventos['prova_calc'], 'Resumir teoremas de limite', -18, -19, True),
            (eventos['trab_alg_ok'], 'Implementar merge sort', -22, -23, True),
            (eventos['trab_alg_ok'], 'Escrever relatório da lista', -20, -20, True),
            (eventos['prova_calc'], 'Resolver prova antiga', -17, -16, False),  # atrasada
            (eventos['trab_alg_ok'], 'Revisar complexidade', -19, -18, True),
            (eventos['prova_calc'], 'Lista de continuidade', -24, -22, True),
            (eventos['trab_alg_ok'], 'Testes unitários da lista', -21, -19, False),  # atrasada
        ]
        for evento, titulo, dp, dc, no_prazo in concluidas:
            TarefaDisciplina.objects.create(
                disciplina=evento.disciplina, evento=evento, titulo=titulo,
                prazo=prazo(dp), concluida=True, data_conclusao=prazo(dc),
                prioridade=P.MEDIA,
            )

        # Pendentes (to-dos abertos nos eventos futuros).
        pendentes = [
            (eventos['trab_alg'], 'Implementar Dijkstra', 4, P.ALTA),
            (eventos['trab_alg'], 'Implementar BFS e DFS', 5, P.ALTA),
            (eventos['trab_alg'], 'Escrever relatório do projeto', 6, P.MEDIA),
            (eventos['sem_bd'], 'Montar slides de normalização', 8, P.MEDIA),
            (eventos['sem_bd'], 'Preparar exemplos 1FN→3FN', 9, P.BAIXA),
            (eventos['prova_fis'], 'Refazer exercícios de termodinâmica', 10, P.ALTA),
            (eventos['prova_fis'], 'Revisar leis dos gases', 11, P.MEDIA),
            (eventos['apres_ing'], 'Ensaiar apresentação', 2, P.ALTA),
        ]
        for evento, titulo, dias, prio in pendentes:
            TarefaDisciplina.objects.create(
                disciplina=evento.disciplina, evento=evento, titulo=titulo,
                prazo=prazo(dias), concluida=False, prioridade=prio,
            )

    # ------------------------------------------------------------------ #
    def _criar_materiais(self, d):
        """Biblioteca de materiais por disciplina."""
        T = dict(PDF='PDF', RESUMO='Resumo', LINK='Link', VIDEO='Video', OUTRO='Outro')
        materiais = [
            (d['alg'], 'Slides — Ordenação e Complexidade', T['PDF'], None),
            (d['alg'], 'Visualgo — Estruturas de Dados', T['LINK'], 'https://visualgo.net/en'),
            (d['alg'], 'Aula: Grafos (BFS/DFS)', T['VIDEO'], 'https://youtu.be/example-grafos'),
            (d['calc'], 'Apostila — Limites e Derivadas', T['PDF'], None),
            (d['calc'], '3Blue1Brown — Essence of Calculus', T['VIDEO'],
             'https://youtu.be/WUvTyaaNkzM'),
            (d['fis'], 'Resumo — Leis da Termodinâmica', T['RESUMO'], None),
            (d['bd'], 'Cheatsheet SQL', T['LINK'], 'https://example.com/sql-cheatsheet'),
            (d['bd'], 'Slides — Normalização', T['PDF'], None),
            (d['ing'], 'Artigo: Attention Is All You Need', T['LINK'],
             'https://arxiv.org/abs/1706.03762'),
        ]
        for disc, titulo, tipo, url in materiais:
            MaterialEstudo.objects.create(
                disciplina=disc, titulo=titulo, tipo=tipo, url=url,
                descricao=f'Material de apoio de {disc.nome}.',
            )

    def _criar_notas(self, d):
        """Notas de estudo (MaterialEstudo tipo 'Resumo' com prefixo [NOTA])."""
        def nota(disc, titulo, secoes):
            MaterialEstudo.objects.create(
                disciplina=disc, titulo=f'[NOTA] {titulo}', tipo='Resumo',
                descricao=json.dumps({'nota': True, 'secoes': secoes}, ensure_ascii=False),
            )

        nota(d['alg'], 'Aula 8 — Grafos', {
            'obs': ['Grafos podem ser representados por lista ou matriz de adjacência.'],
            'conceitos': ['BFS usa fila', 'DFS usa pilha/recursão'],
            'prova': ['Professor destacou complexidade de Dijkstra: O((V+E) log V).'],
            'duvidas': ['Rever quando usar heap de Fibonacci.'],
        })
        nota(d['calc'], 'Revisão — Regras de Derivação', {
            'conceitos': ['Regra do produto', 'Regra do quociente', 'Regra da cadeia'],
            'prova': ['Cai muita regra da cadeia composta.'],
            'revisao': ['Derivar f(x) = sen(x²) e conferir com a cadeia.'],
        })
        nota(d['fis'], 'Termodinâmica — 1ª e 2ª Lei', {
            'obs': ['1ª Lei: conservação de energia (ΔU = Q - W).'],
            'conceitos': ['Entropia sempre aumenta em processos espontâneos.'],
        })
        nota(d['ing'], 'Paper Reading — Transformers', {
            'artigos': ['Attention Is All You Need — Vaswani et al., 2017'],
            'carreira': ['Base de LLMs modernos; útil para entrevistas de ML.'],
            'conceitos': ['Self-attention', 'Positional encoding'],
        })

    # ------------------------------------------------------------------ #
    def _resumo(self, aluno):
        def n(model, **f):
            return model.objects.filter(**f).count()

        disc_ids = list(aluno.disciplinas.values_list('id', flat=True))
        self.stdout.write(self.style.SUCCESS('\n[OK] Perfil de demonstracao criado.'))
        self.stdout.write(f'  Aluno .............. {aluno.email}')
        self.stdout.write(f'  Disciplinas ........ {aluno.disciplinas.count()}')
        self.stdout.write(
            f"  Sessoes (total) .... {n(SessaoEstudo, disciplina_id__in=disc_ids)} "
            f"(concluidas: {n(SessaoEstudo, disciplina_id__in=disc_ids, status='CONCLUIDO')}, "
            f"canceladas: {n(SessaoEstudo, disciplina_id__in=disc_ids, status='CANCELADO')}, "
            f"agendadas: {n(SessaoEstudo, disciplina_id__in=disc_ids, status='AGENDADO')})"
        )
        self.stdout.write(
            f'  Blocos Pomodoro .... '
            f'{n(BlocoPomodoro, sessao_estudo__disciplina_id__in=disc_ids)}'
        )
        self.stdout.write(f'  Eventos ............ {n(EventoAcademico, disciplina_id__in=disc_ids)}')
        self.stdout.write(
            f"  Tarefas ............ {n(TarefaDisciplina, disciplina_id__in=disc_ids)} "
            f"(concluidas: {n(TarefaDisciplina, disciplina_id__in=disc_ids, concluida=True)})"
        )
        self.stdout.write(f'  Materiais + notas .. {n(MaterialEstudo, disciplina_id__in=disc_ids)}')
