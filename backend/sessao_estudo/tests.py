from django.test import TestCase
from django.utils import timezone
from datetime import timedelta

from alunos.models import Aluno
from disciplinas.models import Disciplina
from sessao_estudo.models import SessaoEstudo
from services.consistencia_service import ConsistenciaService


class BaseTestConsistencia(TestCase):
    """Base class com helpers comuns para testes de consistência."""

    def criar_sessao(self, disciplina, inicio, fim, duracao, status):
        """Helper para criar sessões com menos repetição."""
        return SessaoEstudo.objects.create(
            disciplina=disciplina,
            inicio=inicio,
            fim=fim,
            duracao_realizada=duracao,
            status=status
        )


# ==================== TASK 2 ====================

class TestConsistenciaServiceTask2(BaseTestConsistencia):
    """Testes para TASK 2: Busca de Sessões da Semana."""

    def setUp(self):
        self.aluno = Aluno.objects.create_user(
            email='aluno@teste.com',
            nome='Aluno Teste',
            password='senha123'
        )
        self.outro_aluno = Aluno.objects.create_user(
            email='outro@teste.com',
            nome='Outro Aluno',
            password='senha123'
        )
        self.disciplina1 = Disciplina.objects.create(
            aluno=self.aluno,
            nome='Banco de Dados',
            codigo='BD101',
            descricao='Disciplina de BD',
            cor='#FF5733',
            meta_horas_semanais=6,
            ativo=True
        )
        self.disciplina2 = Disciplina.objects.create(
            aluno=self.aluno,
            nome='Cálculo',
            codigo='CALC101',
            descricao='Disciplina de Cálculo',
            cor='#3357FF',
            meta_horas_semanais=5,
            ativo=True
        )
        self.servico = ConsistenciaService()

        hoje = timezone.now()
        self.segunda = hoje - timedelta(days=hoje.weekday())
        self.segunda = self.segunda.replace(
            hour=0, minute=0, second=0, microsecond=0
        )

    def test_retorna_sessoes_concluidas_da_semana(self):
        """Retorna sessões concluídas da semana atual."""
        sessao1 = self.criar_sessao(
            self.disciplina1,
            self.segunda + timedelta(hours=19),
            self.segunda + timedelta(hours=21),
            120,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )
        sessao2 = self.criar_sessao(
            self.disciplina1,
            self.segunda + timedelta(days=1, hours=14),
            self.segunda + timedelta(days=1, hours=15, minutes=30),
            90,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )

        sessoes = self.servico.obter_sessoes_semana(self.aluno.id)

        self.assertEqual(len(sessoes), 2)
        self.assertIn(sessao1, sessoes)
        self.assertIn(sessao2, sessoes)

    def test_ignora_sessoes_canceladas(self):
        """Sessões canceladas não são retornadas."""
        self.criar_sessao(
            self.disciplina1,
            self.segunda + timedelta(hours=10),
            self.segunda + timedelta(hours=12),
            0,
            SessaoEstudo.StatusSessao.CANCELADO
        )

        sessoes = self.servico.obter_sessoes_semana(self.aluno.id)

        self.assertEqual(len(sessoes), 0)

    def test_ignora_sessoes_agendadas(self):
        """Sessões agendadas não são retornadas."""
        self.criar_sessao(
            self.disciplina1,
            self.segunda + timedelta(hours=19),
            self.segunda + timedelta(hours=21),
            0,
            SessaoEstudo.StatusSessao.AGENDADO
        )

        sessoes = self.servico.obter_sessoes_semana(self.aluno.id)

        self.assertEqual(len(sessoes), 0)

    def test_ignora_semanas_anteriores(self):
        """Sessões de semanas anteriores não são retornadas."""
        segunda_anterior = self.segunda - timedelta(days=7)
        self.criar_sessao(
            self.disciplina1,
            segunda_anterior + timedelta(hours=19),
            segunda_anterior + timedelta(hours=21),
            120,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )

        sessoes = self.servico.obter_sessoes_semana(self.aluno.id)

        self.assertEqual(len(sessoes), 0)

    def test_ignora_proximas_semanas(self):
        """Sessões de próximas semanas não são retornadas."""
        segunda_proxima = self.segunda + timedelta(days=7)
        self.criar_sessao(
            self.disciplina1,
            segunda_proxima + timedelta(hours=19),
            segunda_proxima + timedelta(hours=21),
            120,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )

        sessoes = self.servico.obter_sessoes_semana(self.aluno.id)

        self.assertEqual(len(sessoes), 0)

    def test_isolamento_por_aluno(self):
        """Sessões de outros alunos não são retornadas."""
        disciplina_outro = Disciplina.objects.create(
            aluno=self.outro_aluno,
            nome='Outra Disciplina',
            codigo='OUT101',
            meta_horas_semanais=5,
            ativo=True
        )
        self.criar_sessao(
            disciplina_outro,
            self.segunda + timedelta(hours=19),
            self.segunda + timedelta(hours=21),
            120,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )

        sessoes = self.servico.obter_sessoes_semana(self.aluno.id)

        self.assertEqual(len(sessoes), 0)

    def test_retorna_sessoes_de_multiplas_disciplinas(self):
        """Sessões de múltiplas disciplinas do aluno são retornadas."""
        sessao1 = self.criar_sessao(
            self.disciplina1,
            self.segunda + timedelta(hours=10),
            self.segunda + timedelta(hours=11),
            60,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )
        sessao2 = self.criar_sessao(
            self.disciplina2,
            self.segunda + timedelta(hours=14),
            self.segunda + timedelta(hours=16),
            120,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )

        sessoes = self.servico.obter_sessoes_semana(self.aluno.id)

        self.assertEqual(len(sessoes), 2)
        self.assertIn(sessao1, sessoes)
        self.assertIn(sessao2, sessoes)

    def test_retorna_queryset_vazio_sem_sessoes(self):
        """Retorna QuerySet vazio quando não há sessões."""
        sessoes = self.servico.obter_sessoes_semana(self.aluno.id)

        self.assertEqual(len(sessoes), 0)

    def test_retorna_sessoes_ordenadas_por_data(self):
        """Sessões são retornadas ordenadas por data de início."""
        sessao3 = self.criar_sessao(
            self.disciplina1,
            self.segunda + timedelta(days=2, hours=19),
            self.segunda + timedelta(days=2, hours=21),
            120,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )
        sessao1 = self.criar_sessao(
            self.disciplina1,
            self.segunda + timedelta(hours=19),
            self.segunda + timedelta(hours=21),
            120,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )
        sessao2 = self.criar_sessao(
            self.disciplina1,
            self.segunda + timedelta(days=1, hours=14),
            self.segunda + timedelta(days=1, hours=16),
            120,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )

        sessoes = list(self.servico.obter_sessoes_semana(self.aluno.id))

        self.assertEqual(len(sessoes), 3)
        self.assertEqual(sessoes[0].id, sessao1.id)
        self.assertEqual(sessoes[1].id, sessao2.id)
        self.assertEqual(sessoes[2].id, sessao3.id)


