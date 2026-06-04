from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from alunos.views import AlunoViewSet
from disciplinas.views import DisciplinaViewSet
from tarefas_disciplina.views import TarefaDisciplinaViewSet
from avaliacoes_academicas.views import AvaliacaoAcademicaViewSet
from metas_semanais.views import MetaSemanalViewSet
from ciclos_estudo.views import CicloEstudoViewSet
from materiais_estudo.views import MaterialEstudoViewSet
from sessoes_estudo.views import SessaoEstudoViewSet
from feedbacks_sessao.views import FeedbackSessaoViewSet
from recompensas.views import RecompensaViewSet

router = DefaultRouter()
router.register(r'alunos', AlunoViewSet)
router.register(r'disciplinas', DisciplinaViewSet)
router.register(r'tarefas-disciplina', TarefaDisciplinaViewSet)
router.register(r'avaliacoes-academicas', AvaliacaoAcademicaViewSet)
router.register(r'metas-semanais', MetaSemanalViewSet)
router.register(r'ciclos-estudo', CicloEstudoViewSet)
router.register(r'materiais-estudo', MaterialEstudoViewSet)
router.register(r'sessoes-estudo', SessaoEstudoViewSet)
router.register(r'feedbacks-sessao', FeedbackSessaoViewSet)
router.register(r'recompensas', RecompensaViewSet)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include(router.urls)),
]
