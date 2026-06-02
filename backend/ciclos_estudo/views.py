from rest_framework import viewsets
from .models import CicloEstudo
from .serializers import CicloEstudoSerializer


class CicloEstudoViewSet(viewsets.ModelViewSet):
    queryset = CicloEstudo.objects.all()
    serializer_class = CicloEstudoSerializer
