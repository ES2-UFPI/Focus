import uuid
from django.db import models
from django.core.exceptions import ValidationError
from django.utils import timezone
from disciplinas.models import Disciplina


class EventoAcademico(models.Model):
   
    class TipoEvento(models.TextChoices):
        PROVA = 'PROVA', 'Prova'
        TRABALHO = 'TRABALHO', 'Trabalho'
        SEMINARIO = 'SEMINARIO', 'Seminário'
        APRESENTACAO = 'APRESENTACAO', 'Apresentação'
        OUTRO = 'OUTRO', 'Outro'

   
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    disciplina = models.ForeignKey(
        Disciplina, 
        on_delete=models.CASCADE, 
        related_name='eventos_academicos'
    )

    
    titulo = models.CharField(max_length=255)
    tipo = models.CharField(max_length=20, choices=TipoEvento.choices)
    descricao = models.TextField(blank=True, null=True)
    data_evento = models.DateField()
    hora_inicio = models.TimeField(blank=True, null=True)
    hora_fim = models.TimeField(blank=True, null=True)


    
    concluido = models.BooleanField(default=False)
    data_conclusao = models.DateField(blank=True, null=True)
    data_criacao = models.DateTimeField(auto_now_add=True)

    @property
    def dias_restantes(self):
        today = timezone.localdate()
        return (self.data_evento - today).days

    @property
    def urgencia(self):
        dias = self.dias_restantes
        if dias < 0:
            return 'ATRASADO'
        elif dias <= 3:
            return 'ALTA'
        elif dias <= 7:
            return 'MEDIA'
        else:
            return 'BAIXA'

    def clean(self):
        super().clean()
        if self.hora_fim and not self.hora_inicio:
            raise ValidationError("Defina o horário de início antes de definir o horário de término.")
        if self.hora_inicio and self.hora_fim and self.hora_fim <= self.hora_inicio:
            raise ValidationError("O horário de término deve ser posterior ao horário de início.")
            
        if hasattr(self, 'disciplina') and self.disciplina:
            duplicates = EventoAcademico.objects.filter(
                disciplina=self.disciplina,
                titulo=self.titulo,
                tipo=self.tipo,
                data_evento=self.data_evento
            )
            if self.pk:
                duplicates = duplicates.exclude(pk=self.pk)
            if duplicates.exists():
                raise ValidationError("Este evento acadêmico já está cadastrado para esta disciplina nesta data.")
   
    class Meta:
        verbose_name = 'Evento Acadêmico'
        verbose_name_plural = 'Eventos Acadêmicos'
        ordering = ['data_evento', 'titulo'] 

    def __str__(self):
        return f"{self.titulo} ({self.disciplina.nome if hasattr(self.disciplina, 'nome') else self.disciplina})"