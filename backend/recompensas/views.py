from rest_framework import viewsets
from .models import Recompensa
from .serializers import RecompensaSerializer


class RecompensaViewSet(viewsets.ModelViewSet):
    queryset = Recompensa.objects.all()
    serializer_class = RecompensaSerializer
