from rest_framework import serializers

from .models import SessaoEstudo


class SessaoEstudoSerializer(serializers.ModelSerializer):
    
    class Meta:
        model = SessaoEstudo
        fields = '__all__'