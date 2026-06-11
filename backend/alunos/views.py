from rest_framework import viewsets, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from .models import Aluno
from .serializers import AlunoSerializer, RegisterSerializer, LoginSerializer


class AlunoViewSet(viewsets.ModelViewSet):
    queryset = Aluno.objects.all()
    serializer_class = AlunoSerializer


@api_view(['POST'])
@permission_classes([AllowAny])
def registro(request):
    serializer = RegisterSerializer(data=request.data)
    if serializer.is_valid():
        aluno = serializer.save()
        token, _ = Token.objects.get_or_create(user=aluno)
        return Response({
            'token': token.key,
            'aluno': AlunoSerializer(aluno).data,
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    serializer = LoginSerializer(data=request.data)
    if serializer.is_valid():
        aluno = serializer.validated_data['aluno']
        token, _ = Token.objects.get_or_create(user=aluno)
        return Response({
            'token': token.key,
            'aluno': AlunoSerializer(aluno).data,
        })
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
