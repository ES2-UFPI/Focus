from rest_framework import viewsets
from .models import MetaSemanal
from .serializers import MetaSemanalSerializer


class MetaSemanalViewSet(viewsets.ModelViewSet):
    queryset = MetaSemanal.objects.all()
    serializer_class = MetaSemanalSerializer