# ==================== TASK 3 ====================

class TestConsistenciaServiceTask3(BaseTestConsistencia):
    """Testes para TASK 3: Calcular Horas Estudadas."""

    def setUp(self):
        self.aluno = Aluno.objects.create_user(
            email='aluno@teste.com',
            nome='Aluno Teste',
            password='senha123'
        )
        self.disciplina = Disciplina.objects.create(
            aluno=self.aluno,
            nome='Banco de Dados',
            codigo='BD101',
            meta_horas_semanais=6,
            ativo=True
        )
        self.servico = ConsistenciaService()

        hoje = timezone.now()
        self.segunda = hoje - timedelta(days=hoje.weekday())
        self.segunda = self.segunda.replace(
            hour=0, minute=0, second=0, microsecond=0
        )

    def test_soma_duracao_realizada_de_multiplas_sessoes(self):
        """Retorna soma correta de duracao_realizada."""
        self.criar_sessao(
            self.disciplina,
            self.segunda + timedelta(hours=19),
            self.segunda + timedelta(hours=21),
            60,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )
        self.criar_sessao(
            self.disciplina,
            self.segunda + timedelta(days=1),
            self.segunda + timedelta(days=1, hours=2),
            120,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )
        self.criar_sessao(
            self.disciplina,
            self.segunda + timedelta(days=2),
            self.segunda + timedelta(days=2, hours=2),
            90,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )

        resultado = self.servico.calcular_horas_estudadas(self.aluno.id)

        self.assertEqual(resultado['minutos'], 270)
        self.assertEqual(resultado['horas'], 4.5)
        self.assertEqual(resultado['formatado'], '4h 30min')

    def test_retorna_valor_correto_com_uma_sessao(self):
        """Retorna valor correto com uma sessão."""
        self.criar_sessao(
            self.disciplina,
            self.segunda,
            self.segunda + timedelta(hours=2, minutes=30),
            150,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )

        resultado = self.servico.calcular_horas_estudadas(self.aluno.id)

        self.assertEqual(resultado['minutos'], 150)
        self.assertAlmostEqual(resultado['horas'], 2.5, places=2)
        self.assertEqual(resultado['formatado'], '2h 30min')

    def test_retorna_zero_sem_sessoes(self):
        """Retorna zero quando não há sessões."""
        resultado = self.servico.calcular_horas_estudadas(self.aluno.id)

        self.assertEqual(resultado['minutos'], 0)
        self.assertEqual(resultado['horas'], 0.0)
        self.assertEqual(resultado['formatado'], '0h 0min')

    def test_ignora_sessoes_canceladas(self):
        """Ignora sessões canceladas no cálculo."""
        self.criar_sessao(
            self.disciplina,
            self.segunda,
            self.segunda + timedelta(hours=2),
            120,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )
        self.criar_sessao(
            self.disciplina,
            self.segunda + timedelta(days=1),
            self.segunda + timedelta(days=1, hours=2),
            120,
            SessaoEstudo.StatusSessao.CANCELADO
        )

        resultado = self.servico.calcular_horas_estudadas(self.aluno.id)

        self.assertEqual(resultado['minutos'], 120)
        self.assertEqual(resultado['formatado'], '2h 0min')

    def test_formata_corretamente_horas_e_minutos(self):
        """Formata corretamente em horas e minutos."""
        self.criar_sessao(
            self.disciplina,
            self.segunda,
            self.segunda + timedelta(hours=3, minutes=45),
            225,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )

        resultado = self.servico.calcular_horas_estudadas(self.aluno.id)

        self.assertEqual(resultado['minutos'], 225)
        self.assertEqual(resultado['formatado'], '3h 45min')


