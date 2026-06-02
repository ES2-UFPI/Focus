from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from avaliacoes_academicas.views import AvaliacaoAcademicaViewSet
from metas_semanais.views import MetaSemanalViewSet

router = DefaultRouter()
router.register(r'avaliacoes-academicas', AvaliacaoAcademicaViewSet)
router.register(r'metas-semanais', MetaSemanalViewSet)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include(router.urls)),
]
