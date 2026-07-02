from django.core.exceptions import ValidationError as DjangoValidationError
from django.utils import timezone
from rest_framework import serializers

from .models import SessaoEstudo


class SessaoEstudoSerializer(serializers.ModelSerializer):
    """Serializer para mapear os dados da sessao de estudo para JSON."""

    # Campo calculado para exibir o nome da disciplina nas listagens (somente leitura)
    disciplina_nome = serializers.CharField(source='disciplina.nome', read_only=True)
    semana_estudo = serializers.SerializerMethodField()
    horario_estudo = serializers.SerializerMethodField()

    class Meta:
        model = SessaoEstudo
        # 🔍 Alinhado perfeitamente com as propriedades reais do seu Model
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
      
        read_only_fields = ['id', 'semana_estudo']
        
    def get_semana_estudo(self, obj):
        return timezone.localtime(obj.inicio).isocalendar().week

    def get_horario_estudo(self, obj):
        inicio = timezone.localtime(obj.inicio).strftime('%H:%M')
        fim = timezone.localtime(obj.fim).strftime('%H:%M')
        return f'{inicio} - {fim}'

    def validate(self, attrs):
        # Criamos um dicionário temporário a partir dos dados já validados/tratados pelo DRF
        contexto_validacao = {}
        
        if self.instance:
            contexto_validacao = {
                'id': self.instance.id, # 🌟 ADICIONE ESTA LINHA AQUI! (Injeta o UUID na validação)
                'disciplina_id': self.instance.disciplina_id,
                'inicio': self.instance.inicio,
                'fim': self.instance.fim,
                'status': self.instance.status,
                'duracao_realizada': self.instance.duracao_realizada,
            }
            
        # Mescla estritamente com os novos dados modificados vindos do payload
        for campo, valor in attrs.items():
            if campo == 'disciplina':
                contexto_validacao['disciplina_id'] = valor.id if hasattr(valor, 'id') else valor
            else:
                contexto_validacao[campo] = valor

        # Criamos o objeto temporário de forma segura repassando o ID
        try:
            temp_instance = SessaoEstudo(**contexto_validacao)
            temp_instance.clean()
        except DjangoValidationError as e:
            raise serializers.ValidationError(
                e.message_dict if hasattr(e, 'message_dict') else e.messages
            )

        return attrs
