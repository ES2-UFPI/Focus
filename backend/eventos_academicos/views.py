import datetime
from collections import defaultdict
from django.utils import timezone
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import EventoAcademico
from .serializers import EventoAcademicoSerializer
from sessao_estudo.models import SessaoEstudo


class EventoAcademicoViewSet(viewsets.ModelViewSet):
    queryset = EventoAcademico.objects.all().select_related('disciplina')
    serializer_class = EventoAcademicoSerializer

    @action(detail=False, methods=['get'], url_path='proximos')
    def proximos(self, request):
        # Filtrar eventos dos próximos 7 dias ordenados por data
        today = timezone.localdate()
        seven_days_later = today + datetime.timedelta(days=7)
        # Filtra apenas eventos cuja data está no intervalo [hoje, hoje + 7 dias]
        queryset = EventoAcademico.objects.filter(
            data_evento__range=(today, seven_days_later)
        ).select_related('disciplina').order_by('data_evento')
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)


class AgendaView(APIView):
    def get(self, request):
        today = timezone.localdate()

        # OTIMIZAÇÃO: 2 queries para carregar todo o conjunto necessário (sem N+1)
        eventos = list(EventoAcademico.objects.all().select_related('disciplina'))
        sessoes = list(SessaoEstudo.objects.all().select_related('disciplina'))

        # Mapeamento de sessões por disciplina_id para processamento em memória
        sessoes_por_disciplina = defaultdict(list)
        for se in sessoes:
            sessoes_por_disciplina[se.disciplina_id].append(se)

        # Montagem dos itens no formato flat unificado para consumo facilitado no Flutter
        itens = []
        for ev in eventos:
            # Criar um timestamp consistente para ordenação (evento inicia à meia-noite do respectivo dia)
            dt_min = datetime.datetime.combine(ev.data_evento, datetime.time.min)
            timestamp = timezone.make_aware(dt_min, timezone.get_current_timezone())
            
            itens.append({
                'tipo': 'EVENTO_ACADEMICO',
                'id': str(ev.id),
                'titulo': ev.titulo,
                'data': ev.data_evento.strftime('%Y-%m-%d'),
                'timestamp': timestamp.isoformat(),
                'descricao': ev.descricao,
                'disciplina_nome': ev.disciplina.nome if ev.disciplina else '',
                'tipo_evento': ev.tipo,
                'urgencia': ev.urgencia,
                'dias_restantes': ev.dias_restantes,
                'concluido': ev.concluido
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
                'disciplina_nome': se.disciplina.nome if se.disciplina else '',
                'inicio': se.inicio.isoformat(),
                'fim': se.fim.isoformat(),
                'status': se.status,
                'duracao_realizada': se.duracao_realizada
            })

        # Ordenar os itens cronologicamente usando o timestamp consistente (data e hora completas)
        itens.sort(key=lambda x: x['timestamp'])

        # Lógica de Recomendações (apenas para eventos futuros com recomendação útil)
        recomendacoes = []
        for ev in eventos:
            if ev.dias_restantes >= 0:
                sessoes_disc = sessoes_por_disciplina[ev.disciplina_id]
                # Filtra apenas sessões futuras do mesmo aluno/disciplina vinculadas à data do evento
                sessoes_futuras = [
                    s for s in sessoes_disc
                    if today <= timezone.localtime(s.inicio).date() <= ev.data_evento
                ]
                sessoes_count = len(sessoes_futuras)
                dias = ev.dias_restantes

                # Apenas gerar recomendações se houver ação relevante recomendada
                if dias <= 3 and sessoes_count == 0:
                    rec = "Você possui uma avaliação próxima e nenhuma sessão de estudo registrada."
                elif dias <= 7 and sessoes_count <= 1:
                    rec = "Considere agendar mais sessões de estudo antes da avaliação."
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