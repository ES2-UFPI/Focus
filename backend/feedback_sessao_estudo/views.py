from rest_framework import viewsets

from .models import FeedbackSessaoEstudo
from .serializers import FeedbackSessaoEstudoSerializer


class FeedbackSessaoEstudoViewSet(viewsets.ModelViewSet):

    queryset = FeedbackSessaoEstudo.objects.all()
    serializer_class = FeedbackSessaoEstudoSerializer
