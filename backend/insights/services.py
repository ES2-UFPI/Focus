"""Serviço de cálculo dos Insights de perfil de estudo.

Segue o mesmo padrão de `services/consistencia_service.py`: uma classe sem
estado persistente, instanciada por requisição, que lê os dados já coletados
(`SessaoEstudo`, `BlocoPomodoro`, `TarefaDisciplina`) e produz a lista de
insights no contrato esperado pelo frontend
(`frontend/lib/models/insights_model.dart`).

O escopo aqui é intencionalmente pequeno: alimentar as duas seções da tela de
Insights ("Pontos para melhorar" e "Descobertas") e a lista de melhorias
observadas da aba Evolução. Só entram insights que a UI atual realmente exibe.

A abordagem estatística é a aprovada em `docs/plano-backend-insights.md`:
comparação de médias por grupo — sem ML/LLM. Todo insight agregado passa por um
gate de N mínimo; abaixo dele o insight não é exibido.
"""

from collections import defaultdict
from datetime import timedelta

from django.utils import timezone

from sessao_estudo.models import SessaoEstudo
from tarefas_disciplina.models import TarefaDisciplina

from . import statistics as stats
from .models import InsightFeedback


class _Registro:
    """Sessão concluída com os campos já derivados para os cálculos."""

    __slots__ = (
        'id', 'disciplina_id', 'disciplina_nome', 'inicio', 'hora',
        'fim', 'dia_semana', 'duracao_real', 'duracao_planejada',
        'produtividade', 'interrupcoes', 'tipo_atividade', 'status',
    )

    def __init__(self, sessao):
        local = timezone.localtime(sessao.inicio)
        self.id = str(sessao.id)
        self.disciplina_id = str(sessao.disciplina_id)
        self.disciplina_nome = sessao.disciplina.nome
        self.inicio = sessao.inicio
        self.fim = sessao.fim
        self.hora = local.hour
        self.dia_semana = local.weekday()
        self.duracao_real = sessao.duracao_realizada
        self.duracao_planejada = round(
            (sessao.fim - sessao.inicio).total_seconds() / 60
        )
        self.interrupcoes = sessao.interrupcoes
        self.tipo_atividade = sessao.tipo_atividade
        self.status = sessao.status
        # Produtividade da sessão = média das avaliações dos seus blocos.
        notas = [
            b.produtividade
            for b in sessao.blocos_pomodoro.all()
            if b.produtividade is not None
        ]
        self.produtividade = stats.media(notas) if notas else None


