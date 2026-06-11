from django.contrib.auth.base_user import BaseUserManager


class AlunoManager(BaseUserManager):
    """Manager customizado para o modelo Aluno, onde o email é

    o identificador único para autenticação em vez do username.
    """

    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError("O email é obrigatório para criar um aluno.")

        email = self.normalize_email(email)

        # Forçamos o username a receber o próprio e-mail por baixo dos panos
        # para não quebrar tabelas internas do Django Admin/Auth
        extra_fields.setdefault("username", email)

        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)

        if extra_fields.get("is_staff") is not True:
            raise ValueError("Superuser precisa ter is_staff=True.")
        if extra_fields.get("is_superuser") is not True:
            raise ValueError("Superuser precisa ter is_superuser=True.")

        return self.create_user(email, password, **extra_fields)