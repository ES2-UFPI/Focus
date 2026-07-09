from datetime import timedelta
from django.db import IntegrityError, transaction
from django.utils import timezone

from sessao_estudo.models import SemanaEstudo


class SemanaService:
    """
    Resolve a SemanaEstudo correspondente ao momento atual (ou a uma data
    arbitrária) para um aluno, criando-a automaticamente se necessário.

    Toda a lógica de "qual é a semana de hoje" vive aqui — nenhum outro
    lugar do sistema deve calcular isso por conta própria.
    """

    def calcular_limites_semana(self, referencia=None):
        """
        Calcula segunda-feira 00:00:00 e domingo 23:59:59 no horário
        local, a partir de uma data de referência (default: agora).

        Returns:
            tuple[date, date]: (data_inicio, data_fim)
        """
        if referencia is None:
            referencia = timezone.localtime(timezone.now())
        elif timezone.is_aware(referencia):
            referencia = timezone.localtime(referencia)

        segunda = referencia - timedelta(days=referencia.weekday())
        domingo = segunda + timedelta(days=6)

        return segunda.date(), domingo.date()

    def obter_ou_criar_semana_atual(self, aluno_id):
        """
        Retorna a SemanaEstudo da semana corrente do aluno, criando-a
        se ainda não existir. Operação atômica e segura contra
        condições de corrida (duas requisições simultâneas não criam
        semanas duplicadas).
        """
        return self.obter_ou_criar_semana_para_data(aluno_id, timezone.now())

    def obter_ou_criar_semana_para_data(self, aluno_id, referencia):
        """
        Mesma lógica de obter_ou_criar_semana_atual, mas para uma data
        arbitrária — útil para registrar sessões retroativas ou migrar
        dados históricos.
        """
        data_inicio, data_fim = self.calcular_limites_semana(referencia)

        try:
            with transaction.atomic():
                semana, _criada = SemanaEstudo.objects.get_or_create(
                    aluno_id=aluno_id,
                    data_inicio=data_inicio,
                    defaults={'data_fim': data_fim, 'ativa': True}
                )
        except IntegrityError:
            # Corrida entre requisições concorrentes: outra já criou.
            # A constraint UniqueConstraint garante consistência; aqui
            # apenas buscamos o registro que venceu a corrida.
            semana = SemanaEstudo.objects.get(
                aluno_id=aluno_id, data_inicio=data_inicio
            )

        self._atualizar_flag_ativa(aluno_id, semana.id)
        return semana

    def _atualizar_flag_ativa(self, aluno_id, semana_atual_id):
        """
        Garante que apenas a semana mais recente do aluno fique marcada
        como ativa=True. Semanas antigas são desativadas automaticamente
        quando uma nova é criada ou acessada.
        """
        SemanaEstudo.objects.filter(
            aluno_id=aluno_id
        ).exclude(id=semana_atual_id).update(ativa=False)

        SemanaEstudo.objects.filter(id=semana_atual_id).update(ativa=True)

    def listar_semanas(self, aluno_id, limite=12):
        """Histórico de semanas do aluno, mais recente primeiro."""
        return SemanaEstudo.objects.filter(
            aluno_id=aluno_id
        ).order_by('-data_inicio')[:limite]

    def obter_semana_ativa(self, aluno_id):
        """
        Retorna a semana ativa do aluno sem criar uma nova. Útil para
        leituras (dashboard) onde criar uma semana vazia não faz sentido
        se o aluno nunca teve nenhuma sessão.
        """
        return SemanaEstudo.objects.filter(
            aluno_id=aluno_id, ativa=True
        ).first()