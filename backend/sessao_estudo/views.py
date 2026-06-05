from rest_framework import viewsets

from .models import SessaoEstudo
from .serializers import SessaoEstudoSerializer


class SessaoEstudoViewSet(viewsets.ModelViewSet):
 
    queryset = SessaoEstudo.objects.all()
    serializer_class = SessaoEstudoSerializer
