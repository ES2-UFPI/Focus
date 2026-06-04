from rest_framework import viewsets
from .models import FeedbackSessao
from .serializers import FeedbackSessaoSerializer


class FeedbackSessaoViewSet(viewsets.ModelViewSet):
    queryset = FeedbackSessao.objects.all()
    serializer_class = FeedbackSessaoSerializer
