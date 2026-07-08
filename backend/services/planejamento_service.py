from disciplinas.models import Disciplina
from sessao_estudo.models import PlanejamentoDisciplina
from services.semana_service import SemanaService


class PlanejamentoService:
    def obter_metas_semana_atual(self, aluno_id):
        semana = SemanaService().obter_ou_criar_semana_atual(aluno_id)

        disciplinas = Disciplina.objects.filter(
            aluno_id=aluno_id,
            ativo=True
        ).order_by('nome')

        resultado = []

        for disciplina in disciplinas:
            planejamento = PlanejamentoDisciplina.objects.filter(
                semana_estudo=semana,
                disciplina=disciplina
            ).first()

            resultado.append({
                'id': str(planejamento.id) if planejamento else None,
                'semana_estudo': str(semana.id),
                'data_inicio': semana.data_inicio,
                'data_fim': semana.data_fim,
                'disciplina': str(disciplina.id),
                'disciplina_nome': disciplina.nome,
                'carga_horaria_planejada': (
                    planejamento.carga_horaria_planejada
                    if planejamento else 0
                ),
            })

        return resultado