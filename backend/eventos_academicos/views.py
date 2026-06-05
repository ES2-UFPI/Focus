from rest_framework import viewsets

from .models import EventoAcademico
from .serializers import EventoAcademicoSerializer


class EventoAcademicoViewSet(viewsets.ModelViewSet):
    queryset = EventoAcademico.objects.all()
    serializer_class = EventoAcademicoSerializer