# ==================== TASK 4 ====================

class TestConsistenciaServiceTask4(BaseTestConsistencia):
    """Testes para TASK 4: Calcular Horas Planejadas."""

    def setUp(self):
        self.aluno = Aluno.objects.create_user(
            email='aluno@teste.com',
            nome='Aluno Teste',
            password='senha123'
        )
        self.disciplina = Disciplina.objects.create(
            aluno=self.aluno,
            nome='Banco de Dados',
            codigo='BD101',
            meta_horas_semanais=6,
            ativo=True
        )
        self.servico = ConsistenciaService()

        hoje = timezone.now()
        self.segunda = hoje - timedelta(days=hoje.weekday())
        self.segunda = self.segunda.replace(
            hour=0, minute=0, second=0, microsecond=0
        )
        self.servico._cache_sessoes = {}

    def test_soma_fim_menos_inicio_de_multiplas_sessoes(self):
        """Cenário Real: Múltiplas sessões em dias diferentes da semana calculadas com precisão"""
        self.servico._cache_sessoes = {}

        # Segunda-feira - 19:00 às 21:00 (120 min)
        self.criar_sessao(
            self.disciplina,
            self.segunda + timedelta(hours=19),
            self.segunda + timedelta(hours=21),
            120,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )
        # Terça-feira - 14:00 às 16:30 (150 min)
        self.criar_sessao(
            self.disciplina,
            self.segunda + timedelta(days=1, hours=14),
            self.segunda + timedelta(days=1, hours=16, minutes=30),
            150,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )
        # Quarta-feira - 10:00 às 10:30 (30 min)
        self.criar_sessao(
            self.disciplina,
            self.segunda + timedelta(days=2, hours=10),
            self.segunda + timedelta(days=2, hours=10, minutes=30),
            30,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )

        resultado = self.servico.calcular_horas_planejadas(self.aluno.id)
        self.assertEqual(resultado['minutos'], 300)
        

    def test_retorna_valor_correto_com_uma_sessao(self):
        """Retorna valor correto com uma sessão."""
        self.criar_sessao(
            self.disciplina,
            self.segunda,
            self.segunda + timedelta(hours=3),
            180,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )

        resultado = self.servico.calcular_horas_planejadas(self.aluno.id)

        self.assertEqual(resultado['minutos'], 180)
        self.assertEqual(resultado['horas'], 3.0)
        self.assertEqual(resultado['formatado'], '3h 0min')

    def test_retorna_zero_sem_sessoes(self):
        """Retorna zero quando não há sessões."""
        resultado = self.servico.calcular_horas_planejadas(self.aluno.id)

        self.assertEqual(resultado['minutos'], 0)
        self.assertEqual(resultado['horas'], 0.0)
        self.assertEqual(resultado['formatado'], '0h 0min')

    def test_ignora_sessoes_canceladas(self):
        """Ignora sessões canceladas."""
        self.criar_sessao(
            self.disciplina,
            self.segunda,
            self.segunda + timedelta(hours=2),
            120,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )
        self.criar_sessao(
            self.disciplina,
            self.segunda + timedelta(days=1),
            self.segunda + timedelta(days=1, hours=3),
            180,
            SessaoEstudo.StatusSessao.CANCELADO
        )

        resultado = self.servico.calcular_horas_planejadas(self.aluno.id)

        self.assertEqual(resultado['minutos'], 120)
        self.assertEqual(resultado['formatado'], '2h 0min')

    def test_calcula_corretamente_com_minutos_fracionados(self):
        """Calcula corretamente com minutos fracionados."""
        self.criar_sessao(
            self.disciplina,
            self.segunda,
            self.segunda + timedelta(hours=2, minutes=45),
            165,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )

        resultado = self.servico.calcular_horas_planejadas(self.aluno.id)

        self.assertEqual(resultado['minutos'], 165)
        self.assertEqual(resultado['formatado'], '2h 45min')


