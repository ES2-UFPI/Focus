from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.http import Http404
from django.shortcuts import get_object_or_404
from rest_framework.permissions import AllowAny, IsAuthenticated # Garanta o import do AllowAny
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import SessaoEstudo
from .serializers import SessaoEstudoSerializer
from disciplinas.models import Disciplina
from services.consistencia_service import ConsistenciaService

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
    
    def perform_create(self, serializer):
      
        disciplina = serializer.validated_data.get('disciplina')
        

        if disciplina.aluno_id != self.aluno_id:
            from rest_framework.exceptions import ValidationError
            raise ValidationError(
                {"disciplina": "Você não tem permissão para criar uma sessão nesta disciplina."}
            )
      
        serializer.save()

    @action(detail=False, methods=['get'], permission_classes=[AllowAny])
    def dashboard(self, request):
        # 🛡️ Uma verificação simples de segurança caso queira debugar no terminal
        if request.user.is_authenticated:
            print(f"🚀 [Dashboard] Processando dados para: {request.user.email}")
        else:
            print("⚠️ [Dashboard] Requisição anônima recebida!")

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
        # Garante que a disciplina existe e pertence ao aluno logado antes de processar
        
        try:
            get_object_or_404(Disciplina, id=disciplina_id, aluno_id=self.aluno_id)
            
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