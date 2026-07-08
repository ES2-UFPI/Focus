"""Popula o banco com a persona de demonstração dos Insights.

Persona: **Marina Alves**, 5º período de Engenharia de Software, estagia à
tarde e usa o Focus para manter Estruturas de Dados (ED), Banco de Dados (BD) e
Redes de Computadores sob controle. É a mesma persona da demo do frontend
(`frontend/lib/data/insights_mock.dart`).

Os dados são desenhados para acionar, de uma vez, todos os insights que a tela
atual exibe:

| Insight             | Seção      | Padrão semeado                                    |
|---------------------|------------|---------------------------------------------------|
| taxa_furo           | Melhorar   | Sexta à noite de BD com muitos cancelamentos      |
| duracao_ideal       | Melhorar   | Blocos longos de BD (85 min) perdem produtividade |
| ritmo_disciplina    | Melhorar   | Redes some nas últimas 2 semanas                  |
| vies_estimativa     | Melhorar   | BD planejado p/ 60 min termina em ~85 min         |
| melhor_horario      | Descoberta | ED de manhã rende bem melhor que à noite          |
| tarefas_no_prazo    | Descoberta | ~75% das tarefas entregues no prazo               |
| sequencia_produtiva | Descoberta | Sequência recente de manhãs produtivas de ED      |
| progresso + jornada | Evolução   | Cancelamentos caem do início para o fim da janela |

Idempotente: recria a Marina a cada execução (`--email` para trocar o login).
"""

from datetime import timedelta

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from alunos.models import Aluno
from disciplinas.models import Disciplina
from sessao_estudo.models import BlocoPomodoro, SessaoEstudo
from tarefas_disciplina.models import TarefaDisciplina

CONCLUIDO = SessaoEstudo.StatusSessao.CONCLUIDO
CANCELADO = SessaoEstudo.StatusSessao.CANCELADO

EMAIL_PADRAO = 'marina.demo@focus.test'
SENHA_PADRAO = 'demo12345'


