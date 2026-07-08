from datetime import timedelta

from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import InsightFeedback
from .serializers import InsightFeedbackInputSerializer, InsightFeedbackSerializer
from .services import InsightsService

# Duração da punição por feedback negativo (👎): o insight some por 7 dias.
DIAS_PUNICAO = 7


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def listar_insights(request):
    """GET /api/insights/ — insights calculados do aluno autenticado."""
    insights = InsightsService().obter_insights(request.user.id)
    return Response(insights)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def evolucao(request):
    """GET /api/insights/evolucao/ — melhorias observadas da aba Evolução."""
    evolucao_data = InsightsService().obter_evolucao(request.user.id)
    return Response(evolucao_data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def registrar_feedback(request, insight_id):
    """POST /api/insights/{id}/feedback — registra o 👍/👎 do aluno.

    Feedback negativo (👎) aplica uma punição temporária: oculta o insight
    deste aluno por 7 dias. Feedback positivo (👍) não cria, não remove e não
    altera punição — apenas registra o "visto".
    """
    serializer = InsightFeedbackInputSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    util = serializer.validated_data['util']
    # O tipo base é o id sem o sufixo de disciplina (ex.: "ritmo_disciplina:<id>").
    tipo = insight_id.split(':', 1)[0]

    defaults = {
        'tipo': tipo,
        'util': util,
        'motivo': serializer.validated_data['motivo'],
    }
    # Só o feedback negativo mexe na punição. O positivo deixa `ocultar_ate`
    # como está (não remove uma punição já ativa nem cria uma nova).
    if not util:
        defaults['ocultar_ate'] = timezone.now() + timedelta(days=DIAS_PUNICAO)

    feedback, _criado = InsightFeedback.objects.update_or_create(
        aluno=request.user,
        insight_id=insight_id,
        defaults=defaults,
    )
    return Response(
        InsightFeedbackSerializer(feedback).data,
        status=status.HTTP_200_OK,
    )
