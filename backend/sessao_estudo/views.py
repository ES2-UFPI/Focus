from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.exceptions import ValidationError
from django.http import Http404
from django.shortcuts import get_object_or_404


from .models import BlocoPomodoro, SessaoEstudo, PlanejamentoDisciplina
from .serializers import BlocoPomodoroSerializer, SessaoEstudoSerializer, PlanejamentoDisciplinaSerializer
from disciplinas.models import Disciplina
from services.consistencia_service import ConsistenciaService
from services.semana_service import SemanaService
from services.planejamento_service import PlanejamentoService


class SessaoEstudoViewSet(viewsets.ModelViewSet):
    queryset = SessaoEstudo.objects.none()
    serializer_class = SessaoEstudoSerializer
    permission_classes = [IsAuthenticated]

    @property
    def consistencia(self):
        return ConsistenciaService()

    @property
    def aluno_id(self):
        return self.request.user.id

    def get_queryset(self):
        return SessaoEstudo.objects.filter(
            disciplina__aluno_id=self.aluno_id
        ).select_related(
            'disciplina',
            'semana_estudo',
            'horario_estudo'
        )

    def perform_create(self, serializer):
        disciplina = serializer.validated_data.get('disciplina')
        inicio = serializer.validated_data.get('inicio')

        if disciplina.aluno_id != self.aluno_id:
            raise ValidationError({
                "disciplina": "Você não tem permissão para criar uma sessão nesta disciplina."
            })

        semana = SemanaService().obter_ou_criar_semana_para_data(
            aluno_id=self.aluno_id,
            referencia=inicio
        )

        serializer.save(
            semana_estudo=semana
        )

    def perform_update(self, serializer):
        disciplina = serializer.validated_data.get(
            'disciplina',
            serializer.instance.disciplina
        )

        inicio = serializer.validated_data.get(
            'inicio',
            serializer.instance.inicio
        )

        if disciplina.aluno_id != self.aluno_id:
            raise ValidationError({
                "disciplina": "Você não tem permissão para editar uma sessão desta disciplina."
            })

        semana = SemanaService().obter_ou_criar_semana_para_data(
            aluno_id=self.aluno_id,
            referencia=inicio
        )

        serializer.save(
            semana_estudo=semana
        )

    @action(detail=False, methods=['get'])
    def semana_atual(self, request):
        sessoes = self.consistencia.obter_sessoes_semana(
            self.aluno_id
        )

        serializer = self.get_serializer(
            sessoes,
            many=True
        )

        return Response({
            'count': len(sessoes),
            'results': serializer.data
        })

    @action(detail=False, methods=['get'])
    def dashboard(self, request):
        # Retorna o cálculo do serviço usando o aluno_id correto
        return Response(
            self.consistencia.obter_dashboard_consistencia(self.aluno_id)
        )

    @action(detail=False, methods=['get'])
    def ranking(self, request):
        return Response(
            self.consistencia.obter_ranking_disciplinas(
                self.aluno_id
            )
        )

    @action(detail=False, methods=['get'])
    def disciplina_negligenciada(self, request):
        return Response(
            self.consistencia.obter_disciplina_mais_negligenciada(
                self.aluno_id
            )
        )

    @action(
        detail=False,
        methods=['get'],
        url_path=r'disciplina/(?P<disciplina_id>[^/.]+)/desempenho'
    )
    def desempenho_disciplina(self, request, disciplina_id):
        try:
            get_object_or_404(
                Disciplina,
                id=disciplina_id,
                aluno_id=self.aluno_id
            )

            return Response(
                self.consistencia.obter_desempenho_disciplina(
                    self.aluno_id,
                    disciplina_id
                )
            )

        except (Http404, ValueError):
            return Response(
                {
                    'detail': 'Disciplina não encontrada ou acesso negado.'
                },
                status=status.HTTP_404_NOT_FOUND
            )
            
class PlanejamentoDisciplinaViewSet(viewsets.ModelViewSet):
    serializer_class = PlanejamentoDisciplinaSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return PlanejamentoDisciplina.objects.filter(
            semana_estudo__aluno_id=self.request.user.id
        ).select_related(
            'semana_estudo',
            'disciplina'
        )
        
    def list(self, request, *args, **kwargs):
        dados = PlanejamentoService().obter_metas_semana_atual(
            request.user.id
        )

        return Response(dados)

    def perform_create(self, serializer):
        disciplina = serializer.validated_data.get('disciplina')

        if disciplina.aluno_id != self.request.user.id:
            raise ValidationError({
                'disciplina': 'Você não tem permissão para planejar esta disciplina.'
            })

        semana = SemanaService().obter_ou_criar_semana_atual(
            self.request.user.id
        )

        serializer.save(
            semana_estudo=semana
        )

    def perform_update(self, serializer):
        disciplina = serializer.validated_data.get(
            'disciplina',
            serializer.instance.disciplina
        )

        if disciplina.aluno_id != self.request.user.id:
            raise ValidationError({
                'disciplina': 'Você não tem permissão para editar esta meta.'
            })

        serializer.save()


class BlocoPomodoroViewSet(viewsets.ModelViewSet):
    queryset = BlocoPomodoro.objects.none()
    serializer_class = BlocoPomodoroSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return BlocoPomodoro.objects.filter(
            sessao_estudo__disciplina__aluno_id=self.request.user.id
        )
