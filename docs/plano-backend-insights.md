# Plano de desenvolvimento — Backend do módulo Insights

> Compilado a partir de `relatorio-dados-calculos-insights.md`,
> `relatorio-implementacao-insights-frontend.md` e `test.md`. Serve de base
> para implementar o backend real do módulo Insights — hoje 100% mock no
> frontend (`frontend/lib/data/insights_mock.dart`).

---

## 1. Estado atual do backend

Já existe e está testado:

- **Models:** `Aluno`, `Disciplina`, `EventoAcademico`, `TarefaDisciplina`,
  `SessaoEstudo`, `FeedbackSessaoEstudo` (ver campo a campo em
  `relatorio-dados-calculos-insights.md`, §2).
- **`ConsistenciaService`** (`backend/services/consistencia_service.py`):
  frequência, horas estudadas/planejadas, metas por disciplina, streak,
  índice de consistência composto, ranking, distribuição por disciplina,
  comparação entre semanas, evolução de 12 semanas. **Nunca cruza com
  produtividade, horário do dia ou dia da semana.**
- **`AgendaView`** (`backend/eventos_academicos/views.py`): única rota que já
  gera recomendação baseada em regra (proximidade de evento × contagem de
  sessões futuras) — é o padrão mais próximo do que Insights quer generalizar.

**Não existe hoje:**
- Rota `/api/insights/` ou qualquer endpoint que devolva os 16 tipos de
  insight do mock.
- Persistência de `InsightFeedback` (o frontend já tem UI de 👍/👎, mas o
  estado é só local — comentário no código já aponta o destino real:
  `POST /api/insights/{id}/feedback`).
- Qualquer cálculo que envolva `produtividade`.

---

## 2. Abordagem estatística aprovada (sem ML pesado, sem LLM)

Decisão: dataset é pequeno por aluno (dezenas de sessões/semana) e a única
variável de "qualidade" é `produtividade`, nota 1–5 autodeclarada — ML
supervisionado (SVM/KNN/random forest/redes neurais/deep learning)
generalizaria mal nesse volume. Usar só:

1. **Correlação (Pearson/Spearman)** — pares de variáveis contínuas/ordinais
   já existentes. Spearman é a escolha mais segura por padrão (`produtividade`
   é ordinal, não intervalar de verdade).
2. **Comparação de médias por grupo/bucket** — variável categórica (hora do
   dia, dia da semana, disciplina, tipo de atividade) × produtividade média,
   ou × taxa quando o desfecho é binário (ex.: cancelamento).
3. **Regressão linear/polinomial de baixo grau (grau ≤ 2)** — só quando existe
   hipótese de "ponto ideal" (relação não monotônica), hoje essencialmente só
   `duracao_ideal`. Não extrapolar fora do range observado.
4. **Gate de N mínimo** — todo insight agregado só é exibido se cada grupo
   comparado tiver N ≥ limiar (sugestão inicial: 5 sessões/grupo, ajustável
   por tipo de insight). Abaixo disso: não mostrar, ou mostrar variante
   "dados insuficientes" (o frontend já tem esse estado visual pronto no
   `insight_card.dart`).

**Fora de escopo, explicitamente:** árvore de decisão, random forest, SVM,
KNN, redes neurais, deep learning, LLM/IA generativa.

---

## 3. Contrato de resposta que o backend precisa emitir

O frontend já define o contrato em `frontend/lib/models/insights_model.dart`
(mock-first, pronto para swap sem mudar UI). O backend deve produzir exatamente
este formato:

- **`Insight`:** `tipo`, `categoria`, `disciplina?`, `titulo`, `descricao`,
  `numeros` (map), `amostra`, `confianca`, `natureza`, `severidade`, `acao?`,
  `grafico?`, `sessoesEvidencia?`.
- **`InsightAction`:** `tipo`, `label`, `disciplinaId?`, `horarioSugerido?`.
- **`grafico`:** `tipo` (`barras`/`comparacao`/`linha`), `labels`, `valores`,
  `destaqueIndex?`.
- **`sessoesEvidencia`:** lista de `{ data, disciplina?, duracaoMin,
  produtividade }`.
- **`InsightsDashboard`:** período/atualização, dimensões do estudo,
  comparações temporais, experimentos observacionais.
- **`InsightComparison`:** antes, agora, unidade, variação, série (minitendência).
- **`InsightExperiment`:** hipótese, estágio, métrica inicial/atual, amostra,
  confiança.

`amostra` e `confianca` devem vir diretamente do gate de N mínimo (§2.4) —
não são campos decorativos, são o resultado do critério estatístico.

---

## 4. Endpoints a criar

