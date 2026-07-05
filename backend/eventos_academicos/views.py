import datetime
from collections import defaultdict
from django.utils import timezone
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import EventoAcademico
from .serializers import EventoAcademicoSerializer
from sessao_estudo.models import SessaoEstudo


class EventoAcademicoViewSet(viewsets.ModelViewSet):
    serializer_class = EventoAcademicoSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return EventoAcademico.objects.filter(
            disciplina__aluno=self.request.user
        ).select_related('disciplina')

    @action(detail=False, methods=['get'], url_path='proximos')
    def proximos(self, request):
        today = timezone.localdate()
        seven_days_later = today + datetime.timedelta(days=7)
        queryset = self.get_queryset().filter(
            data_evento__range=(today, seven_days_later)
        ).order_by('data_evento')
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)


class AgendaView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        today = timezone.localdate()

        eventos = list(EventoAcademico.objects.filter(
            disciplina__aluno=request.user
        ).select_related('disciplina'))
        sessoes = list(SessaoEstudo.objects.filter(
            disciplina__aluno=request.user
        ).select_related('disciplina'))

        # Mapeamento de sessões por disciplina_id para processamento em memória
        sessoes_por_disciplina = defaultdict(list)
        for se in sessoes:
            sessoes_por_disciplina[se.disciplina_id].append(se)

        # Montagem dos itens no formato flat unificado para consumo facilitado no Flutter
        itens = []
        for ev in eventos:
            # Criar um timestamp consistente para ordenação (evento inicia no horário definido ou à meia-noite)
            if ev.hora_inicio:
                dt = datetime.datetime.combine(ev.data_evento, ev.hora_inicio)
            else:
                dt = datetime.datetime.combine(ev.data_evento, datetime.time.min)
            timestamp = timezone.make_aware(dt, timezone.get_current_timezone())

            itens.append({
                'tipo': 'EVENTO_ACADEMICO',
                'id': str(ev.id),
                'titulo': ev.titulo,
                'data': ev.data_evento.strftime('%Y-%m-%d'),
                'timestamp': timestamp.isoformat(),
                'descricao': ev.descricao,
                'disciplina_id': str(ev.disciplina_id) if ev.disciplina_id else None,
                'disciplina_nome': ev.disciplina.nome if ev.disciplina else '',
                'tipo_evento': ev.tipo,
                'urgencia': ev.urgencia,
                'dias_restantes': ev.dias_restantes,
                'concluido': ev.concluido,
                'hora_inicio': ev.hora_inicio.strftime('%H:%M') if ev.hora_inicio else None,
                'hora_fim': ev.hora_fim.strftime('%H:%M') if ev.hora_fim else None,
            })

        for se in sessoes:
            local_date = timezone.localtime(se.inicio).date()
            itens.append({
                'tipo': 'SESSAO_ESTUDO',
                'id': str(se.id),
                'titulo': f"Sessão de Estudo - {se.disciplina.nome}" if se.disciplina else "Sessão de Estudo",
                'data': local_date.strftime('%Y-%m-%d'),
                'timestamp': se.inicio.isoformat(),
                'descricao': se.descricao,
                'disciplina_id': str(se.disciplina_id) if se.disciplina_id else None,
                'disciplina_nome': se.disciplina.nome if se.disciplina else '',
                'inicio': se.inicio.isoformat(),
                'fim': se.fim.isoformat(),
                'status': se.status,
                'duracao_realizada': se.duracao_realizada,
                'energia_inicial': se.energia_inicial,
                'interrupcoes': se.interrupcoes,
                'tipo_atividade': se.tipo_atividade,
            })

        # Ordenar os itens cronologicamente usando o timestamp consistente (data e hora completas)
        itens.sort(key=lambda x: x['timestamp'])

        # Lógica de Recomendações (apenas para eventos futuros com recomendação útil)
        recomendacoes = []
        for ev in eventos:
            if ev.dias_restantes >= 0 and ev.tipo in ['PROVA', 'TRABALHO', 'SEMINARIO', 'APRESENTACAO']:
                sessoes_disc = sessoes_por_disciplina[ev.disciplina_id]
                # Filtra apenas sessões futuras do mesmo aluno/disciplina vinculadas à data do evento
                sessoes_futuras = [
                    s for s in sessoes_disc
                    if today <= timezone.localtime(s.inicio).date() <= ev.data_evento
                ]
                sessoes_count = len(sessoes_futuras)
                dias = ev.dias_restantes

                # Mapeamento de termos por tipo de evento
                nomes_tipo = {
                    'PROVA': ('avaliação próxima', 'antes da avaliação'),
                    'TRABALHO': ('entrega próxima', 'antes da entrega'),
                    'SEMINARIO': ('seminário próximo', 'antes do seminário'),
                    'APRESENTACAO': ('apresentação próxima', 'antes da apresentação'),
                }
                termo_prox, termo_antes = nomes_tipo[ev.tipo]

                # Apenas gerar recomendações se houver ação relevante recomendada
                if dias <= 3 and sessoes_count == 0:
                    rec = f"Você possui uma {termo_prox} e nenhuma sessão de estudo registrada."
                elif dias <= 7 and sessoes_count <= 1:
                    rec = f"Considere agendar mais sessões de estudo {termo_antes}."
                else:
                    rec = None

                if rec is not None:
                    recomendacoes.append({
                        'evento_id': str(ev.id),
                        'evento_titulo': ev.titulo,
                        'recomendacao': rec
                    })

        return Response({
            'itens': itens,
            'recomendacoes': recomendacoes
        })

