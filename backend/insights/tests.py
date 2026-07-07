from datetime import timedelta

from django.utils import timezone
from rest_framework.test import APITestCase

from alunos.models import Aluno
from disciplinas.models import Disciplina
from eventos_academicos.models import EventoAcademico
from sessao_estudo.models import BlocoPomodoro, SessaoEstudo
from tarefas_disciplina.models import TarefaDisciplina

from insights.models import InsightFeedback
from insights.services import InsightsService


class InsightsTestBase(APITestCase):
    def setUp(self):
        self.aluno = Aluno.objects.create_user(
            email='insights@teste.com',
            nome='Aluno Insights',
            password='senha123',
        )
        self.disciplina = Disciplina.objects.create(
            aluno=self.aluno,
            nome='ES2',
            cor='#6366F1',
            meta_horas_semanais=4,
        )
        self.client.force_authenticate(self.aluno)

    def _sessao(self, inicio, duracao_real=45, planejada_min=None,
                produtividade=4, interrupcoes=0, tipo=None,
                status=SessaoEstudo.StatusSessao.CONCLUIDO, disciplina=None):
        disciplina = disciplina or self.disciplina
        planejada = planejada_min if planejada_min is not None else duracao_real
        sessao = SessaoEstudo.objects.create(
            disciplina=disciplina,
            inicio=inicio,
            fim=inicio + timedelta(minutes=planejada),
            duracao_realizada=duracao_real,
            status=status,
            interrupcoes=interrupcoes,
            tipo_atividade=tipo,
        )
        if produtividade is not None and status == SessaoEstudo.StatusSessao.CONCLUIDO:
            BlocoPomodoro.objects.create(
                sessao_estudo=sessao,
                numero_ciclo=1,
                inicio=inicio,
                fim=inicio + timedelta(minutes=25),
                duracao_planejada_segundos=1500,
                duracao_realizada_segundos=duracao_real * 60,
                interrupcoes=interrupcoes,
                status=BlocoPomodoro.StatusBloco.CONCLUIDO,
                produtividade=produtividade,
            )
        return sessao

    def _base_local(self):
        """Agora em horário local, normalizado ao minuto zero."""
        return timezone.localtime(timezone.now()).replace(
            minute=0, second=0, microsecond=0
        )

    def _tipos(self):
        return {ins['tipo'] for ins in InsightsService().obter_insights(self.aluno.id)}

    def _por_tipo(self, tipo):
        for ins in InsightsService().obter_insights(self.aluno.id):
            if ins['tipo'] == tipo:
                return ins
        return None


class MelhorHorarioTests(InsightsTestBase):
    def test_detecta_melhor_rendimento_pela_manha(self):
        base = self._base_local()
        # 8 sessões de manhã com produtividade alta.
        for i in range(8):
            self._sessao(
                base.replace(hour=8) - timedelta(days=2 * i + 1),
                produtividade=5,
            )
        # 8 sessões à noite com produtividade baixa.
        for i in range(8):
            self._sessao(
                base.replace(hour=21) - timedelta(days=2 * i + 2),
                produtividade=2,
            )

        insight = self._por_tipo('melhor_horario')
        self.assertIsNotNone(insight)
        self.assertEqual(insight['severidade'], 'positivo')
        self.assertGreater(insight['numeros']['manha'], insight['numeros']['noite'])
        self.assertEqual(insight['confianca'], 'alta')  # 16 sessões (>= 15)
        self.assertEqual(len(insight['grafico']['valores']), 6)


class DuracaoIdealTests(InsightsTestBase):
    def test_detecta_queda_apos_limite(self):
        base = self._base_local().replace(hour=10)
        for i in range(6):
            self._sessao(base - timedelta(days=2 * i + 1),
                         duracao_real=40, produtividade=5)
        for i in range(6):
            self._sessao(base - timedelta(days=2 * i + 2),
                         duracao_real=85, produtividade=2)

        insight = self._por_tipo('duracao_ideal')
        self.assertIsNotNone(insight)
        self.assertEqual(insight['severidade'], 'atencao')
        self.assertGreater(insight['numeros']['queda_pct'], 15)


