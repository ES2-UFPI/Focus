from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .models import Disciplina
from .serializers import DisciplinaSerializer


class DisciplinaViewSet(viewsets.ModelViewSet):
    serializer_class = DisciplinaSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Disciplina.objects.filter(aluno=self.request.user)

    def perform_create(self, serializer):
        serializer.save(aluno=self.request.user)
