from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import serializers

from .models import SessaoEstudo


class SessaoEstudoSerializer(serializers.ModelSerializer):
    
    class Meta:
        model = SessaoEstudo
        fields = '__all__'

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
            raise serializers.ValidationError(e.message_dict if hasattr(e, 'message_dict') else e.messages)
        
        return attrs