class ViesEstimativaTests(InsightsTestBase):
    def test_detecta_subestimativa_de_duracao(self):
        base = self._base_local().replace(hour=14)
        for i in range(6):
            # Planejado 60 min, realizado 84 min → viés de +40%.
            self._sessao(base - timedelta(days=i + 1),
                         duracao_real=84, planejada_min=60, produtividade=3)

        insight = self._por_tipo('vies_estimativa')
        self.assertIsNotNone(insight)
        self.assertEqual(insight['numeros']['estimado_min'], 60)
        self.assertEqual(insight['numeros']['real_min'], 84)
        self.assertTrue(insight['id'].startswith('vies_estimativa:'))


class TarefasNoPrazoTests(InsightsTestBase):
    def test_calcula_taxa_de_tarefas_no_prazo(self):
        agora = timezone.now()
        # 4 no prazo, 2 atrasadas → 67%.
        for i in range(4):
            TarefaDisciplina.objects.create(
                disciplina=self.disciplina,
                titulo=f'No prazo {i}',
                prazo=agora - timedelta(days=i + 1),
                concluida=True,
                data_conclusao=agora - timedelta(days=i + 2),
            )
        for i in range(2):
            TarefaDisciplina.objects.create(
                disciplina=self.disciplina,
                titulo=f'Atrasada {i}',
                prazo=agora - timedelta(days=i + 3),
                concluida=True,
                data_conclusao=agora - timedelta(days=i + 1),
            )

        insight = self._por_tipo('tarefas_no_prazo')
        self.assertIsNotNone(insight)
        self.assertEqual(insight['numeros']['total_tarefas'], 6)
        self.assertEqual(insight['numeros']['concluidas'], 4)
        self.assertEqual(insight['numeros']['taxa_pct'], 67)


class TaxaFuroTests(InsightsTestBase):
    def test_detecta_horario_com_muitos_cancelamentos(self):
        # Sexta à noite: junta sessões no mesmo dia da semana e período.
        hoje = self._base_local()
        sexta = hoje - timedelta(days=(hoje.weekday() - 4) % 7 or 7)
        sexta = sexta.replace(hour=20)
        # 3 sextas, 2 sessões cada (20h e 22h) = 6 sessões, 4 canceladas.
        canceladas = 0
        for semana in range(3):
            for hora in (20, 22):
                dia = sexta.replace(hour=hora) - timedelta(days=7 * semana)
                if canceladas < 4:
                    self._sessao(dia, status=SessaoEstudo.StatusSessao.CANCELADO,
                                 produtividade=None)
                    canceladas += 1
                else:
                    self._sessao(dia, produtividade=4)

        insight = self._por_tipo('taxa_furo')
        self.assertIsNotNone(insight)
        self.assertEqual(insight['severidade'], 'critico')
        self.assertGreaterEqual(insight['numeros']['taxa_pct'], 50)


class EquilibrioMetodoTests(InsightsTestBase):
    def test_detecta_excesso_de_leitura(self):
        base = self._base_local().replace(hour=10)
        for i in range(6):
            self._sessao(base - timedelta(days=2 * i + 1),
                         duracao_real=60, tipo='LEITURA', produtividade=3)
        self._sessao(base - timedelta(days=13),
                     duracao_real=30, tipo='EXERCICIO', produtividade=3)

        insight = self._por_tipo('equilibrio_metodo')
        self.assertIsNotNone(insight)
        self.assertGreaterEqual(insight['numeros']['leitura_pct'], 70)
        self.assertEqual(insight['severidade'], 'atencao')


class GateAmostraTests(InsightsTestBase):
    def test_poucas_sessoes_retorna_amostra_insuficiente(self):
        base = self._base_local().replace(hour=9)
        for i in range(3):
            self._sessao(base - timedelta(days=i + 1), produtividade=4)

        insights = InsightsService().obter_insights(self.aluno.id)
        tipos = {ins['tipo'] for ins in insights}
        self.assertEqual(tipos, {'amostra_insuficiente'})
        self.assertEqual(insights[0]['confianca'], 'insuficiente')


