import datetime
from django.utils import timezone
from django.core.exceptions import ValidationError
from rest_framework import status
from rest_framework.test import APITestCase
from alunos.models import Aluno
from disciplinas.models import Disciplina
from eventos_academicos.models import EventoAcademico
from sessao_estudo.models import SessaoEstudo


class EventoAcademicoModelTests(APITestCase):

    def setUp(self):
        # Criar dados base
        self.aluno = Aluno.objects.create(
            nome="Caio",
            email="caio@teste.com",
            username="caio@teste.com"
        )
        self.disciplina = Disciplina.objects.create(
            nome="Cálculo I",
            aluno=self.aluno
        )

    def test_dias_restantes_e_urgencia(self):
        today = timezone.localdate()

        # Evento em 2 dias (Urgência: ALTA)
        ev_alta = EventoAcademico.objects.create(
            disciplina=self.disciplina,
            titulo="Prova 1",
            tipo="PROVA",
            data_evento=today + datetime.timedelta(days=2)
        )
        self.assertEqual(ev_alta.dias_restantes, 2)
        self.assertEqual(ev_alta.urgencia, "ALTA")

        # Evento em 5 dias (Urgência: MEDIA)
        ev_media = EventoAcademico.objects.create(
            disciplina=self.disciplina,
            titulo="Trabalho 1",
            tipo="TRABALHO",
            data_evento=today + datetime.timedelta(days=5)
        )
        self.assertEqual(ev_media.dias_restantes, 5)
        self.assertEqual(ev_media.urgencia, "MEDIA")

        # Evento em 10 dias (Urgência: BAIXA)
        ev_baixa = EventoAcademico.objects.create(
            disciplina=self.disciplina,
            titulo="Seminário 1",
            tipo="SEMINARIO",
            data_evento=today + datetime.timedelta(days=10)
        )
        self.assertEqual(ev_baixa.dias_restantes, 10)
        self.assertEqual(ev_baixa.urgencia, "BAIXA")

        # Evento no passado (Urgência: ATRASADO)
        ev_atrasado = EventoAcademico.objects.create(
            disciplina=self.disciplina,
            titulo="Prova antiga",
            tipo="PROVA",
            data_evento=today - datetime.timedelta(days=1)
        )
        self.assertEqual(ev_atrasado.dias_restantes, -1)
        self.assertEqual(ev_atrasado.urgencia, "ATRASADO")

    def test_evitar_eventos_duplicados(self):
        today = timezone.localdate()
        date_ev = today + datetime.timedelta(days=4)

        # Criar evento original
        ev1 = EventoAcademico.objects.create(
            disciplina=self.disciplina,
            titulo="Prova 1",
            tipo="PROVA",
            data_evento=date_ev
        )

        # Tentar criar outro idêntico para a mesma disciplina/data
        ev2 = EventoAcademico(
            disciplina=self.disciplina,
            titulo="Prova 1",
            tipo="PROVA",
            data_evento=date_ev
        )

        with self.assertRaises(ValidationError):
            ev2.clean()


