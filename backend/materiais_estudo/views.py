from rest_framework import viewsets
from .models import MaterialEstudo
from .serializers import MaterialEstudoSerializer


class MaterialEstudoViewSet(viewsets.ModelViewSet):
    queryset = MaterialEstudo.objects.all()
    serializer_class = MaterialEstudoSerializer
