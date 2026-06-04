from rest_framework import viewsets
from .models import TarefaDisciplina
from .serializers import TarefaDisciplinaSerializer


class TarefaDisciplinaViewSet(viewsets.ModelViewSet):
    queryset = TarefaDisciplina.objects.all()
    serializer_class = TarefaDisciplinaSerializer
