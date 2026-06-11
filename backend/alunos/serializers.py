from rest_framework import serializers
from django.contrib.auth import authenticate
from .models import Aluno


class AlunoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Aluno
        fields = ['id', 'nome', 'email', 'data_cadastro']


class RegisterSerializer(serializers.ModelSerializer):
    senha = serializers.CharField(write_only=True, min_length=6)

    class Meta:
        model = Aluno
        fields = ['nome', 'email', 'senha', 'data_nascimento']

    def create(self, validated_data):
        senha = validated_data.pop('senha')
        aluno = Aluno(**validated_data)
        aluno.set_password(senha)
        aluno.save()
        return aluno


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    senha = serializers.CharField(write_only=True)

    def validate(self, data):
        aluno = authenticate(username=data['email'], password=data['senha'])
        if not aluno:
            raise serializers.ValidationError('Email ou senha incorretos.')
        data['aluno'] = aluno
        return data
