import uuid
from django.db import models
from sessao_estudo.models import SessaoEstudo  


class FeedbackSessaoEstudo(models.Model):
   
    class NivelProdutividade(models.IntegerChoices):
        MUITO_BAIXA = 1, 'Muito Baixa'
        BAIXA = 2, 'Baixa'
        REGULAR = 3, 'Regular'
        ALTA = 4, 'Alta'
        MUITO_ALTA = 5, 'Muito Alta'

    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
   
    sessao_estudo = models.OneToOneField(
        SessaoEstudo,
        on_delete=models.CASCADE,
        related_name='feedback'
    )

    produtividade = models.PositiveSmallIntegerField(
        choices=NivelProdutividade.choices,
        help_text="Nota de 1 a 5 para o rendimento do estudante na sessão."
    )
    descricao = models.TextField(
        blank=True, 
        null=True,
        help_text="Anotações opcionais sobre o que atrapalhou ou ajudou no foco."
    )

    hora_registro = models.DateTimeField(
        auto_now_add=True,
        help_text="Momento exato em que o feedback foi enviado."
    )
    class Meta:
        verbose_name = 'Feedback da Sessão'
        verbose_name_plural = 'Feedbacks das Sessões'
        ordering = ['-hora_registro']

    def __str__(self):

        prod_txt = self.NivelProdutividade(self.produtividade).label
        return f"Feedback: {self.sessao_estudo} - Produtividade: {prod_txt}"