# ==================== DISCIPLINA ESPECÍFICA ====================

class TestConsistenciaServiceDisciplinaEspecifica(BaseTestConsistencia):
    """Testes para funções de cálculos por disciplina específica."""

    def setUp(self):
        self.aluno = Aluno.objects.create_user(
            email='aluno@teste.com',
            nome='Aluno Teste',
            password='senha123'
        )
        self.disciplina1 = Disciplina.objects.create(
            aluno=self.aluno,
            nome='Banco de Dados',
            codigo='BD101',
            meta_horas_semanais=6,
            ativo=True
        )
        self.disciplina2 = Disciplina.objects.create(
            aluno=self.aluno,
            nome='Cálculo',
            codigo='CALC101',
            meta_horas_semanais=5,
            ativo=True
        )
        self.servico = ConsistenciaService()

        hoje = timezone.now()
        self.segunda = hoje - timedelta(days=hoje.weekday())
        self.segunda = self.segunda.replace(
            hour=0, minute=0, second=0, microsecond=0
        )

    def test_horas_estudadas_retorna_apenas_da_disciplina_especifica(self):
        """Retorna horas apenas da disciplina específica."""
        self.criar_sessao(
            self.disciplina1,
            self.segunda,
            self.segunda + timedelta(hours=2),
            120,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )
        self.criar_sessao(
            self.disciplina2,
            self.segunda + timedelta(days=1),
            self.segunda + timedelta(days=1, hours=3),
            180,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )

        resultado = self.servico.calcular_horas_estudadas_disciplina(
            self.aluno.id, self.disciplina1.id
        )

        self.assertEqual(resultado['minutos'], 120)
        self.assertEqual(resultado['formatado'], '2h 0min')

    def test_horas_estudadas_soma_multiplas_sessoes_da_mesma_disciplina(self):
        """Soma horas de múltiplas sessões da mesma disciplina."""
        self.criar_sessao(
            self.disciplina1,
            self.segunda,
            self.segunda + timedelta(hours=2),
            120,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )
        self.criar_sessao(
            self.disciplina1,
            self.segunda + timedelta(days=2),
            self.segunda + timedelta(days=2, hours=1, minutes=30),
            90,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )

        resultado = self.servico.calcular_horas_estudadas_disciplina(
            self.aluno.id, self.disciplina1.id
        )

        self.assertEqual(resultado['minutos'], 210)
        self.assertEqual(resultado['formatado'], '3h 30min')

    def test_horas_estudadas_retorna_zero_sem_sessoes(self):
        """Retorna zero quando não há sessões na disciplina."""
        resultado = self.servico.calcular_horas_estudadas_disciplina(
            self.aluno.id, self.disciplina1.id
        )

        self.assertEqual(resultado['minutos'], 0)
        self.assertEqual(resultado['formatado'], '0h 0min')

    def test_horas_planejadas_retorna_apenas_da_disciplina_especifica(self):
        """Retorna horas planejadas apenas da disciplina específica."""
        self.criar_sessao(
            self.disciplina1,
            self.segunda,
            self.segunda + timedelta(hours=3),
            100,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )
        self.criar_sessao(
            self.disciplina2,
            self.segunda + timedelta(days=1),
            self.segunda + timedelta(days=1, hours=2),
            100,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )

        resultado = self.servico.calcular_horas_planejadas_disciplina(
            self.aluno.id, self.disciplina1.id
        )

        self.assertEqual(resultado['minutos'], 180)
        self.assertEqual(resultado['formatado'], '3h 0min')

    def test_horas_planejadas_soma_multiplas_sessoes(self):
        """Soma horas planejadas de múltiplas sessões."""
        self.criar_sessao(
            self.disciplina1,
            self.segunda,
            self.segunda + timedelta(hours=2),
            100,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )
        self.criar_sessao(
            self.disciplina1,
            self.segunda + timedelta(days=1),
            self.segunda + timedelta(days=1, hours=1, minutes=30),
            80,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )

        resultado = self.servico.calcular_horas_planejadas_disciplina(
            self.aluno.id, self.disciplina1.id
        )

        self.assertEqual(resultado['minutos'], 210)
        self.assertEqual(resultado['formatado'], '3h 30min')

    def test_diferenca_entre_horas_estudadas_e_planejadas(self):
        """Horas estudadas e planejadas podem diferir."""
        self.criar_sessao(
            self.disciplina1,
            self.segunda,
            self.segunda + timedelta(hours=3),
            120,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )

        horas_estudadas = self.servico.calcular_horas_estudadas_disciplina(
            self.aluno.id, self.disciplina1.id
        )
        horas_planejadas = self.servico.calcular_horas_planejadas_disciplina(
            self.aluno.id, self.disciplina1.id
        )

        self.assertEqual(horas_estudadas['minutos'], 120)
        self.assertEqual(horas_planejadas['minutos'], 180)
        self.assertLess(horas_estudadas['horas'], horas_planejadas['horas'])