class FeedbackTests(InsightsTestBase):
    def _semear_melhor_horario(self):
        base = self._base_local()
        for i in range(6):
            self._sessao(base.replace(hour=8) - timedelta(days=2 * i + 1), produtividade=5)
        for i in range(6):
            self._sessao(base.replace(hour=21) - timedelta(days=2 * i + 2), produtividade=2)

    def test_feedback_negativo_oculta_insight(self):
        self._semear_melhor_horario()
        self.assertIn('melhor_horario', self._tipos())

        resp = self.client.post(
            '/api/insights/melhor_horario/feedback/',
            {'useful': False, 'reason': 'não faz sentido'},
            format='json',
        )
        self.assertEqual(resp.status_code, 200, resp.data)
        self.assertNotIn('melhor_horario', self._tipos())
        self.assertEqual(InsightFeedback.objects.count(), 1)

    def test_feedback_positivo_mantem_e_prioriza(self):
        self._semear_melhor_horario()
        resp = self.client.post(
            '/api/insights/melhor_horario/feedback/',
            {'util': True},
            format='json',
        )
        self.assertEqual(resp.status_code, 200, resp.data)
        insights = InsightsService().obter_insights(self.aluno.id)
        self.assertEqual(insights[0]['tipo'], 'melhor_horario')

    def test_reenvio_atualiza_feedback_existente(self):
        self._semear_melhor_horario()
        self.client.post('/api/insights/melhor_horario/feedback/',
                         {'util': True}, format='json')
        self.client.post('/api/insights/melhor_horario/feedback/',
                         {'util': False}, format='json')
        self.assertEqual(InsightFeedback.objects.count(), 1)
        self.assertFalse(InsightFeedback.objects.first().util)


class EndpointsTests(InsightsTestBase):
    def test_get_insights_exige_autenticacao(self):
        self.client.force_authenticate(user=None)
        resp = self.client.get('/api/insights/')
        self.assertEqual(resp.status_code, 401)

    def test_get_insights_retorna_lista(self):
        base = self._base_local()
        for i in range(6):
            self._sessao(base.replace(hour=8) - timedelta(days=2 * i + 1), produtividade=5)
        for i in range(6):
            self._sessao(base.replace(hour=21) - timedelta(days=2 * i + 2), produtividade=2)

        resp = self.client.get('/api/insights/')
        self.assertEqual(resp.status_code, 200)
        self.assertIsInstance(resp.data, list)
        self.assertTrue(any(i['tipo'] == 'melhor_horario' for i in resp.data))

    def test_get_evolucao_retorna_dashboard(self):
        base = self._base_local()
        for i in range(6):
            self._sessao(base.replace(hour=8) - timedelta(days=2 * i + 1), produtividade=5)
        for i in range(6):
            self._sessao(base.replace(hour=21) - timedelta(days=2 * i + 2), produtividade=2)

        resp = self.client.get('/api/insights/evolucao/')
        self.assertEqual(resp.status_code, 200)
        self.assertIn('dimensoes', resp.data)
        self.assertIn('periodo', resp.data)

    def test_insights_isolados_por_aluno(self):
        base = self._base_local()
        for i in range(6):
            self._sessao(base.replace(hour=8) - timedelta(days=2 * i + 1), produtividade=5)
        for i in range(6):
            self._sessao(base.replace(hour=21) - timedelta(days=2 * i + 2), produtividade=2)

        outro = Aluno.objects.create_user(
            email='outro-insights@teste.com', nome='Outro', password='senha123',
        )
        self.client.force_authenticate(outro)
        resp = self.client.get('/api/insights/')
        tipos = {i['tipo'] for i in resp.data}
        self.assertEqual(tipos, {'amostra_insuficiente'})


class StatisticsTests(APITestCase):
    def test_spearman_monotonica(self):
        from insights import statistics as stats
        # Relação perfeitamente crescente → Spearman = 1.
        self.assertAlmostEqual(stats.spearman([1, 2, 3, 4], [10, 20, 30, 40]), 1.0)

    def test_regressao_quadratica_recupera_coeficientes(self):
        from insights import statistics as stats
        # y = -1x² + 4x + 1
        xs = [0, 1, 2, 3, 4]
        ys = [-1 * x ** 2 + 4 * x + 1 for x in xs]
        a, b, c = stats.regressao_quadratica(xs, ys)
        self.assertAlmostEqual(a, -1, places=4)
        self.assertAlmostEqual(b, 4, places=4)
        self.assertAlmostEqual(c, 1, places=4)
