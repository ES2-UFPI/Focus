from datetime import timedelta
from django.utils import timezone
from django.db.models import Sum, Count, Q
from sessao_estudo.models import SessaoEstudo
from disciplinas.models import Disciplina


class ConsistenciaService:
  

    # ==================== FASE 1: Infraestrutura Básica ====================

    def __init__(self):
        """Inicializar o serviço com cache dinâmico por requisição."""
        self._cache_sessoes = {}

    def obter_sessoes_semana(self, aluno_id):
        """[TASK 2] Obtém todas as sessões concluídas da semana atual de forma sincronizada."""
        if aluno_id in self._cache_sessoes:
            return self._cache_sessoes[aluno_id]

        hoje = timezone.now()
   
        segunda = hoje - timedelta(days=hoje.weekday())
  
        segunda_dt = segunda.replace(hour=0, minute=0, second=0, microsecond=0)
        proxima_segunda_dt = segunda_dt + timedelta(days=7)

        sessoes = list(SessaoEstudo.objects.filter(
            disciplina__aluno_id=aluno_id,
            status=SessaoEstudo.StatusSessao.CONCLUIDO,
            inicio__gte=segunda_dt,
            inicio__lt=proxima_segunda_dt
        ).order_by('inicio'))

        self._cache_sessoes[aluno_id] = sessoes
        return sessoes

    def obter_sessoes_intervalo(self, aluno_id, data_inicio, data_fim):
        """Método utilitário para buscar sessões em qualquer intervalo de datas."""
        return SessaoEstudo.objects.filter(
            disciplina__aluno_id=aluno_id,
            status=SessaoEstudo.StatusSessao.CONCLUIDO,
            inicio__gte=data_inicio,
            inicio__lt=data_fim
        ).order_by('inicio')

    def calcular_horas_estudadas(self, aluno_id):
        """[TASK 3] Calcula total de horas realmente estudadas (duracao_realizada)."""
        sessoes = self.obter_sessoes_semana(aluno_id)
        # Soma usando iteração direta sobre a lista em cache
        total_minutos = sum(sessao.duracao_realizada for sessao in sessoes)

        horas = total_minutos // 60
        minutos = total_minutos % 60

        return {
            'minutos': total_minutos,
            'horas': total_minutos / 60,
            'formatado': f"{horas}h {minutos}min"
        }

    def calcular_horas_planejadas(self, aluno_id):
        """
        [TASK 4] Calcula total de horas planejadas (fim - inicio).

        """
        sessoes = self.obter_sessoes_semana(aluno_id)

        total_minutos = 0
        for sessao in sessoes:
            duracao = sessao.fim - sessao.inicio
        
            minutos = round(duracao.total_seconds() / 60)
            total_minutos += minutos

        horas = total_minutos // 60
        minutos = total_minutos % 60

        return {
            'minutos': total_minutos,
            'horas': total_minutos / 60,
            'formatado': f"{horas}h {minutos}min"
        }

    def obter_sessoes_semana_disciplina(self, aluno_id, disciplina_id):
        """
        Obtém sessões concluídas de uma disciplina específica na semana.

        """
        hoje = timezone.now()
        segunda = hoje - timedelta(days=hoje.weekday())
        segunda = segunda.replace(hour=0, minute=0, second=0, microsecond=0)

        proxima_segunda = segunda + timedelta(days=7)

        sessoes = SessaoEstudo.objects.filter(
            disciplina_id=disciplina_id,
            disciplina__aluno_id=aluno_id,
            status=SessaoEstudo.StatusSessao.CONCLUIDO,
            inicio__gte=segunda,
            inicio__lt=proxima_segunda
        ).order_by('inicio')

        return sessoes

    def calcular_horas_estudadas_disciplina(self, aluno_id, disciplina_id, sessoes_pre_filtradas=None):
        """Calcula horas realmente estudadas de uma disciplina."""
        if sessoes_pre_filtradas is not None:
            sessoes = sessoes_pre_filtradas
        else:
            # Reutiliza o cache em memória em vez de ir ao banco por disciplina
            sessoes_semana = self.obter_sessoes_semana(aluno_id)
            sessoes = [
                s for s in sessoes_semana if s.disciplina_id == disciplina_id]

        total_minutos = sum(s.duracao_realizada for s in sessoes)

        horas = total_minutos // 60
        minutos = total_minutos % 60

        return {
            'minutos': total_minutos,
            'horas': total_minutos / 60,
            'formatado': f"{horas}h {minutos}min"
        }

    def calcular_horas_planejadas_disciplina(self, aluno_id, disciplina_id):
        """
        Calculas horas planejadas (fim - inicio) de uma disciplina.
        """
        sessoes = self.obter_sessoes_semana_disciplina(aluno_id, disciplina_id)

        total_minutos = 0
        for sessao in sessoes:
            duracao = sessao.fim - sessao.inicio
            # Aplica a mesma correção de arredondamento seguro
            minutos = round(duracao.total_seconds() / 60)
            total_minutos += minutos

        horas = total_minutos // 60
        minutos = total_minutos % 60

        return {
            'minutos': total_minutos,
            'horas': total_minutos / 60,
            'formatado': f"{horas}h {minutos}min"
        }

    # ==================== FASE 2: Indicadores Básicos ====================

    def calcular_sessoes_concluidas(self, aluno_id):
        """[TASK 5] Conta quantas sessões foram concluídas na semana."""
        return len(self.obter_sessoes_semana(aluno_id))

    def calcular_consistencia_por_dia(self, aluno_id):
        """
        [TASK 6] Determina quais dias da semana tiveram estudo.
        """
        sessoes = self.obter_sessoes_semana(aluno_id)

        dias_nomes = {
            0: 'segunda',
            1: 'terça',
            2: 'quarta',
            3: 'quinta',
            4: 'sexta',
            5: 'sábado',
            6: 'domingo'
        }

        dias_estudados = set()
        for sessao in sessoes:
            dia_semana = sessao.inicio.weekday()
            dias_estudados.add(dia_semana)

        resultado = {}
        for num, nome in dias_nomes.items():
            resultado[nome] = num in dias_estudados

        resultado['dias_com_estudo'] = len(dias_estudados)
        return resultado

    def calcular_frequencia_semanal(self, aluno_id):
        """
        [TASK 7] Calcula percentual de dias estudados na semana.


        """
        consistencia = self.calcular_consistencia_por_dia(aluno_id)
        dias_estudados = consistencia['dias_com_estudo']
        dias_totais = 7

        percentual = (dias_estudados / dias_totais) * 100

        return {
            'percentual': round(percentual, 2),
            'dias_estudados': dias_estudados,
            'dias_totais': dias_totais
        }


        sessoes = self.obter_sessoes_semana(aluno_id)
        hoje_dt = timezone.now().date()

        dias_estudados_dates = {s.inicio.date() for s in sessoes}

        dias_nomes_pt = {
            0: 'segunda', 1: 'terça', 2: 'quarta', 3: 'quinta',
            4: 'sexta', 5: 'sábado', 6: 'domingo'
        }

        streak = 0
        dias_sequence = []
        analisando_data = hoje_dt

        for _ in range(7):
            if analisando_data in dias_estudados_dates:
                streak += 1
                dias_sequence.append(dias_nomes_pt[analisando_data.weekday()])
                analisando_data -= timedelta(days=1)
            else:
                # Se não estudou hoje, mas estudou ontem, o streak continua ativo a partir de ontem
                if _ == 0 and (hoje_dt - timedelta(days=1)) in dias_estudados_dates:
                    analisando_data -= timedelta(days=1)
                    continue
                break

        return {
            'streak': streak,
            'dias': dias_sequence
        }

    def calcular_meta_disciplinas(self, aluno_id, sessoes_contexto=None):
        """Calcula metas. Aceita sessoes_contexto externa para reutilização em datas passadas."""
        disciplinas = Disciplina.objects.filter(aluno_id=aluno_id, ativo=True)
        resultado = []

        for disc in disciplinas:
            if sessoes_contexto is not None:
                sessoes_disc = [
                    s for s in sessoes_contexto if s.disciplina_id == disc.id]
            else:
                sessoes_semana = self.obter_sessoes_semana(aluno_id)
                sessoes_disc = [
                    s for s in sessoes_semana if s.disciplina_id == disc.id]

            horas = self.calcular_horas_estudadas_disciplina(
                aluno_id, disc.id, sessoes_pre_filtradas=sessoes_disc)
            horas_total = horas['horas']

    
            meta = float(disc.meta_horas_semanais)
            atingiu = horas_total >= meta

            resultado.append({
                'disciplina_id': str(disc.id),
                'nome': disc.nome,
                'horas_estudadas': horas_total,
                'meta': meta,
                'atingiu': atingiu,
                'diferenca': round(horas_total - meta, 2)
            })

        return resultado

    def calcular_semanas_consecutivas(self, aluno_id):

        hoje = timezone.now()
        segunda_atual = hoje - timedelta(days=hoje.weekday())
        segunda_atual = segunda_atual.replace(
            hour=0, minute=0, second=0, microsecond=0)

        semanas_consecutivas = 0
        melhor_sequencia = 0

        # Checa a semana atual primeiro
        metas_atual = self.calcular_meta_disciplinas(aluno_id)
        if metas_atual and all(m['atingiu'] for m in metas_atual):
            semanas_consecutivas = 1
            melhor_sequencia = 1

        for semana_num in range(1, 52):
            segunda_anterior = segunda_atual - timedelta(days=7 * semana_num)
            proxima_segunda = segunda_anterior + timedelta(days=7)

            # Busca as sessões REAIS daquela semana específica passada
            sessoes_da_semana = list(self.obter_sessoes_intervalo(
                aluno_id, segunda_anterior, proxima_segunda))

            if not sessoes_da_semana:
                break

            # Injeta as sessões daquela semana para avaliar as metas do passado corretamente
            metas_semana = self.calcular_meta_disciplinas(
                aluno_id, sessoes_contexto=sessoes_da_semana)
            todas_atingidas_semana = all(m['atingiu'] for m in metas_semana)

            if todas_atingidas_semana:
                if semanas_consecutivas > 0:
                    semanas_consecutivas += 1
                else:
                    semanas_consecutivas = 1
                melhor_sequencia = max(melhor_sequencia, semanas_consecutivas)
            else:
                melhor_sequencia = max(melhor_sequencia, semanas_consecutivas)
                semanas_consecutivas = 0

        return {
            'semanas_consecutivas': semanas_consecutivas,
            'melhor_sequencia': melhor_sequencia
        }

    # ==================== FASE 3: Indicadores Avançados ====================

    def calcular_indice_consistencia(self, aluno_id):
        """
        [TASK 11] Cria score de 0-100 com base em múltiplos fatores.


        Score = frequência (40%) + metas_atingidas (40%) + streak (20%)
        """
        frequencia = self.calcular_frequencia_semanal(aluno_id)
        metas = self.calcular_meta_disciplinas(aluno_id)
        streak = self.calcular_streak_atual(aluno_id)

        score_frequencia = frequencia['percentual']

        metas_atingidas = sum(1 for m in metas if m['atingiu'])
        score_metas = (metas_atingidas / max(len(metas), 1)) * \
            100 if metas else 0

        score_streak = min((streak['streak'] / 7) * 100, 100)

        indice = (
            (score_frequencia * 0.4) +
            (score_metas * 0.4) +
            (score_streak * 0.2)
        )

        return {
            'indice': round(indice, 2),
            'componentes': {
                'frequencia': round(score_frequencia, 2),
                'metas': round(score_metas, 2),
                'streak': round(score_streak, 2)
            }
        }

    def obter_desempenho_disciplina(self, aluno_id, disciplina_id):
        disciplina = Disciplina.objects.get(
            id=disciplina_id,
            aluno_id=aluno_id
        )

        horas = self.calcular_horas_estudadas_disciplina(
            aluno_id,
            disciplina_id
        )

        sessoes = self.obter_sessoes_semana_disciplina(
            aluno_id,
            disciplina_id
        )

        percentual = 0

        if disciplina.meta_horas_semanais > 0:
            percentual = (
                horas['horas'] /
                disciplina.meta_horas_semanais
            ) * 100

        return {
            'disciplina_id': str(disciplina.id),
            'disciplina': disciplina.nome,
            'meta_horas_semanais': disciplina.meta_horas_semanais,
            'horas_estudadas': horas['horas'],
            'sessoes_concluidas': sessoes.count(),
            'percentual_meta': round(percentual, 2),
            'atingiu_meta': horas['horas'] >= disciplina.meta_horas_semanais
        }

    def obter_ranking_disciplinas(self, aluno_id):
        disciplinas = Disciplina.objects.filter(
            aluno_id=aluno_id,
            ativo=True
        )

        ranking = []

        for disciplina in disciplinas:
            horas = self.calcular_horas_estudadas_disciplina(
                aluno_id,
                disciplina.id
            )

            ranking.append({
                'disciplina_id': str(disciplina.id),
                'disciplina': disciplina.nome,
                'horas': horas['horas']
            })

        return sorted(
            ranking,
            key=lambda item: item['horas'],
            reverse=True
        )

    def obter_disciplina_mais_negligenciada(self, aluno_id):
        metas = self.calcular_meta_disciplinas(aluno_id)

        atrasadas = [
            item for item in metas
            if not item['atingiu']
        ]

        if not atrasadas:
            return None

        atrasadas.sort(
            key=lambda item: item['diferenca']
        )

        return atrasadas[0]

    def calcular_distribuicao_disciplinas(self, aluno_id):
        """
        [TASK 12] Prepara dados para gráfico de pizza (disciplinas).

        """
        disciplinas = Disciplina.objects.filter(aluno_id=aluno_id, ativo=True)
        total_horas = self.calcular_horas_estudadas(aluno_id)['horas']

        resultado = []
        for disc in disciplinas:
            horas = self.calcular_horas_estudadas_disciplina(aluno_id, disc.id)[
                'horas']
            percentual = (horas / total_horas * 100) if total_horas > 0 else 0

            resultado.append({
                'disciplina': disc.nome,
                'disciplina_id': str(disc.id),
                'horas': round(horas, 2),
                'percentual': round(percentual, 2)
            })

        return sorted(resultado, key=lambda x: x['horas'], reverse=True)

    def detectar_baixa_consistencia(self, aluno_id):
        """
        [TASK 13] Gera alertas quando consistência está abaixo do esperado.

  
        """
        alertas = []
        severidade = 'baixa'

        frequencia = self.calcular_frequencia_semanal(aluno_id)
        metas = self.calcular_meta_disciplinas(aluno_id)
        streak = self.calcular_streak_atual(aluno_id)
        indice = self.calcular_indice_consistencia(aluno_id)

        if frequencia['percentual'] < 60:
            alertas.append(
                f"Frequência baixa: apenas {frequencia['dias_estudados']}/7 dias")
            severidade = 'media'

        metas_nao_atingidas = [m['nome'] for m in metas if not m['atingiu']]
        if metas_nao_atingidas:
            alertas.append(
                f"Meta não atingida em: {', '.join(metas_nao_atingidas)}")
            severidade = 'media'

        if streak['streak'] < 3:
            alertas.append(
                f"Streak baixo: apenas {streak['streak']} dias consecutivos")
            severidade = 'media'

        if indice['indice'] < 50:
            alertas.append(f"Consistência crítica: índice {indice['indice']}%")
            severidade = 'alta'

        return {
            'alertas': alertas,
            'severidade': severidade,
            'total_alertas': len(alertas)
        }

    def comparar_semanas(self, aluno_id):
        """
        [TASK 14] Compara semana atual com semana anterior de forma otimizada.

        """
        hoje = timezone.now()
        segunda_atual = hoje - timedelta(days=hoje.weekday())
        segunda_atual = segunda_atual.replace(
            hour=0, minute=0, second=0, microsecond=0)

        segunda_anterior = segunda_atual - timedelta(days=7)

        # Função interna para buscar dados REAIS de semanas passadas
        def obter_dados_semana_passada(seg, prox_seg):
            sessoes = self.obter_sessoes_intervalo(aluno_id, seg, prox_seg)

            # Se for uma lista comum do Python (Cache)
            if isinstance(sessoes, list):
                total_minutos = sum(s.duracao_realizada for s in sessoes)
                total_sessoes = len(sessoes)
            # Se for um QuerySet do Django (Banco de Dados)
            else:
                total_minutos = sessoes.aggregate(duracao_realizada=Sum('duracao_realizada'))[
                    'duracao_realizada'] or 0
                total_sessoes = sessoes.count()

            return {
                'sessoes': total_sessoes,
                'horas': round(total_minutos / 60, 2),
                'minutos': total_minutos
            }

        # Semana atual lê diretamente das funções com cache em memória (Zero queries extras)
        semana_atual = {
            'sessoes': self.calcular_sessoes_concluidas(aluno_id),
            'horas': round(self.calcular_horas_estudadas(aluno_id)['horas'], 2),
            'minutos': self.calcular_horas_estudadas(aluno_id)['minutos']
        }

        # Semana anterior vai buscar o histórico real usando os intervalos corretos
        semana_anterior = obter_dados_semana_passada(
            segunda_anterior, segunda_atual)

        diferenca = {
            'sessoes': semana_atual['sessoes'] - semana_anterior['sessoes'],
            'horas': round(semana_atual['horas'] - semana_anterior['horas'], 2)
        }

        return {
            'semana_atual': semana_atual,
            'semana_anterior': semana_anterior,
            'diferenca': diferenca
        }

    def obter_evolucao_consistencia(self, aluno_id, semanas=12):
        """
        [TASK 15] Prepara histórico das últimas 12 semanas.

        """
        hoje = timezone.now()
        segunda_atual = hoje - timedelta(days=hoje.weekday())
        segunda_atual = segunda_atual.replace(
            hour=0, minute=0, second=0, microsecond=0)

        evolucao = []

        for semana_num in range(semanas):
            segunda = segunda_atual - timedelta(days=7 * semana_num)
            proxima_segunda = segunda + timedelta(days=7)

            sessoes = SessaoEstudo.objects.filter(
                disciplina__aluno_id=aluno_id,
                status=SessaoEstudo.StatusSessao.CONCLUIDO,
                inicio__gte=segunda,
                inicio__lt=proxima_segunda
            )

            # Forçamos o alias da chave para 'duracao_realizada'
            total_minutos = sessoes.aggregate(duracao_realizada=Sum('duracao_realizada'))[
                'duracao_realizada'] or 0
            horas = total_minutos / 60
            num_sessoes = sessoes.count()

            indice = 0
            if num_sessoes > 0 or horas > 0:
                indice = min((horas / 10) * 100, 100)

            evolucao.append({
                'semana': semana_num,
                'data_inicio': segunda.date(),
                'indice': round(indice, 2),
                'sessoes': num_sessoes,
                'horas': round(horas, 2)
            })

        return evolucao

    def obter_dashboard_consistencia(self, aluno_id):
        """[TASK 16] Retorna todos os indicadores consolidados de forma otimizada."""
        # Limpa o cache antigo para garantir dados novos na chamada do endpoint
        self._cache_sessoes.pop(aluno_id, None)

        # Executa os cálculos uma única vez e distribui as variáveis no payload
        frequencia = self.calcular_frequencia_semanal(aluno_id)
        consistencia_por_dia = self.calcular_consistencia_por_dia(aluno_id)
        streak = self.calcular_streak_atual(aluno_id)
        metas = self.calcular_meta_disciplinas(aluno_id)
        indice_detalhado = self.calcular_indice_consistencia(aluno_id)

        return {
            'resumo': {
                'indice_consistencia': indice_detalhado['indice'],
                'sessoes_semana': self.calcular_sessoes_concluidas(aluno_id),
                'horas_estudadas': self.calcular_horas_estudadas(aluno_id),
                'horas_planejadas': self.calcular_horas_planejadas(aluno_id)
            },
            'indicadores': {
                'frequencia': frequencia,
                'consistencia_por_dia': consistencia_por_dia,
                'streak': streak,
                'semanas_consecutivas': self.calcular_semanas_consecutivas(aluno_id)
            },
            'metas': {
                'por_disciplina': metas,
                'distribuicao': self.calcular_distribuicao_disciplinas(aluno_id)
            },
            'comparacao': {
                'semanas': self.comparar_semanas(aluno_id)
            },
            'analise': {
                'indice_detalhado': indice_detalhado,
                'alertas': self.detectar_baixa_consistencia(aluno_id)
            },
            'evolucao': {
                'historico_12_semanas': self.obter_evolucao_consistencia(aluno_id, 12)
            }
        }