class SessaoEstudoModelTests(APITestCase):

    def setUp(self):
        self.aluno = Aluno.objects.create(
            nome="Caio",
            email="caio@teste.com",
            username="caio@teste.com"
        )
        self.disciplina1 = Disciplina.objects.create(
            nome="Cálculo I",
            aluno=self.aluno
        )
        self.disciplina2 = Disciplina.objects.create(
            nome="Física I",
            aluno=self.aluno
        )

    def test_periodo_invalido(self):
        now = timezone.now()
        # Fim antes de início
        se = SessaoEstudo(
            disciplina=self.disciplina1,
            inicio=now,
            fim=now - datetime.timedelta(hours=1)
        )
        with self.assertRaises(ValidationError):
            se.clean()

    def test_sessoes_duplicadas(self):
        now = timezone.now()
        inicio = now + datetime.timedelta(days=1)
        fim = inicio + datetime.timedelta(hours=2)

        # Criar sessão original
        se1 = SessaoEstudo.objects.create(
            disciplina=self.disciplina1,
            inicio=inicio,
            fim=fim
        )

        # Tentar criar outra idêntica
        se2 = SessaoEstudo(
            disciplina=self.disciplina1,
            inicio=inicio,
            fim=fim
        )
        with self.assertRaises(ValidationError):
            se2.clean()

    def test_sessoes_sobrepostas_mesmo_aluno(self):
        now = timezone.now()
        
        # Sessão 1: das 14h às 16h na Disciplina 1
        inicio1 = now.replace(hour=14, minute=0, second=0, microsecond=0)
        fim1 = now.replace(hour=16, minute=0, second=0, microsecond=0)
        se1 = SessaoEstudo.objects.create(
            disciplina=self.disciplina1,
            inicio=inicio1,
            fim=fim1
        )

        # Sessão 2: das 15h às 17h na Disciplina 2 (Sobreposta)
        inicio2 = now.replace(hour=15, minute=0, second=0, microsecond=0)
        fim2 = now.replace(hour=17, minute=0, second=0, microsecond=0)
        se2 = SessaoEstudo(
            disciplina=self.disciplina2,
            inicio=inicio2,
            fim=fim2
        )
        with self.assertRaises(ValidationError):
            se2.clean()