class InsightsService:
    """Calcula os insights de um aluno a partir dos dados reais."""

    # Janela de análise padrão (6 semanas ~ "últimas seis semanas" do produto).
    JANELA_DIAS = 42

    # Gate de N mínimo (ajustável por tipo, conforme o plano).
    MIN_AMOSTRA = 5
    # Gate menor para comparações entre dois grupos (N por grupo).
    MIN_POR_GRUPO = 3
    LIMIAR_CONF_ALTA = 15

    FAIXAS_HORARIO = [
        (6, 9, '6-9h'), (9, 12, '9-12h'), (12, 15, '12-15h'),
        (15, 18, '15-18h'), (18, 21, '18-21h'), (21, 24, '21-0h'),
    ]
    DIAS_SEMANA = [
        'segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo',
    ]
    PERIODO_MANHA = range(5, 12)
    PERIODO_NOITE = set(range(18, 24)) | set(range(0, 5))

    def __init__(self):
        self._agora = timezone.now()
        self._inicio_janela = self._agora - timedelta(days=self.JANELA_DIAS)

    # ==================== Coleta de dados ====================

    def _carregar_registros(self, aluno_id):
        """Sessões concluídas na janela, com blocos e disciplina pré-carregados."""
        sessoes = (
            SessaoEstudo.objects
            .filter(
                disciplina__aluno_id=aluno_id,
                status=SessaoEstudo.StatusSessao.CONCLUIDO,
                inicio__gte=self._inicio_janela,
            )
            .select_related('disciplina')
            .prefetch_related('blocos_pomodoro')
            .order_by('inicio')
        )
        return [_Registro(s) for s in sessoes]

    def _confianca(self, amostra):
        if amostra >= self.LIMIAR_CONF_ALTA:
            return 'alta'
        if amostra >= self.MIN_AMOSTRA:
            return 'media'
        return 'insuficiente'

    def _faixa_horario(self, hora):
        for indice, (ini, fim, _label) in enumerate(self.FAIXAS_HORARIO):
            if ini <= hora < fim:
                return indice
        return len(self.FAIXAS_HORARIO) - 1  # madrugada (0-6h) cai em 21-0h

    # ==================== API pública ====================

    def obter_insights(self, aluno_id):
        """Lista de insights (dicts no contrato do frontend), já filtrada.

        Só produz os insights que a tela atual usa:
        - Pontos para melhorar: `taxa_furo`, `duracao_ideal`,
          `ritmo_disciplina`, `vies_estimativa`.
        - Descobertas: `melhor_horario`, `tarefas_no_prazo`,
          `sequencia_produtiva`, `progresso`.
        """
        registros = self._carregar_registros(aluno_id)
        com_produtividade = [r for r in registros if r.produtividade is not None]

        candidatos = [
            # Pontos para melhorar.
            self._insight_taxa_furo(aluno_id),
            self._insight_duracao_ideal(com_produtividade),
            self._insight_ritmo_disciplina(registros),
            self._insight_vies_estimativa(registros),
            # Descobertas.
            self._insight_melhor_horario(com_produtividade),
            self._insight_tarefas_no_prazo(aluno_id),
            self._insight_sequencia_produtiva(com_produtividade),
            self._insight_progresso(aluno_id),
        ]
        insights = [c for c in candidatos if c is not None]

        if not insights:
            insights.append(self._insight_amostra_insuficiente(registros))

        return self._filtrar_ocultos(aluno_id, insights)

    def _filtrar_ocultos(self, aluno_id, insights):
        """Aplica a punição temporária de feedback negativo (👎).

        Insight com punição ativa (`ocultar_ate` no futuro) é omitido para
        aquele aluno. Feedback positivo não influencia nada aqui — a ordem é
        puramente por severidade, independente de qualquer feedback.
        """
        ocultos = {
            f.insight_id
            for f in InsightFeedback.objects.filter(
                aluno_id=aluno_id,
                ocultar_ate__gt=self._agora,
            )
        }
        visiveis = [ins for ins in insights if ins['id'] not in ocultos]

        ordem_sev = {'critico': 0, 'atencao': 1, 'positivo': 2, 'info': 3}
        return sorted(
            visiveis,
            key=lambda ins: ordem_sev.get(ins['severidade'], 4),
        )

    # ==================== Pontos para melhorar ====================

    def _insight_taxa_furo(self, aluno_id):
        sessoes = SessaoEstudo.objects.filter(
            disciplina__aluno_id=aluno_id,
            inicio__gte=self._inicio_janela,
            status__in=[
                SessaoEstudo.StatusSessao.CONCLUIDO,
                SessaoEstudo.StatusSessao.CANCELADO,
            ],
        ).select_related('disciplina')

        # Agrupa por (dia da semana, período) e mede a taxa de cancelamento.
        grupos = defaultdict(
            lambda: {
                'total': 0,
                'canceladas': 0,
                'disc': None,
                'disc_id': None,
                'sessoes': [],
            }
        )
        for s in sessoes:
            local = timezone.localtime(s.inicio)
            periodo = 'manha' if local.hour in self.PERIODO_MANHA else (
                'noite' if local.hour in self.PERIODO_NOITE else 'tarde'
            )
            chave = (local.weekday(), periodo)
            grupos[chave]['total'] += 1
            grupos[chave]['disc'] = s.disciplina.nome
            grupos[chave]['disc_id'] = str(s.disciplina_id)
            grupos[chave]['sessoes'].append(s)
            if s.status == SessaoEstudo.StatusSessao.CANCELADO:
                grupos[chave]['canceladas'] += 1

        pior = None
        for (dia, periodo), dados in grupos.items():
            if dados['total'] < self.MIN_AMOSTRA:
                continue
            taxa = round(dados['canceladas'] / dados['total'] * 100)
            if taxa >= 50 and (pior is None or taxa > pior['taxa']):
                pior = {
                    'dia': dia, 'periodo': periodo, 'taxa': taxa,
                    'total': dados['total'], 'canceladas': dados['canceladas'],
                    'disc': dados['disc'], 'disc_id': dados['disc_id'],
                    'sessoes': dados['sessoes'],
                }
        if pior is None:
            return None

        nome_dia = self.DIAS_SEMANA[pior['dia']]
        return {
            'id': f'taxa_furo:{pior["disc_id"]}',
            'tipo': 'taxa_furo',
            'categoria': 'rotina',
            'disciplina': pior['disc'],
            'titulo': f'{pior["taxa"]}% das sessões de {nome_dia} à {pior["periodo"]} são canceladas',
            'descricao': (
                f'Esse horário concentra {pior["canceladas"]} cancelamentos entre '
                f'as últimas {pior["total"]} sessões planejadas.'
            ),
            'numeros': {
                'sessoes_no_horario': pior['total'],
                'canceladas': pior['canceladas'],
                'taxa_pct': pior['taxa'],
            },
            'amostra': pior['total'],
            'confianca': self._confianca(pior['total']),
            'natureza': 'observacional',
            'severidade': 'critico',
            'grafico': {
                'tipo': 'barras',
                'labels': ['Realizadas', 'Canceladas'],
                'valores': [pior['total'] - pior['canceladas'], pior['canceladas']],
                'destaqueIndex': 1,
            },
            'sessoesEvidencia': self._evidencias_sessoes_canceladas(
                pior['sessoes']
            ),
            'acao': {
                'tipo': 'reagendar',
                'label': f'Reagendar {nome_dia} à {pior["periodo"]}',
                'disciplina_id': pior['disc_id'],
                'horario_sugerido': pior['periodo'],
            },
        }

    def _insight_duracao_ideal(self, registros):
        if len(registros) < self.MIN_AMOSTRA:
            return None

        duracoes = [r.duracao_real for r in registros]
        produtividades = [r.produtividade for r in registros]

        # Procura o melhor ponto de corte que maximiza a queda de produtividade
        # entre sessões curtas e longas (com ambos os grupos acima do gate).
        melhor = None
        for limite in range(30, 91, 5):
            curtas = [p for d, p in zip(duracoes, produtividades) if d <= limite]
            longas = [p for d, p in zip(duracoes, produtividades) if d > limite]
            if len(curtas) < self.MIN_POR_GRUPO or len(longas) < self.MIN_POR_GRUPO:
                continue
            queda_pct = stats.variacao_percentual(stats.media(curtas), stats.media(longas))
            if queda_pct < 0 and (melhor is None or queda_pct < melhor['queda_pct']):
                melhor = {
                    'limite': limite,
                    'antes': stats.media(curtas),
                    'depois': stats.media(longas),
                    'queda_pct': queda_pct,
                }
        if melhor is None or abs(melhor['queda_pct']) < 15:
            return None

        # Chart: produtividade média por faixa de duração.
        faixas = [(0, 30, '≤30 min'), (30, 45, '30-45 min'), (45, 60, '45-60 min'),
                  (60, 90, '60-90 min'), (90, 10 ** 9, '90+ min')]
        valores = []
        for ini, fim, _lbl in faixas:
            grupo = [p for d, p in zip(duracoes, produtividades) if ini <= d < fim]
            valores.append(round(stats.media(grupo), 2) if grupo else 0)

        return {
            'id': 'duracao_ideal',
            'tipo': 'duracao_ideal',
            'categoria': 'foco',
            'titulo': f'Sua produtividade tende a cair após {melhor["limite"]} minutos',
            'descricao': (
                f'Sessões mais longas apresentam uma queda média de '
                f'{abs(melhor["queda_pct"])}% na sua avaliação de produtividade.'
            ),
            'numeros': {
                'limite_min': melhor['limite'],
                'antes_limite': round(melhor['antes'], 2),
                'depois_limite': round(melhor['depois'], 2),
                'queda_pct': abs(melhor['queda_pct']),
            },
            'amostra': len(registros),
            'confianca': self._confianca(len(registros)),
            'natureza': 'observacional',
            'severidade': 'atencao',
            'grafico': {
                'tipo': 'linha',
                'labels': [f[2] for f in faixas],
                'valores': valores,
                'destaqueIndex': 2,
            },
            'sessoesEvidencia': self._evidencias(
                sorted(registros, key=lambda r: r.duracao_real)[:3]
            ),
            'acao': {
                'tipo': 'agendar_sessao',
                'label': f'Testar blocos de até {melhor["limite"]} min',
            },
        }

    def _insight_ritmo_disciplina(self, registros):
        if len(registros) < self.MIN_AMOSTRA:
            return None

        semanas = self.JANELA_DIAS / 7
        limite_recente = self._agora - timedelta(days=14)
        por_disc = defaultdict(
            lambda: {'total': 0, 'recente': 0, 'nome': None, 'regs': []}
        )
        for r in registros:
            por_disc[r.disciplina_id]['total'] += 1
            por_disc[r.disciplina_id]['nome'] = r.disciplina_nome
            por_disc[r.disciplina_id]['regs'].append(r)
            if r.inicio >= limite_recente:
                por_disc[r.disciplina_id]['recente'] += 1

        pior = None
        for disc_id, d in por_disc.items():
            if d['total'] < self.MIN_POR_GRUPO:
                continue
            ritmo_semanal = d['total'] / semanas
            esperado_2sem = round(ritmo_semanal * 2)
            if d['recente'] < esperado_2sem and esperado_2sem >= 2:
                deficit = esperado_2sem - d['recente']
                if pior is None or deficit > pior['deficit']:
                    pior = {
                        'disciplina_id': disc_id, 'nome': d['nome'],
                        'recente': d['recente'], 'esperado': esperado_2sem,
                        'deficit': deficit, 'total': d['total'],
                        'regs': d['regs'],
                    }
        if pior is None:
            return None

        return {
            'id': f'ritmo_disciplina:{pior["disciplina_id"]}',
            'tipo': 'ritmo_disciplina',
            'categoria': 'rotina',
            'disciplina': pior['nome'],
            'titulo': f'{pior["nome"]} recebeu menos atenção nas últimas semanas',
            'descricao': (
                f'Seu ritmo recente ({pior["recente"]} sessões em 2 semanas) ficou '
                f'abaixo das {pior["esperado"]} que você costuma manter.'
            ),
            'numeros': {
                'sessoes_registradas': pior['recente'],
                'minimo_sugerido': pior['esperado'],
            },
            'amostra': pior['total'],
            'confianca': self._confianca(pior['total']),
            'natureza': 'observacional',
            'severidade': 'atencao',
            'sessoesEvidencia': self._evidencias(
                sorted(pior['regs'], key=lambda r: r.inicio, reverse=True)[:3]
            ),
            'acao': {
                'tipo': 'agendar_sessao',
                'label': f'Agendar mais sessões de {pior["nome"]}',
                'disciplina_id': pior['disciplina_id'],
            },
        }

    def _insight_vies_estimativa(self, registros):
        # Considera só sessões com duração realizada e planejada válidas.
        validas = [r for r in registros if r.duracao_real > 0 and r.duracao_planejada > 0]
        if len(validas) < self.MIN_AMOSTRA:
            return None

        # Agrupa por disciplina e escolhe a de maior viés de subestimação.
        por_disc = defaultdict(list)
        for r in validas:
            por_disc[r.disciplina_id].append(r)

        melhor = None
        for disc_id, regs in por_disc.items():
            if len(regs) < self.MIN_POR_GRUPO:
                continue
            estimado = stats.media([r.duracao_planejada for r in regs])
            real = stats.media([r.duracao_real for r in regs])
            delta_pct = stats.variacao_percentual(estimado, real)
            if delta_pct > 15 and (melhor is None or delta_pct > melhor['delta_pct']):
                melhor = {
                    'disciplina_id': disc_id,
                    'disciplina': regs[0].disciplina_nome,
                    'estimado': estimado,
                    'real': real,
                    'delta_pct': delta_pct,
                    'regs': regs,
                }
        if melhor is None:
            return None

        return {
            'id': f'vies_estimativa:{melhor["disciplina_id"]}',
            'tipo': 'vies_estimativa',
            'categoria': 'planejamento',
            'disciplina': melhor['disciplina'],
            'titulo': (
                f'Você costuma subestimar {melhor["disciplina"]} em cerca de '
                f'{melhor["delta_pct"]}%'
            ),
            'descricao': (
                f'As sessões planejadas para {melhor["estimado"]:.0f} minutos '
                f'terminam, em média, com {melhor["real"]:.0f} minutos de duração.'
            ),
            'numeros': {
                'estimado_min': round(melhor['estimado']),
                'real_min': round(melhor['real']),
                'delta_pct': melhor['delta_pct'],
            },
            'amostra': len(melhor['regs']),
            'confianca': self._confianca(len(melhor['regs'])),
            'natureza': 'observacional',
            'severidade': 'atencao',
            'grafico': {
                'tipo': 'comparacao',
                'labels': ['Planejado', 'Realizado'],
                'valores': [round(melhor['estimado']), round(melhor['real'])],
                'destaqueIndex': 1,
            },
            'sessoesEvidencia': self._evidencias(melhor['regs'][:3]),
        }

    # ==================== Descobertas ====================

    def _insight_melhor_horario(self, registros):
        if len(registros) < self.MIN_AMOSTRA:
            return None

        manha = [r.produtividade for r in registros if r.hora in self.PERIODO_MANHA]
        noite = [r.produtividade for r in registros if r.hora in self.PERIODO_NOITE]
        if len(manha) < self.MIN_POR_GRUPO or len(noite) < self.MIN_POR_GRUPO:
            return None

        media_manha = stats.media(manha)
        media_noite = stats.media(noite)
        delta_pct = stats.variacao_percentual(media_noite, media_manha)
        if abs(delta_pct) < 15:
            return None

        # Chart: média de produtividade por faixa de horário.
        soma = defaultdict(float)
        contagem = defaultdict(int)
        for r in registros:
            faixa = self._faixa_horario(r.hora)
            soma[faixa] += r.produtividade
            contagem[faixa] += 1
        valores = [
            round(soma[i] / contagem[i], 2) if contagem[i] else 0
            for i in range(len(self.FAIXAS_HORARIO))
        ]
        destaque = max(range(len(valores)), key=lambda i: valores[i])

        manha_melhor = media_manha >= media_noite
        periodo_evidencia = (
            self.PERIODO_MANHA if manha_melhor else self.PERIODO_NOITE
        )
        return {
            'id': 'melhor_horario',
            'tipo': 'melhor_horario',
            'categoria': 'tempo',
            'titulo': (
                'Seu rendimento tende a ser maior pela manhã'
                if manha_melhor else
                'Seu rendimento tende a ser maior à noite'
            ),
            'descricao': (
                f'Sua produtividade média é {media_manha:.1f} pela manhã e '
                f'{media_noite:.1f} à noite.'
            ),
            'numeros': {
                'manha': round(media_manha, 2),
                'noite': round(media_noite, 2),
                'delta_pct': abs(delta_pct),
            },
            'amostra': len(registros),
            'confianca': self._confianca(len(registros)),
            'natureza': 'observacional',
            'severidade': 'positivo',
            'grafico': {
                'tipo': 'barras',
                'labels': [f[2] for f in self.FAIXAS_HORARIO],
                'valores': valores,
                'destaqueIndex': destaque,
            },
            'sessoesEvidencia': self._evidencias(
                [r for r in registros if r.hora in periodo_evidencia]
            ),
            'acao': {
                'tipo': 'agendar_sessao',
                'label': 'Agendar de manhã' if manha_melhor else 'Agendar à noite',
                'horario_sugerido': 'manha' if manha_melhor else 'noite',
            },
        }

    def _insight_tarefas_no_prazo(self, aluno_id):
        tarefas = TarefaDisciplina.objects.filter(
            disciplina__aluno_id=aluno_id,
            concluida=True,
            data_conclusao__gte=self._inicio_janela,
        )
        total = tarefas.count()
        if total < self.MIN_AMOSTRA:
            return None

        no_prazo = sum(1 for t in tarefas if t.data_conclusao and t.data_conclusao <= t.prazo)
        taxa = round(no_prazo / total * 100)

        return {
            'id': 'tarefas_no_prazo',
            'tipo': 'tarefas_no_prazo',
            'categoria': 'planejamento',
            'titulo': f'{taxa}% das suas tarefas recentes foram concluídas no prazo',
            'descricao': (
                f'Você entregou {no_prazo} de {total} tarefas até a data '
                f'planejada nas últimas semanas.'
            ),
            'numeros': {
                'concluidas': no_prazo,
                'total_tarefas': total,
                'taxa_pct': taxa,
            },
            'amostra': total,
            'confianca': self._confianca(total),
            'natureza': 'observacional',
            # Comportamento bom → aparece como informativo (sem ação).
            'severidade': 'positivo' if taxa >= 70 else 'info',
        }

    def _insight_sequencia_produtiva(self, registros):
        if len(registros) < self.MIN_AMOSTRA:
            return None

        # Maior sequência de sessões consecutivas com produtividade alta (>=4).
        melhor_seq = 0
        seq_atual = 0
        notas_seq = []
        notas_melhor = []
        regs_seq = []
        regs_melhor = []
        for r in registros:  # já ordenados por início
            if r.produtividade >= 4:
                seq_atual += 1
                notas_seq.append(r.produtividade)
                regs_seq.append(r)
                if seq_atual > melhor_seq:
                    melhor_seq = seq_atual
                    notas_melhor = list(notas_seq)
                    regs_melhor = list(regs_seq)
            else:
                seq_atual = 0
                notas_seq = []
                regs_seq = []
        if melhor_seq < 3:
            return None

        return {
            'id': 'sequencia_produtiva',
            'tipo': 'sequencia_produtiva',
            'categoria': 'rotina',
            'titulo': f'Você reuniu {melhor_seq} sessões produtivas em sequência',
            'descricao': (
                f'A sequência teve produtividade média de '
                f'{stats.media(notas_melhor):.1f}.'
            ),
            'numeros': {
                'sequencia_sessoes': melhor_seq,
                'produtividade_media': round(stats.media(notas_melhor), 2),
            },
            'amostra': len(registros),
            'confianca': self._confianca(len(registros)),
            'natureza': 'observacional',
            'severidade': 'positivo',
            'sessoesEvidencia': self._evidencias(regs_melhor[:3]),
        }

    def _insight_progresso(self, aluno_id):
        # Compara taxa de cancelamento das 3 semanas recentes vs 3 anteriores.
        meio = self._agora - timedelta(days=21)
        total_ant, taxa_ant = self._taxa_cancelamento(aluno_id, self._inicio_janela, meio)
        total_rec, taxa_rec = self._taxa_cancelamento(aluno_id, meio, self._agora)
        if total_ant < self.MIN_POR_GRUPO or total_rec < self.MIN_POR_GRUPO:
            return None
        if taxa_ant == 0 or taxa_rec >= taxa_ant:
            return None

        reducao = stats.variacao_percentual(taxa_ant, taxa_rec)
        sessoes_recentes = (
            SessaoEstudo.objects
            .filter(
                disciplina__aluno_id=aluno_id,
                inicio__gte=meio,
                inicio__lt=self._agora,
                status__in=[
                    SessaoEstudo.StatusSessao.CONCLUIDO,
                    SessaoEstudo.StatusSessao.CANCELADO,
                ],
            )
            .select_related('disciplina')
            .prefetch_related('blocos_pomodoro')
            .order_by('-inicio')[:3]
        )
        return {
            'id': 'progresso',
            'tipo': 'progresso',
            'categoria': 'rotina',
            'titulo': 'Seus cancelamentos diminuíram nas últimas semanas',
            'descricao': (
                f'Antes, {taxa_ant}% das sessões eram canceladas; nos registros '
                f'mais recentes, a taxa ficou em {taxa_rec}%.'
            ),
            'numeros': {
                'taxa_anterior_pct': taxa_ant,
                'taxa_atual_pct': taxa_rec,
                'reducao_pct': abs(reducao),
            },
            'amostra': total_ant + total_rec,
            'confianca': self._confianca(total_ant + total_rec),
            'natureza': 'observacional',
            'severidade': 'positivo',
            'sessoesEvidencia': self._evidencias_sessoes(sessoes_recentes),
        }

    # ==================== Fallback ====================

    def _insight_amostra_insuficiente(self, registros):
        return {
            'id': 'amostra_insuficiente',
            'tipo': 'amostra_insuficiente',
            'categoria': 'foco',
            'titulo': 'Seus insights ainda estão se formando',
            'descricao': (
                'Registre mais sessões de estudo, avaliando a produtividade dos '
                'blocos, para desbloquear análises com segurança.'
            ),
            'numeros': {
                'sessoes_registradas': len(registros),
                'minimo_sugerido': self.MIN_AMOSTRA,
            },
            'amostra': len(registros),
            'confianca': 'insuficiente',
            'natureza': 'observacional',
            'severidade': 'info',
        }

    # ==================== Utilitários ====================

    def _taxa_cancelamento(self, aluno_id, desde, ate):
        qs = SessaoEstudo.objects.filter(
            disciplina__aluno_id=aluno_id,
            inicio__gte=desde,
            inicio__lt=ate,
            status__in=[
                SessaoEstudo.StatusSessao.CONCLUIDO,
                SessaoEstudo.StatusSessao.CANCELADO,
            ],
        )
        total = qs.count()
        canceladas = qs.filter(status=SessaoEstudo.StatusSessao.CANCELADO).count()
        return total, (round(canceladas / total * 100) if total else 0)

    def _evidencias_sessoes(self, sessoes, limite=3):
        evidencias = []
        for sessao in list(sessoes)[:limite]:
            inicio = timezone.localtime(sessao.inicio)
            fim = timezone.localtime(sessao.fim)
            notas = [
                b.produtividade
                for b in sessao.blocos_pomodoro.all()
                if b.produtividade is not None
            ]
            evidencias.append({
                'data': inicio.date().isoformat(),
                'horario': f'{inicio:%H:%M} - {fim:%H:%M}',
                'disciplina': sessao.disciplina.nome,
                'duracao_min': sessao.duracao_realizada,
                'produtividade': round(stats.media(notas), 2) if notas else 0,
                'status': sessao.status,
            })
        return evidencias

    def _evidencias_sessoes_canceladas(self, sessoes, limite=6):
        canceladas = sorted(
            (
                s for s in sessoes
                if s.status == SessaoEstudo.StatusSessao.CANCELADO
            ),
            key=lambda s: s.inicio,
            reverse=True,
        )
        evidencias = []
        for sessao in canceladas[:limite]:
            inicio = timezone.localtime(sessao.inicio)
            fim = timezone.localtime(sessao.fim)
            evidencias.append({
                'data': inicio.date().isoformat(),
                'horario': f'{inicio:%H:%M} - {fim:%H:%M}',
                'disciplina': sessao.disciplina.nome,
                'duracao_min': sessao.duracao_realizada,
                'produtividade': 0,
                'status': sessao.status,
            })
        return evidencias

    def _evidencias(self, registros):
        """Converte registros em sessões de evidência do contrato."""
        return [
            {
                'data': timezone.localtime(r.inicio).date().isoformat(),
                'horario': (
                    f'{timezone.localtime(r.inicio):%H:%M} - '
                    f'{timezone.localtime(r.fim):%H:%M}'
                ),
                'disciplina': r.disciplina_nome,
                'duracao_min': r.duracao_real,
                'produtividade': round(r.produtividade, 2) if r.produtividade else 0,
                'status': r.status,
            }
            for r in registros[:3]
        ]

    # ==================== Evolução (melhorias observadas) ====================

    def obter_evolucao(self, aluno_id):
        """Melhorias observadas da aba Evolução.

        A tela só precisa de uma lista simples de melhorias (`jornada`). Cada
        melhoria é uma comparação objetiva entre o começo e o fim da janela,
        atrelada a um insight ruim que ainda aparece na tela — sem provar
        causalidade. Os campos `dimensoes`, `comparacoes` e `experimentos`
        continuam apenas por compatibilidade de contrato e vêm sempre vazios.
        """
        registros = self._carregar_registros(aluno_id)
        insights = self.obter_insights(aluno_id)
        tipos_presentes = {ins['tipo'] for ins in insights}

        periodo = (
            f'{timezone.localtime(self._inicio_janela).date().strftime("%d/%m")} a '
            f'{timezone.localtime(self._agora).date().strftime("%d/%m")}'
        )

        return {
            'periodo': periodo,
            'atualizado_em': timezone.localtime(self._agora).strftime(
                'Atualizado em %d/%m %H:%M'
            ),
            'jornada': self._melhorias_observadas(aluno_id, registros, tipos_presentes),
            'dimensoes': [],
            'comparacoes': [],
            'experimentos': [],
        }

    def _melhorias_observadas(self, aluno_id, registros, tipos_presentes):
        """Lista de melhorias objetivas ligadas a insights ruins ainda ativos."""
        eventos = []
        if 'taxa_furo' in tipos_presentes:
            evento = self._melhoria_cancelamentos(aluno_id)
            if evento is not None:
                eventos.append(evento)
        if 'duracao_ideal' in tipos_presentes:
            evento = self._melhoria_duracao(registros)
            if evento is not None:
                eventos.append(evento)
        return eventos

    def _melhoria_cancelamentos(self, aluno_id):
        meio = self._agora - timedelta(days=21)
        total_ant, taxa_ant = self._taxa_cancelamento(aluno_id, self._inicio_janela, meio)
        total_rec, taxa_rec = self._taxa_cancelamento(aluno_id, meio, self._agora)
        if total_ant < self.MIN_POR_GRUPO or total_rec < self.MIN_POR_GRUPO:
            return None
        if taxa_ant == 0 or taxa_rec >= taxa_ant:
            return None

        return {
            'data': 'Últimas 3 semanas',
            'tipo': 'melhora',
            'texto': (
                f'Os cancelamentos caíram de {taxa_ant}% para {taxa_rec}% depois '
                f'de evitar o horário mais frágil da semana.'
            ),
            'insight_tipo': 'taxa_furo',
        }

    def _melhoria_duracao(self, registros):
        meio = self._agora - timedelta(days=21)
        antigas = [r.duracao_real for r in registros
                   if r.inicio < meio and r.duracao_real > 0]
        recentes = [r.duracao_real for r in registros
                    if r.inicio >= meio and r.duracao_real > 0]
        if len(antigas) < self.MIN_POR_GRUPO or len(recentes) < self.MIN_POR_GRUPO:
            return None

        media_ant = stats.media(antigas)
        media_rec = stats.media(recentes)
        queda_pct = stats.variacao_percentual(media_ant, media_rec)
        # Só relata quando os blocos ficaram sensivelmente mais curtos.
        if queda_pct >= -10:
            return None

        return {
            'data': 'Últimas 3 semanas',
            'tipo': 'melhora',
            'texto': (
                f'A duração média das sessões caiu de {media_ant:.0f} para '
                f'{media_rec:.0f} minutos, mais perto do ponto ideal.'
            ),
            'insight_tipo': 'duracao_ideal',
        }