# ==================== TASK 5 ====================

class TestConsistenciaServiceTask5(BaseTestConsistencia):
    """Testes para TASK 5: Calcular Sessões Concluídas."""

    def setUp(self):
        self.aluno = Aluno.objects.create_user(
            email='aluno@teste.com',
            nome='Aluno Teste',
            password='senha123'
        )
        self.disciplina = Disciplina.objects.create(
            aluno=self.aluno,
            nome='Banco de Dados',
            codigo='BD101',
            meta_horas_semanais=6,
            ativo=True
        )
        self.servico = ConsistenciaService()

        hoje = timezone.now()
        self.segunda = hoje - timedelta(days=hoje.weekday())
        self.segunda = self.segunda.replace(
            hour=0, minute=0, second=0, microsecond=0
        )

    def test_conta_corretamente_multiplas_sessoes(self):
        """Retorna contagem correta de sessões."""
        for i in range(5):
            self.criar_sessao(
                self.disciplina,
                self.segunda + timedelta(days=i, hours=10),
                self.segunda + timedelta(days=i, hours=11),
                60,
                SessaoEstudo.StatusSessao.CONCLUIDO
            )

        resultado = self.servico.calcular_sessoes_concluidas(self.aluno.id)

        self.assertEqual(resultado, 5)

    def test_ignora_sessoes_canceladas(self):
        """Ignora sessões canceladas."""
        self.criar_sessao(
            self.disciplina,
            self.segunda,
            self.segunda + timedelta(hours=1),
            60,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )
        self.criar_sessao(
            self.disciplina,
            self.segunda + timedelta(days=1),
            self.segunda + timedelta(days=1, hours=1),
            60,
            SessaoEstudo.StatusSessao.CANCELADO
        )

        resultado = self.servico.calcular_sessoes_concluidas(self.aluno.id)

        self.assertEqual(resultado, 1)

    def test_retorna_zero_sem_sessoes(self):
        """Retorna zero quando não há sessões."""
        resultado = self.servico.calcular_sessoes_concluidas(self.aluno.id)

        self.assertEqual(resultado, 0)


# ==================== TASK 6 ====================

