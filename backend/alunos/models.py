import uuid
from django.contrib.auth.models import AbstractUser
from django.db import models


class Aluno(AbstractUser):
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    nome = models.CharField(max_length=255)

    email = models.EmailField(
        unique=True
    )

    data_nascimento = models.DateField(blank=True, null=True)

    data_cadastro = models.DateTimeField(
        auto_now_add=True
    )

    username = models.CharField(
        max_length=150,
        unique=True,
        blank=True,
        null=True
    )

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["nome"]

    class Meta:
        verbose_name = "Aluno"
        verbose_name_plural = "Alunos"

    def __str__(self):
        return str(self.nome)

    def save(self, *args, **kwargs):
        if not self.username:
            self.username = self.email
        super().save(*args, **kwargs)
