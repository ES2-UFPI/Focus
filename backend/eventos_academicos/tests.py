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

    def test_horarios_evento_validation(self):
        # Caso 1: hora_inicio preenchida, hora_fim vazia (Permitido)
        ev1 = EventoAcademico(
            disciplina=self.disciplina,
            titulo="Prova Caso 1",
            tipo="PROVA",
            data_evento=self.today,
            hora_inicio=datetime.time(10, 0),
            hora_fim=None
        )
        try:
            ev1.clean()
        except ValidationError:
            self.fail("ValidationError raised unexpectedly for Case 1")

        # Caso 2: hora_inicio vazia, hora_fim preenchida (Bloqueado)
        ev2 = EventoAcademico(
            disciplina=self.disciplina,
            titulo="Prova Caso 2",
            tipo="PROVA",
            data_evento=self.today,
            hora_inicio=None,
            hora_fim=datetime.time(12, 0)
        )
        with self.assertRaises(ValidationError):
            ev2.clean()

        # Caso 3: hora_inicio > hora_fim (Bloqueado)
        ev3 = EventoAcademico(
            disciplina=self.disciplina,
            titulo="Prova Caso 3",
            tipo="PROVA",
            data_evento=self.today,
            hora_inicio=datetime.time(14, 0),
            hora_fim=datetime.time(10, 0)
        )
        with self.assertRaises(ValidationError):
            ev3.clean()

        # Caso 4: hora_inicio == hora_fim (Bloqueado)
        ev4 = EventoAcademico(
            disciplina=self.disciplina,
            titulo="Prova Caso 4",
            tipo="PROVA",
            data_evento=self.today,
            hora_inicio=datetime.time(10, 0),
            hora_fim=datetime.time(10, 0)
        )
        with self.assertRaises(ValidationError):
            ev4.clean()

        # Caso 5: Evento sem horário (Permitido)
        ev5 = EventoAcademico(
            disciplina=self.disciplina,
            titulo="Prova Caso 5",
            tipo="PROVA",
            data_evento=self.today,
            hora_inicio=None,
            hora_fim=None
        )
        try:
            ev5.clean()
        except ValidationError:
            self.fail("ValidationError raised unexpectedly for Case 5")

    def test_recomendacoes_especificas_por_tipo(self):
        # Limpar existentes
        EventoAcademico.objects.all().delete()
        SessaoEstudo.objects.all().delete()

        # OUTRO - Sem recomendação
        EventoAcademico.objects.create(
            disciplina=self.disciplina,
            titulo="Outro Evento",
            tipo="OUTRO",
            data_evento=self.today + datetime.timedelta(days=2)
        )

        # PROVA - Recomendação de avaliação
        ev_prova = EventoAcademico.objects.create(
            disciplina=self.disciplina,
            titulo="Prova Próxima",
            tipo="PROVA",
            data_evento=self.today + datetime.timedelta(days=2)
        )

        # TRABALHO - Recomendação de entrega
        ev_trabalho = EventoAcademico.objects.create(
            disciplina=self.disciplina,
            titulo="Trabalho Próximo",
            tipo="TRABALHO",
            data_evento=self.today + datetime.timedelta(days=2)
        )

        # SEMINARIO - Recomendação de seminário
        ev_seminario = EventoAcademico.objects.create(
            disciplina=self.disciplina,
            titulo="Seminário Próximo",
            tipo="SEMINARIO",
            data_evento=self.today + datetime.timedelta(days=2)
        )

        # APRESENTACAO - Recomendação de apresentação
        ev_apresentacao = EventoAcademico.objects.create(
            disciplina=self.disciplina,
            titulo="Apresentação Próxima",
            tipo="APRESENTACAO",
            data_evento=self.today + datetime.timedelta(days=2)
        )

        response = self.client.get('/api/agenda/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        recs = response.data['recomendacoes']

        # Verificar quantidade (4 recomendações - OUTRO deve ser ignorado)
        self.assertEqual(len(recs), 4)

        # Prova
        rec_prova = next(r for r in recs if r['evento_id'] == str(ev_prova.id))
        self.assertIn("avaliação próxima", rec_prova['recomendacao'])

        # Trabalho
        rec_trabalho = next(r for r in recs if r['evento_id'] == str(ev_trabalho.id))
        self.assertIn("entrega próxima", rec_trabalho['recomendacao'])

        # Seminário
        rec_seminario = next(r for r in recs if r['evento_id'] == str(ev_seminario.id))
        self.assertIn("seminário próximo", rec_seminario['recomendacao'])

        # Apresentação
        rec_apres = next(r for r in recs if r['evento_id'] == str(ev_apresentacao.id))
        self.assertIn("apresentação próxima", rec_apres['recomendacao'])

    def test_agenda_view_estrutura_e_ordenacao(self):
        # Limpar existentes
        EventoAcademico.objects.all().delete()
        SessaoEstudo.objects.all().delete()

        # Cenário:
        # Evento sem horário (Dia D, MEIA-NOITE)
        # Evento 08:00 (Dia D)
        # Sessão 10:00 (Dia D)
        # Evento 14:00 (Dia D)
        # Sessão 16:00 (Dia D)
        dia_d = self.today + datetime.timedelta(days=2)

        ev_sem_hora = EventoAcademico.objects.create(
            disciplina=self.disciplina,
            titulo="Evento Sem Hora",
            tipo="PROVA",
            data_evento=dia_d,
            hora_inicio=None
        )

        ev_08 = EventoAcademico.objects.create(
            disciplina=self.disciplina,
            titulo="Evento 08:00",
            tipo="PROVA",
            data_evento=dia_d,
            hora_inicio=datetime.time(8, 0)
        )

        inicio_se_10 = timezone.make_aware(
            datetime.datetime.combine(dia_d, datetime.time(10, 0)),
            timezone.get_current_timezone()
        )
        se_10 = SessaoEstudo.objects.create(
            disciplina=self.disciplina,
            inicio=inicio_se_10,
            fim=inicio_se_10 + datetime.timedelta(hours=1)
        )

        ev_14 = EventoAcademico.objects.create(
            disciplina=self.disciplina,
            titulo="Evento 14:00",
            tipo="PROVA",
            data_evento=dia_d,
            hora_inicio=datetime.time(14, 0)
        )

        inicio_se_16 = timezone.make_aware(
            datetime.datetime.combine(dia_d, datetime.time(16, 0)),
            timezone.get_current_timezone()
        )
        se_16 = SessaoEstudo.objects.create(
            disciplina=self.disciplina,
            inicio=inicio_se_16,
            fim=inicio_se_16 + datetime.timedelta(hours=1)
        )

        response = self.client.get('/api/agenda/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        itens = response.data['itens']
        self.assertEqual(len(itens), 5)

        # Ordem cronológica esperada:
        # 1. Evento Sem Hora (meia-noite)
        # 2. Evento 08:00
        # 3. Sessão 10:00
        # 4. Evento 14:00
        # 5. Sessão 16:00
        self.assertEqual(itens[0]['id'], str(ev_sem_hora.id))
        self.assertEqual(itens[1]['id'], str(ev_08.id))
        self.assertEqual(itens[2]['id'], str(se_10.id))
        self.assertEqual(itens[3]['id'], str(ev_14.id))
        self.assertEqual(itens[4]['id'], str(se_16.id))

        # Verificar presença dos campos novos no JSON do Evento
        ev_flat = next(item for item in itens if item['id'] == str(ev_08.id))
        self.assertEqual(ev_flat['disciplina_id'], str(self.disciplina.id))
        self.assertEqual(ev_flat['hora_inicio'], '08:00')
        self.assertIn('hora_fim', ev_flat)

        # Verificar presença do campo disciplina_id no JSON da Sessão
        se_flat = next(item for item in itens if item['id'] == str(se_10.id))
        self.assertEqual(se_flat['disciplina_id'], str(self.disciplina.id))

    def test_exclusao_remove_da_agenda(self):
        # Criar Evento e Sessão
        ev = EventoAcademico.objects.create(
            disciplina=self.disciplina,
            titulo="Evento para Excluir",
            tipo="PROVA",
            data_evento=self.today
        )
        now = timezone.now()
        se = SessaoEstudo.objects.create(
            disciplina=self.disciplina,
            inicio=now,
            fim=now + datetime.timedelta(hours=1)
        )

        # Verificar presença na Agenda
        response = self.client.get('/api/agenda/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['itens']), 2)

        # Excluir ambos
        res_ev = self.client.delete(f'/api/eventos-academicos/{ev.id}/')
        self.assertEqual(res_ev.status_code, status.HTTP_204_NO_CONTENT)
        res_se = self.client.delete(f'/api/sessoes-estudo/{se.id}/')
        self.assertEqual(res_se.status_code, status.HTTP_204_NO_CONTENT)

        # Verificar que foram removidos da agenda
        response = self.client.get('/api/agenda/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['itens']), 0)

    def test_edicao_patch_preserva_dados_antigos(self):
        # Criar Evento com dados completos
        ev = EventoAcademico.objects.create(
            disciplina=self.disciplina,
            titulo="Título Antigo",
            tipo="PROVA",
            descricao="Descrição muito importante",
            data_evento=self.today,
            hora_inicio=datetime.time(10, 0),
            hora_fim=datetime.time(11, 30)
        )

        # Atualizar apenas o título via PATCH
        patch_data = {
            'titulo': "Título Novo"
        }
        res_patch = self.client.patch(f'/api/eventos-academicos/{ev.id}/', data=patch_data, format='json')
        self.assertEqual(res_patch.status_code, status.HTTP_200_OK)

        # Verificar que o título mudou, mas descrição, horários e disciplina continuam intactos
        ev.refresh_from_db()
        self.assertEqual(ev.titulo, "Título Novo")
        self.assertEqual(ev.descricao, "Descrição muito importante")
        self.assertEqual(ev.hora_inicio, datetime.time(10, 0))
        self.assertEqual(ev.hora_fim, datetime.time(11, 30))
        self.assertEqual(ev.disciplina_id, self.disciplina.id)
        self.assertEqual(ev.tipo, "PROVA")
        self.assertEqual(ev.data_evento, self.today)