class TestConsistenciaServiceTask6(BaseTestConsistencia):
    """Testes para TASK 6: Calcular Consistência por Dia."""

    def setUp(self):
        self.aluno = Aluno.objects.create_user(
            email='aluno@teste.com',
            nome='Aluno Teste',
            password='senha123'
        )
        self.disciplina = Disciplina.objects.create(
            aluno=self.aluno,
            nome='Banco de Dados',
            codigo='BD101',
            meta_horas_semanais=6,
            ativo=True
        )
        self.servico = ConsistenciaService()

        hoje = timezone.now()
        self.segunda = hoje - timedelta(days=hoje.weekday())
        self.segunda = self.segunda.replace(
            hour=0, minute=0, second=0, microsecond=0
        )

    def test_marca_dias_com_estudo_corretamente(self):
        """Marca dias com estudo corretamente."""
        self.criar_sessao(
            self.disciplina,
            self.segunda,
            self.segunda + timedelta(hours=1),
            60,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )
        self.criar_sessao(
            self.disciplina,
            self.segunda + timedelta(days=2),
            self.segunda + timedelta(days=2, hours=1),
            60,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )

        resultado = self.servico.calcular_consistencia_por_dia(self.aluno.id)

        self.assertTrue(resultado['segunda'])
        self.assertFalse(resultado['terça'])
        self.assertTrue(resultado['quarta'])
        self.assertEqual(resultado['dias_com_estudo'], 2)

    def test_retorna_todos_false_sem_sessoes(self):
        """Retorna todos false quando sem sessões."""
        resultado = self.servico.calcular_consistencia_por_dia(self.aluno.id)

        self.assertEqual(resultado['dias_com_estudo'], 0)
        for dia in ['segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo']:
            self.assertFalse(resultado[dia])


# ==================== TASK 7 ====================

class TestConsistenciaServiceTask7(BaseTestConsistencia):
    """Testes para TASK 7: Calcular Frequência Semanal."""

    def setUp(self):
        self.aluno = Aluno.objects.create_user(
            email='aluno@teste.com',
            nome='Aluno Teste',
            password='senha123'
        )
        self.disciplina = Disciplina.objects.create(
            aluno=self.aluno,
            nome='Banco de Dados',
            codigo='BD101',
            meta_horas_semanais=6,
            ativo=True
        )
        self.servico = ConsistenciaService()

        hoje = timezone.now()
        self.segunda = hoje - timedelta(days=hoje.weekday())
        self.segunda = self.segunda.replace(
            hour=0, minute=0, second=0, microsecond=0
        )

    def test_calcula_percentual_correto(self):
        """Calcula percentual correto de dias estudados."""
        for i in range(5):
            self.criar_sessao(
                self.disciplina,
                self.segunda + timedelta(days=i),
                self.segunda + timedelta(days=i, hours=1),
                60,
                SessaoEstudo.StatusSessao.CONCLUIDO
            )

        resultado = self.servico.calcular_frequencia_semanal(self.aluno.id)

        self.assertAlmostEqual(resultado['percentual'], 71.43, places=1)
        self.assertEqual(resultado['dias_estudados'], 5)
        self.assertEqual(resultado['dias_totais'], 7)

    def test_retorna_zero_sem_sessoes(self):
        """Retorna 0% quando sem sessões."""
        resultado = self.servico.calcular_frequencia_semanal(self.aluno.id)

        self.assertEqual(resultado['percentual'], 0.0)
        self.assertEqual(resultado['dias_estudados'], 0)


# ==================== TASK 9 ====================

class TestConsistenciaServiceTask9(BaseTestConsistencia):
    """Testes para TASK 9: Calcular Metas das Disciplinas."""

    def setUp(self):
        self.aluno = Aluno.objects.create_user(
            email='aluno@teste.com',
            nome='Aluno Teste',
            password='senha123'
        )
        self.disciplina1 = Disciplina.objects.create(
            aluno=self.aluno,
            nome='Banco de Dados',
            codigo='BD101',
            meta_horas_semanais=6,
            ativo=True
        )
        self.disciplina2 = Disciplina.objects.create(
            aluno=self.aluno,
            nome='Cálculo',
            codigo='CALC101',
            meta_horas_semanais=5,
            ativo=True
        )
        self.servico = ConsistenciaService()

        hoje = timezone.now()
        self.segunda = hoje - timedelta(days=hoje.weekday())
        self.segunda = self.segunda.replace(
            hour=0, minute=0, second=0, microsecond=0
        )

    def test_marca_como_atingida_quando_horas_igual_meta(self):
        """Marca como atingida quando horas >= meta."""
        self.criar_sessao(
            self.disciplina1,
            self.segunda,
            self.segunda + timedelta(hours=6),
            360,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )

        resultado = self.servico.calcular_meta_disciplinas(self.aluno.id)
        bd_meta = next(
            m for m in resultado if m['disciplina_id'] == str(self.disciplina1.id))

        self.assertTrue(bd_meta['atingiu'])
        self.assertEqual(bd_meta['horas_estudadas'], 6.0)

    def test_marca_como_nao_atingida_quando_horas_abaixo_da_meta(self):
        """Marca como não atingida quando horas < meta."""
        self.criar_sessao(
            self.disciplina1,
            self.segunda,
            self.segunda + timedelta(hours=3),
            180,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )

        resultado = self.servico.calcular_meta_disciplinas(self.aluno.id)
        bd_meta = next(
            m for m in resultado if m['disciplina_id'] == str(self.disciplina1.id))

        self.assertFalse(bd_meta['atingiu'])
        self.assertEqual(bd_meta['horas_estudadas'], 3.0)


