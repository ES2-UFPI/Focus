from rest_framework import viewsets, filters, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
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
            aluno=self.request.user
        ).select_related('disciplina')

        disciplina_id = self.request.query_params.get('disciplina')
        tipo = self.request.query_params.get('tipo')

        if disciplina_id:
            qs = qs.filter(disciplina_id=disciplina_id)
        if tipo:
            qs = qs.filter(tipo=tipo)

        return qs

    def perform_create(self, serializer):
        serializer.save(aluno=self.request.user)

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        if instance.aluno != request.user:
            return Response(status=status.HTTP_403_FORBIDDEN)
        return super().update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        if instance.aluno != request.user:
            return Response(status=status.HTTP_403_FORBIDDEN)
        return super().destroy(request, *args, **kwargs)
