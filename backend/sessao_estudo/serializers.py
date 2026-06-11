from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import serializers
from .models import SessaoEstudo

class SessaoEstudoSerializer(serializers.ModelSerializer):
    """Serializer para mapear os dados da Sessão de Estudo para JSON."""
    
    disciplina_nome = serializers.CharField(source='disciplina.nome', read_only=True)

    class Meta:
        model = SessaoEstudo
        fields = [
            'id', 
            'semana_estudo',
            'disciplina', 
            'disciplina_nome', 
            'horario_estudo',
            'inicio', 
            'fim', 
            'duracao_realizada', 
            'status'
        ]
      
        read_only_fields = ['id', 'semana_estudo', 'duracao_realizada']

    def validate(self, attrs):
       
        instance = self.instance
        if instance:
            for field, value in attrs.items():
                setattr(instance, field, value)
        else:
            instance = SessaoEstudo(**attrs)
        
        try:
         
            instance.clean()
        except DjangoValidationError as e:
            raise serializers.ValidationError(
                e.message_dict if hasattr(e, 'message_dict') else e.messages
            )
        
        return attrs