# ==================== TASK 11 ====================

class TestConsistenciaServiceTask11(BaseTestConsistencia):
    """Testes para TASK 11: Calcular Índice de Consistência."""

    def setUp(self):
        self.aluno = Aluno.objects.create_user(
            email='aluno@teste.com',
            nome='Aluno Teste',
            password='senha123'
        )
        self.disciplina = Disciplina.objects.create(
            aluno=self.aluno,
            nome='Banco de Dados',
            codigo='BD101',
            meta_horas_semanais=6,
            ativo=True
        )
        self.servico = ConsistenciaService()

        hoje = timezone.now()
        self.segunda = hoje - timedelta(days=hoje.weekday())
        self.segunda = self.segunda.replace(
            hour=0, minute=0, second=0, microsecond=0
        )

    def test_retorna_score_entre_0_e_100(self):
        """Retorna score entre 0-100."""
        for i in range(5):
            self.criar_sessao(
                self.disciplina,
                self.segunda + timedelta(days=i, hours=10),
                self.segunda + timedelta(days=i, hours=12),
                120,
                SessaoEstudo.StatusSessao.CONCLUIDO
            )

        resultado = self.servico.calcular_indice_consistencia(self.aluno.id)

        self.assertIn('indice', resultado)
        self.assertIn('componentes', resultado)
        self.assertGreaterEqual(resultado['indice'], 0)
        self.assertLessEqual(resultado['indice'], 100)

    def test_retorna_indice_baixo_sem_sessoes(self):
        """Retorna índice baixo sem sessões."""
        resultado = self.servico.calcular_indice_consistencia(self.aluno.id)

        self.assertLess(resultado['indice'], 50)


# ==================== TASK 12 ====================

class TestConsistenciaServiceTask12(BaseTestConsistencia):
    """Testes para TASK 12: Calcular Distribuição de Disciplinas."""

    def setUp(self):
        self.aluno = Aluno.objects.create_user(
            email='aluno@teste.com',
            nome='Aluno Teste',
            password='senha123'
        )
        self.disciplina1 = Disciplina.objects.create(
            aluno=self.aluno,
            nome='Banco de Dados',
            codigo='BD101',
            meta_horas_semanais=6,
            ativo=True
        )
        self.disciplina2 = Disciplina.objects.create(
            aluno=self.aluno,
            nome='Cálculo',
            codigo='CALC101',
            meta_horas_semanais=5,
            ativo=True
        )
        self.servico = ConsistenciaService()

        hoje = timezone.now()
        self.segunda = hoje - timedelta(days=hoje.weekday())
        self.segunda = self.segunda.replace(
            hour=0, minute=0, second=0, microsecond=0
        )

    def test_retorna_distribuicao_com_percentuais_corretos(self):
        """Retorna distribuição com percentuais corretos."""
        self.criar_sessao(
            self.disciplina1,
            self.segunda,
            self.segunda + timedelta(hours=4),
            240,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )
        self.criar_sessao(
            self.disciplina2,
            self.segunda + timedelta(days=1),
            self.segunda + timedelta(days=1, hours=2),
            120,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )

        resultado = self.servico.calcular_distribuicao_disciplinas(
            self.aluno.id)

        self.assertEqual(len(resultado), 2)
        self.assertEqual(resultado[0]['horas'], 4.0)
        self.assertEqual(resultado[0]['percentual'], 66.67)


# ==================== TASK 13 ====================

