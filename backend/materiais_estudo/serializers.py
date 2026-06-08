from rest_framework import serializers
from .models import MaterialEstudo


class MaterialEstudoSerializer(serializers.ModelSerializer):
    disciplina_nome = serializers.CharField(source='disciplina.nome', read_only=True)

    class Meta:
        model = MaterialEstudo
        fields = [
            'id', 'titulo', 'tipo', 'url', 'arquivo',
            'descricao', 'disciplina', 'disciplina_nome', 'data_insercao',
        ]
        read_only_fields = ['id', 'data_insercao', 'disciplina_nome']