| Rota | Função |
|---|---|
| `GET /api/insights/` | calcula e devolve os insights atuais no contrato acima |
| `POST /api/insights/{id}/feedback` | persiste `InsightFeedback` (útil/rejeitado + motivo) |
| `GET /api/insights/evolucao` (ou equivalente) | alimenta `InsightsDashboard`/aba Evolução |

Novo model sugerido: `InsightFeedback` (aluno, tipo do insight, útil/rejeitado,
motivo, timestamp) — usado para personalização determinística (esconder/rebaixar
padrão que o aluno já marcou como não útil), sem IA.

---

## 5. Mapeamento dos 16 insights (esforço com o dado atual)

| Insight | Dado necessário | Técnica (§2) | Esforço |
|---|---|---|---|
| `melhor_horario` | `inicio` (hora) × `produtividade` | bucket | Baixo |
| `melhor_dia_semana` | `inicio` (dia semana) × `produtividade` | bucket | Baixo |
| `duracao_ideal` | `duracao_realizada` × `produtividade` | polinomial grau 2 | Baixo |
| `vies_estimativa` | `(fim-inicio)` vs `duracao_realizada`, por sessão | correlação | Baixo |
| `tarefas_no_prazo` | `prazo` vs `data_conclusao` (`TarefaDisciplina`) | comparação direta | Baixo |
| `taxa_furo` | `status=CANCELADO` por dia/horário | bucket (taxa) | Baixo/Médio |
| `sequencia_produtiva` | streak ponderado por produtividade alta | adaptar `calcular_streak_atual` | Baixo |
| `cramming` | horas nas 48h antes do evento vinculado | filtro por proximidade | Baixo/Médio |
| `ritmo_disciplina` | sessões/período vs "ritmo esperado" | comparação | Baixo |
| `progresso` | generalizar `comparar_semanas` para outras métricas | comparação | Baixo |
| `foco_sem_interrupcoes` | contagem de interrupções (**campo novo**, §6) | correlação | Médio |
| `equilibrio_metodo` | % leitura vs exercício (**campo novo**, §6) | bucket | Médio |
| `efeito_acao` | produtividade antes/depois de aceitar recomendação (**rastro novo**, §6) | comparação de médias | Médio/Alto |
| `sono_x_rendimento` | horas de sono | correlação | Alto (HealthKit/Health Connect) |
| `tela_antes_sessao` | tempo de tela pré-sessão | correlação | Alto (UsageStatsManager, Android-only) |
| `desgaste` | sessões longas + sono curto + queda de produtividade | composto | Alto (depende de sono; versão reduzida sem sono é Médio) |

---

## 6. Novos campos/models a coletar (ordem de prioridade)

> A captura em si (UI) é responsabilidade do frontend — ver
> `plano-frontend-insights.md`, §3. Aqui vai o que muda no schema/backend.

1. **Energia/disposição pré-sessão** — novo campo (ex.: `energia_inicial`,
   IntegerChoices 1–5) em `SessaoEstudo` ou tabela própria, preenchido ao
   iniciar a sessão. Resolve confundimento entre "estado prévio do aluno" e
   "efeito do horário/duração", hoje misturado dentro de `produtividade`.
   **Prioridade 1**, custo baixo.
2. **Contador de interrupções** — novo campo `interrupcoes` (int, default 0)
   em `SessaoEstudo`, incrementado via o mesmo endpoint que já atualiza
   `duracao_realizada` no Pomodoro. **Prioridade 1**, esforço médio.
3. **Tipo de atividade** — novo campo `tipo_atividade` (choices:
   leitura/exercício/revisão) em `SessaoEstudo`. **Prioridade 2**, esforço médio.
4. **Origem de recomendação** — FK/tag opcional em `SessaoEstudo` apontando
   para o insight que originou a sessão (o frontend já envia
   `disciplinaIdInicial`/`horarioSugerido` ao criar sessão a partir de uma
   ação — falta persistir a origem). **Prioridade 3**, decisão de produto
   sobre atribuição, não só schema.
5. **Sono / tempo de tela** — fora de escopo por ora (permissão de SO,
   esforço alto). Não priorizar agora.

---

## 7. Roadmap sugerido

1. **Fase 1:** `insights_service` cobrindo os 10 insights de esforço
   baixo/baixo-médio (§5) a partir do dado que já existe, com gate de N
   mínimo; expor `GET /api/insights/` no contrato do §3.
2. **Fase 2:** persistir `InsightFeedback` via `POST /api/insights/{id}/feedback`.
3. **Fase 3:** migrações para `energia_inicial`, `interrupcoes`,
   `tipo_atividade`; recalcular `foco_sem_interrupcoes` e `equilibrio_metodo`.
4. **Fase 4:** rastro de origem de recomendação → `efeito_acao`.
5. **Fase 5 (futuro, alto esforço):** integrações de saúde/tela para
   `sono_x_rendimento`, `tela_antes_sessao`, `desgaste` completo.
