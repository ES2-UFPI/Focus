from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import InsightFeedback
from .serializers import InsightFeedbackInputSerializer, InsightFeedbackSerializer
from .services import InsightsService


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def listar_insights(request):
    """GET /api/insights/ — insights calculados do aluno autenticado."""
    insights = InsightsService().obter_insights(request.user.id)
    return Response(insights)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def evolucao(request):
    """GET /api/insights/evolucao/ — panorama/comparações da aba Evolução."""
    dashboard = InsightsService().obter_evolucao(request.user.id)
    return Response(dashboard)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def registrar_feedback(request, insight_id):
    """POST /api/insights/{id}/feedback — persiste o 👍/👎 do aluno."""
    serializer = InsightFeedbackInputSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    # O tipo base é o id sem o sufixo de disciplina (ex.: "ritmo_disciplina:<id>").
    tipo = insight_id.split(':', 1)[0]

    feedback, _criado = InsightFeedback.objects.update_or_create(
        aluno=request.user,
        insight_id=insight_id,
        defaults={
            'tipo': tipo,
            'util': serializer.validated_data['util'],
            'motivo': serializer.validated_data['motivo'],
        },
    )
    return Response(
        InsightFeedbackSerializer(feedback).data,
        status=status.HTTP_200_OK,
    )
