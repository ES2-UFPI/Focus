from rest_framework import serializers
from .models import MaterialEstudo


class MaterialEstudoSerializer(serializers.ModelSerializer):
    class Meta:
        model = MaterialEstudo
        fields = '__all__'
