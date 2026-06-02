from rest_framework import viewsets
from .models import AvaliacaoAcademica
from .serializers import AvaliacaoAcademicaSerializer


class AvaliacaoAcademicaViewSet(viewsets.ModelViewSet):
    queryset = AvaliacaoAcademica.objects.all()
    serializer_class = AvaliacaoAcademicaSerializer
