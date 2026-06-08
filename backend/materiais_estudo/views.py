from rest_framework import viewsets, filters
from rest_framework.permissions import IsAuthenticated
from .models import MaterialEstudo
from .serializers import MaterialEstudoSerializer


class MaterialEstudoViewSet(viewsets.ModelViewSet):
    serializer_class = MaterialEstudoSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['titulo', 'descricao']
    ordering_fields = ['data_insercao', 'titulo']
    ordering = ['-data_insercao']

    def get_queryset(self):
        qs = MaterialEstudo.objects.filter(
            disciplina__aluno=self.request.user
        ).select_related('disciplina')

        disciplina_id = self.request.query_params.get('disciplina')
        tipo = self.request.query_params.get('tipo')

        if disciplina_id:
            qs = qs.filter(disciplina_id=disciplina_id)
        if tipo:
            qs = qs.filter(tipo=tipo)

        return qs