class Command(BaseCommand):
    help = (
        'Popula o banco com a persona de demonstração Marina Alves e dados '
        'fictícios que acionam todos os insights da tela atual.'
    )

    def add_arguments(self, parser):
        parser.add_argument('--email', default=EMAIL_PADRAO)
        parser.add_argument('--senha', default=SENHA_PADRAO)

    @transaction.atomic
    def handle(self, *args, **options):
        email = options['email']
        senha = options['senha']

        # Idempotência: apagar a persona antiga apaga em cascata disciplinas,
        # sessões, blocos, tarefas e feedbacks de insight.
        removidos, _ = Aluno.objects.filter(email=email).delete()
        if removidos:
            self.stdout.write(f'Persona anterior removida ({email}).')

        aluno = Aluno.objects.create_user(
            email=email, nome='Marina Alves', password=senha,
        )
        ed = Disciplina.objects.create(
            aluno=aluno, nome='Estruturas de Dados', codigo='ED',
            cor='#6366F1', meta_horas_semanais=4,
        )
        bd = Disciplina.objects.create(
            aluno=aluno, nome='Banco de Dados', codigo='BD',
            cor='#0EA5E9', meta_horas_semanais=4,
        )
        redes = Disciplina.objects.create(
            aluno=aluno, nome='Redes de Computadores', codigo='RED',
            cor='#F97316', meta_horas_semanais=3,
        )

        # Base "agora" em horário local, normalizada, para posicionar os dias.
        base = timezone.localtime(timezone.now()).replace(
            minute=0, second=0, microsecond=0,
        )
        self._base = base
        self._contadores = {'sessoes': 0, 'canceladas': 0, 'blocos': 0, 'tarefas': 0}

        # ---------------- Descobertas ----------------

        # melhor_horario + sequencia_produtiva: cauda recente e limpa de manhãs
        # de ED muito produtivas (dias -2 a -6, sem nenhuma sessão fraca depois).
        for dia in (2, 3, 4, 5, 6):
            self._sessao(ed, self._em(dia, 8), planejada=45, real=45,
                         prod=5, tipo=SessaoEstudo.TipoAtividade.EXERCICIO)

        # Redes: 6 sessões de manhã, todas com mais de 14 dias → matéria
        # negligenciada nas últimas 2 semanas (ritmo_disciplina).
        for dia in (19, 24, 27, 31, 34, 39):
            self._sessao(redes, self._em(dia, 9), planejada=50, real=50,
                         prod=4, tipo=SessaoEstudo.TipoAtividade.LEITURA)

        # ---------------- Pontos para melhorar ----------------

        # duracao_ideal + vies_estimativa: revisões de BD planejadas para 60 min
        # que arrastam para ~85 min e derrubam a produtividade (bloco longo, à
        # noite, produtividade baixa).
        for dia, prod in ((8, 3), (10, 2), (12, 2), (16, 3), (18, 2)):
            self._sessao(bd, self._em(dia, 19), planejada=60, real=85,
                         prod=prod, interrupcoes=3,
                         tipo=SessaoEstudo.TipoAtividade.REVISAO)

        # taxa_furo + progresso + jornada: sexta à noite de BD.
        # Cancelamentos concentrados no começo da janela e raros no fim.
        dias_ate_sexta = (base.weekday() - 4) % 7
        sexta_recente = dias_ate_sexta + 7  # 7..13 dias atrás (fora da cauda limpa)
        fridays = {
            'recente': sexta_recente,          # ~1 semana e meia atrás
            'antiga_1': sexta_recente + 21,    # ~4 semanas atrás
            'antiga_2': sexta_recente + 28,    # ~5 semanas atrás
        }
        # (hora, status, prod) de cada sessão de sexta à noite.
        self._sexta(bd, fridays['recente'], [
            (20, CONCLUIDO, 2), (22, CANCELADO, None),
        ])
        self._sexta(bd, fridays['antiga_1'], [
            (20, CANCELADO, None), (22, CANCELADO, None),
        ])
        self._sexta(bd, fridays['antiga_2'], [
            (20, CANCELADO, None), (22, CONCLUIDO, 2),
        ])

        # ---------------- Tarefas (tarefas_no_prazo) ----------------
        # 6 no prazo + 2 atrasadas = 75% de entregas no prazo.
        for i in range(6):
            prazo = self._em(3 + i * 2, 18)
            self._tarefa(bd if i % 2 else ed, f'Entrega em dia #{i + 1}',
                         prazo, prazo - timedelta(days=1))
        for i in range(2):
            prazo = self._em(4 + i * 3, 18)
            self._tarefa(bd, f'Entrega atrasada #{i + 1}',
                         prazo, prazo + timedelta(days=1))

        self._resumo(aluno, email, senha)

    # ==================== Helpers ====================

    def _em(self, dias, hora):
        """Datetime `dias` atrás, no horário `hora`."""
        return (self._base - timedelta(days=dias)).replace(hour=hora)

    def _sessao(self, disciplina, inicio, planejada, real, prod,
                status=CONCLUIDO, interrupcoes=0, tipo=None):
        fim = inicio + timedelta(minutes=planejada)
        sessao = SessaoEstudo.objects.create(
            disciplina=disciplina,
            inicio=inicio,
            fim=fim,
            duracao_realizada=real if status == CONCLUIDO else 0,
            status=status,
            interrupcoes=interrupcoes,
            tipo_atividade=tipo,
        )
        self._contadores['sessoes'] += 1
        if status == CANCELADO:
            self._contadores['canceladas'] += 1
        # A produtividade da sessão vem da avaliação de um bloco pomodoro.
        if prod is not None and status == CONCLUIDO:
            BlocoPomodoro.objects.create(
                sessao_estudo=sessao,
                numero_ciclo=1,
                inicio=inicio,
                fim=inicio + timedelta(minutes=25),
                duracao_planejada_segundos=1500,
                duracao_realizada_segundos=real * 60,
                interrupcoes=interrupcoes,
                status=BlocoPomodoro.StatusBloco.CONCLUIDO,
                produtividade=prod,
            )
            self._contadores['blocos'] += 1
        return sessao

    def _sexta(self, disciplina, dias, blocos):
        """Cria as sessões de uma sexta à noite (lista de (hora, status, prod))."""
        for hora, status, prod in blocos:
            self._sessao(disciplina, self._em(dias, hora), planejada=45,
                         real=45, prod=prod, status=status, interrupcoes=1,
                         tipo=SessaoEstudo.TipoAtividade.REVISAO)

    def _tarefa(self, disciplina, titulo, prazo, data_conclusao):
        TarefaDisciplina.objects.create(
            disciplina=disciplina,
            titulo=titulo,
            prazo=prazo,
            concluida=True,
            data_conclusao=data_conclusao,
        )
        self._contadores['tarefas'] += 1

    def _resumo(self, aluno, email, senha):
        c = self._contadores
        self.stdout.write(self.style.SUCCESS('\nSeed concluído: persona Marina Alves.'))
        self.stdout.write(f'  Login .......... {email} / {senha}')
        self.stdout.write(f'  Aluno id ....... {aluno.id}')
        self.stdout.write(
            f'  Sessões ........ {c["sessoes"]} '
            f'({c["canceladas"]} canceladas), blocos: {c["blocos"]}'
        )
        self.stdout.write(f'  Tarefas ........ {c["tarefas"]}')
        self.stdout.write(
            '  Insights esperados: taxa_furo, duracao_ideal, ritmo_disciplina, '
            'vies_estimativa (melhorar); melhor_horario, tarefas_no_prazo, '
            'sequencia_produtiva, progresso (descobertas); jornada com melhoria '
            'de cancelamentos.'
        )