class EndpointsAPITests(APITestCase):

    def setUp(self):
        self.aluno = Aluno.objects.create(
            nome="Caio",
            email="caio@teste.com",
            username="caio@teste.com"
        )
        self.disciplina = Disciplina.objects.create(
            nome="Cálculo I",
            aluno=self.aluno
        )
        self.today = timezone.localdate()

    def test_endpoint_eventos_proximos(self):
        # Evento em 3 dias (Deve aparecer)
        ev1 = EventoAcademico.objects.create(
            disciplina=self.disciplina,
            titulo="Prova Próxima",
            tipo="PROVA",
            data_evento=self.today + datetime.timedelta(days=3)
        )
        # Evento em 10 dias (Não deve aparecer, passa do limite de 7 dias)
        ev2 = EventoAcademico.objects.create(
            disciplina=self.disciplina,
            titulo="Prova Longe",
            tipo="PROVA",
            data_evento=self.today + datetime.timedelta(days=10)
        )
        # Evento no passado (Não deve aparecer)
        ev3 = EventoAcademico.objects.create(
            disciplina=self.disciplina,
            titulo="Prova Passada",
            tipo="PROVA",
            data_evento=self.today - datetime.timedelta(days=1)
        )

        response = self.client.get('/api/eventos-academicos/proximos/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Apenas ev1 (Prova Próxima) deve constar
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['id'], str(ev1.id))
        self.assertEqual(response.data[0]['dias_restantes'], 3)
        self.assertEqual(response.data[0]['urgencia'], "ALTA")

    def test_endpoint_agenda_e_recomendacoes(self):
        # Cenário 1: Prova em 2 dias sem sessões -> Recomendação Crítica
        ev1 = EventoAcademico.objects.create(
            disciplina=self.disciplina,
            titulo="Prova de Cálculo",
            tipo="PROVA",
            data_evento=self.today + datetime.timedelta(days=2)
        )

        # Cenário 2: Prova em 5 dias com 1 sessão -> Recomendação Moderada
        disciplina_fisica = Disciplina.objects.create(
            nome="Física I",
            aluno=self.aluno
        )
        ev2 = EventoAcademico.objects.create(
            disciplina=disciplina_fisica,
            titulo="Prova de Física",
            tipo="PROVA",
            data_evento=self.today + datetime.timedelta(days=5)
        )
        
        # Registrar 1 sessão futura de Física no dia anterior à prova
        now = timezone.now()
        SessaoEstudo.objects.create(
            disciplina=disciplina_fisica,
            inicio=now + datetime.timedelta(days=4),
            fim=now + datetime.timedelta(days=4, hours=2)
        )

        response = self.client.get('/api/agenda/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verificar chaves retornadas
        self.assertIn('itens', response.data)
        self.assertIn('recomendacoes', response.data)

        # Verificar se os itens foram ordenados cronologicamente
        itens = response.data['itens']
        self.assertTrue(len(itens) >= 3) # ev1, ev2 e a sessao
        
        # Verificar o formato flat do item de evento
        ev1_flat = next(item for item in itens if item['id'] == str(ev1.id))
        self.assertEqual(ev1_flat['tipo'], 'EVENTO_ACADEMICO')
        self.assertEqual(ev1_flat['titulo'], 'Prova de Cálculo')
        self.assertEqual(ev1_flat['urgencia'], 'ALTA')
        self.assertEqual(ev1_flat['dias_restantes'], 2)

        # Verificar as recomendações mapeadas
        recs = response.data['recomendacoes']
        rec_calculo = next(r for r in recs if r['evento_id'] == str(ev1.id))
        self.assertEqual(
            rec_calculo['recomendacao'],
            "Você possui uma avaliação próxima e nenhuma sessão de estudo registrada."
        )

        rec_fisica = next(r for r in recs if r['evento_id'] == str(ev2.id))
        self.assertEqual(
            rec_fisica['recomendacao'],
            "Considere agendar mais sessões de estudo antes da avaliação."
        )

    def test_agenda_vazia(self):
        # Limpar registros criados no setUp para garantir agenda vazia
        EventoAcademico.objects.all().delete()
        SessaoEstudo.objects.all().delete()

        response = self.client.get('/api/agenda/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['itens'], [])
        self.assertEqual(response.data['recomendacoes'], [])

    def test_agenda_ordenacao_e_mistura(self):
        # Limpar dados para controle total do cenário
        EventoAcademico.objects.all().delete()
        SessaoEstudo.objects.all().delete()

        dia_d = self.today + datetime.timedelta(days=3)

        # 1. Evento no dia D (Meia-noite do dia D)
        ev1 = EventoAcademico.objects.create(
            disciplina=self.disciplina,
            titulo="Prova Dia D",
            tipo="PROVA",
            data_evento=dia_d
        )

        # 2. Sessão de Estudo no dia D às 14:00
        inicio_se1 = timezone.make_aware(
            datetime.datetime.combine(dia_d, datetime.time(14, 0)),
            timezone.get_current_timezone()
        )
        se1 = SessaoEstudo.objects.create(
            disciplina=self.disciplina,
            inicio=inicio_se1,
            fim=inicio_se1 + datetime.timedelta(hours=2)
        )

        # 3. Sessão de Estudo no dia D às 10:00 (Mais cedo que a se1)
        inicio_se2 = timezone.make_aware(
            datetime.datetime.combine(dia_d, datetime.time(10, 0)),
            timezone.get_current_timezone()
        )
        se2 = SessaoEstudo.objects.create(
            disciplina=self.disciplina,
            inicio=inicio_se2,
            fim=inicio_se2 + datetime.timedelta(hours=2)
        )

        # 4. Evento no dia D - 1 (Dia anterior)
        ev2 = EventoAcademico.objects.create(
            disciplina=self.disciplina,
            titulo="Prova Dia Anterior",
            tipo="PROVA",
            data_evento=dia_d - datetime.timedelta(days=1)
        )

        response = self.client.get('/api/agenda/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        itens = response.data['itens']
        self.assertEqual(len(itens), 4)

        # A ordenação esperada (mais antiga primeiro):
        # 1. ev2 (Dia D-1, meia-noite)
        # 2. ev1 (Dia D, meia-noite)
        # 3. se2 (Dia D às 10h)
        # 4. se1 (Dia D às 14h)
        self.assertEqual(itens[0]['id'], str(ev2.id))
        self.assertEqual(itens[1]['id'], str(ev1.id))
        self.assertEqual(itens[2]['id'], str(se2.id))
        self.assertEqual(itens[3]['id'], str(se1.id))