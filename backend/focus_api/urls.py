from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter

from alunos.views import AlunoViewSet
from disciplinas.views import DisciplinaViewSet
from tarefas_disciplina.views import TarefaDisciplinaViewSet
from materiais_estudo.views import MaterialEstudoViewSet
from eventos_academicos.views import EventoAcademicoViewSet
from sessao_estudo.views import SessaoEstudoViewSet
from feedback_sessao_estudo.views import FeedbackSessaoEstudoViewSet


router = DefaultRouter()


router.register(r'alunos', AlunoViewSet)
router.register(r'disciplinas', DisciplinaViewSet)
router.register(r'tarefas-disciplina', TarefaDisciplinaViewSet)
router.register(r'materiais-estudo', MaterialEstudoViewSet)
router.register(r'eventos-academicos', EventoAcademicoViewSet)
router.register(r'sessoes-estudo', SessaoEstudoViewSet)
router.register(r'feedbacks-sessao', FeedbackSessaoEstudoViewSet)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include(router.urls)),
]