class TestConsistenciaServiceTask13(BaseTestConsistencia):
    """Testes para TASK 13: Detectar Baixa Consistência."""

    def setUp(self):
        self.aluno = Aluno.objects.create_user(
            email='aluno@teste.com',
            nome='Aluno Teste',
            password='senha123'
        )
        self.disciplina = Disciplina.objects.create(
            aluno=self.aluno,
            nome='Banco de Dados',
            codigo='BD101',
            meta_horas_semanais=6,
            ativo=True
        )
        self.servico = ConsistenciaService()

        hoje = timezone.now()
        self.segunda = hoje - timedelta(days=hoje.weekday())
        self.segunda = self.segunda.replace(
            hour=0, minute=0, second=0, microsecond=0
        )

    def test_gera_alertas_quando_consistencia_esta_baixa(self):
        """Gera alertas quando consistência está baixa."""
        self.criar_sessao(
            self.disciplina,
            self.segunda,
            self.segunda + timedelta(hours=2),
            120,
            SessaoEstudo.StatusSessao.CONCLUIDO
        )

        resultado = self.servico.detectar_baixa_consistencia(self.aluno.id)

        self.assertIn('alertas', resultado)
        self.assertIn('severidade', resultado)
        self.assertGreater(len(resultado['alertas']), 0)


# ==================== TASK 14 ====================

class TestConsistenciaServiceTask14(BaseTestConsistencia):
    """Testes para TASK 14: Comparar Semanas."""

    def setUp(self):
        self.aluno = Aluno.objects.create_user(
            email='aluno@teste.com',
            nome='Aluno Teste',
            password='senha123'
        )
        self.disciplina = Disciplina.objects.create(
            aluno=self.aluno,
            nome='Banco de Dados',
            codigo='BD101',
            meta_horas_semanais=6,
            ativo=True
        )
        self.servico = ConsistenciaService()

    def test_retorna_estrutura_com_semanas_e_diferenca(self):
        """Retorna estrutura com semanas e diferença."""
        resultado = self.servico.comparar_semanas(self.aluno.id)

        self.assertIn('semana_atual', resultado)
        self.assertIn('semana_anterior', resultado)
        self.assertIn('diferenca', resultado)
        self.assertIn('sessoes', resultado['semana_atual'])
        self.assertIn('horas', resultado['semana_atual'])


# ==================== TASK 15 ====================

class TestConsistenciaServiceTask15(BaseTestConsistencia):
    """Testes para TASK 15: Obter Evolução de Consistência."""

    def setUp(self):
        self.aluno = Aluno.objects.create_user(
            email='aluno@teste.com',
            nome='Aluno Teste',
            password='senha123'
        )
        self.disciplina = Disciplina.objects.create(
            aluno=self.aluno,
            nome='Banco de Dados',
            codigo='BD101',
            meta_horas_semanais=6,
            ativo=True
        )
        self.servico = ConsistenciaService()

    def test_retorna_historico_de_12_semanas(self):
        """Retorna histórico de 12 semanas."""
        resultado = self.servico.obter_evolucao_consistencia(
            self.aluno.id, semanas=12
        )

        self.assertEqual(len(resultado), 12)
        for semana in resultado:
            self.assertIn('semana', semana)
            self.assertIn('indice', semana)
            self.assertIn('sessoes', semana)
            self.assertIn('horas', semana)


# ==================== TASK 16 ====================

class TestConsistenciaServiceTask16(BaseTestConsistencia):
    """Testes para TASK 16: Obter Dashboard Completo."""

    def setUp(self):
        self.aluno = Aluno.objects.create_user(
            email='aluno@teste.com',
            nome='Aluno Teste',
            password='senha123'
        )
        self.disciplina = Disciplina.objects.create(
            aluno=self.aluno,
            nome='Banco de Dados',
            codigo='BD101',
            meta_horas_semanais=6,
            ativo=True
        )
        self.servico = ConsistenciaService()

    def test_retorna_estrutura_completa_do_dashboard(self):
        """Retorna dashboard com todos os indicadores."""
        resultado = self.servico.obter_dashboard_consistencia(self.aluno.id)

        self.assertIn('resumo', resultado)
        self.assertIn('indicadores', resultado)
        self.assertIn('metas', resultado)
        self.assertIn('comparacao', resultado)
        self.assertIn('analise', resultado)
        self.assertIn('evolucao', resultado)

        self.assertIn('indice_consistencia', resultado['resumo'])
        self.assertIn('frequencia', resultado['indicadores'])
        self.assertIn('por_disciplina', resultado['metas'])
