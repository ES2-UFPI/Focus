from datetime import timedelta

from django.utils import timezone
from rest_framework.test import APITestCase

from alunos.models import Aluno
from disciplinas.models import Disciplina
from sessao_estudo.models import BlocoPomodoro, SessaoEstudo


class BlocoPomodoroAPITests(APITestCase):
    def setUp(self):
        self.aluno = Aluno.objects.create_user(
            email='pomodoro@teste.com',
            nome='Aluno Pomodoro',
            password='senha123',
        )
        self.disciplina = Disciplina.objects.create(
            aluno=self.aluno,
            nome='Cálculo',
            cor='#6366F1',
            meta_horas_semanais=4,
        )
        inicio_sessao = timezone.now()
        self.sessao = SessaoEstudo.objects.create(
            disciplina=self.disciplina,
            inicio=inicio_sessao,
            fim=inicio_sessao + timedelta(hours=2),
        )
        self.client.force_authenticate(self.aluno)

    def _payload(self, **overrides):
        inicio = timezone.now()
        payload = {
            'sessao_estudo': str(self.sessao.id),
            'numero_ciclo': 1,
            'inicio': inicio.isoformat(),
            'fim': (inicio + timedelta(minutes=25)).isoformat(),
            'duracao_planejada_segundos': 1500,
            'duracao_realizada_segundos': 1500,
            'interrupcoes': 1,
            'status': BlocoPomodoro.StatusBloco.CONCLUIDO,
            'produtividade': None,
        }
        payload.update(overrides)
        return payload

    def test_cria_bloco_concluido_e_avalia_depois(self):
        response = self.client.post(
            '/api/blocos-pomodoro/',
            self._payload(),
            format='json',
        )

        self.assertEqual(response.status_code, 201, response.data)
        bloco_id = response.data['id']
        self.assertIsNone(response.data['produtividade'])

        response = self.client.patch(
            f'/api/blocos-pomodoro/{bloco_id}/',
            {'produtividade': 5},
            format='json',
        )

        self.assertEqual(response.status_code, 200, response.data)
        bloco = BlocoPomodoro.objects.get(id=bloco_id)
        self.assertEqual(bloco.produtividade, 5)
        self.assertEqual(bloco.interrupcoes, 1)

    def test_bloco_incompleto_fica_sem_avaliacao(self):
        response = self.client.post(
            '/api/blocos-pomodoro/',
            self._payload(
                status=BlocoPomodoro.StatusBloco.INCOMPLETO,
                duracao_realizada_segundos=320,
            ),
            format='json',
        )

        self.assertEqual(response.status_code, 201, response.data)
        self.assertIsNone(response.data['produtividade'])

    def test_rejeita_produtividade_em_bloco_incompleto(self):
        response = self.client.post(
            '/api/blocos-pomodoro/',
            self._payload(
                status=BlocoPomodoro.StatusBloco.INCOMPLETO,
                produtividade=4,
            ),
            format='json',
        )

        self.assertEqual(response.status_code, 400)
        self.assertIn('produtividade', response.data)

    def test_promove_bloco_pulado_quando_usuario_avalia(self):
        response = self.client.post(
            '/api/blocos-pomodoro/',
            self._payload(
                status=BlocoPomodoro.StatusBloco.INCOMPLETO,
                duracao_realizada_segundos=320,
            ),
            format='json',
        )
        bloco_id = response.data['id']

        response = self.client.patch(
            f'/api/blocos-pomodoro/{bloco_id}/',
            {
                'status': (
                    BlocoPomodoro.StatusBloco.ENCERRADO_ANTECIPADAMENTE
                ),
                'produtividade': 4,
            },
            format='json',
        )

        self.assertEqual(response.status_code, 200, response.data)
        bloco = BlocoPomodoro.objects.get(id=bloco_id)
        self.assertEqual(
            bloco.status,
            BlocoPomodoro.StatusBloco.ENCERRADO_ANTECIPADAMENTE,
        )
        self.assertEqual(bloco.produtividade, 4)

    def test_nao_permite_bloco_em_sessao_de_outro_aluno(self):
        outro = Aluno.objects.create_user(
            email='outro-pomodoro@teste.com',
            nome='Outro Aluno',
            password='senha123',
        )
        outra_disciplina = Disciplina.objects.create(
            aluno=outro,
            nome='Física',
            cor='#2196F3',
            meta_horas_semanais=3,
        )
        inicio = timezone.now() + timedelta(days=1)
        outra_sessao = SessaoEstudo.objects.create(
            disciplina=outra_disciplina,
            inicio=inicio,
            fim=inicio + timedelta(hours=1),
        )

        response = self.client.post(
            '/api/blocos-pomodoro/',
            self._payload(sessao_estudo=str(outra_sessao.id)),
            format='json',
        )

        self.assertEqual(response.status_code, 400)
        self.assertIn('sessao_estudo', response.data)
