from rest_framework import serializers
from .models import CicloEstudo


class CicloEstudoSerializer(serializers.ModelSerializer):
    class Meta:
        model = CicloEstudo
        fields = '__all__'
