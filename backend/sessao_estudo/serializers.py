from rest_framework import serializers
from .models import SessaoEstudo

class SessaoEstudoSerializer(serializers.ModelSerializer):
    """Serializer para mapear os dados da Sessão de Estudo para JSON."""
    
    # Campo complementar opcional: exibe o nome da disciplina no JSON, além do ID
    disciplina_nome = serializers.CharField(source='disciplina.nome', read_only=True)

    class Meta:
        model = SessaoEstudo
        fields = [
            'id', 
            'disciplina', 
            'disciplina_nome', 
            'inicio', 
            'fim', 
            'duracao_realizada', 
            'status'
        ]
        read_only_fields = ['id']