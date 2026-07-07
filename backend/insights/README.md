# App `insights` — backend do módulo de Insights

Implementa o backend do módulo de Insights (perfil de estudo/produtividade),
antes 100% mock no frontend. Contrato e roadmap em
[`docs/plano-backend-insights.md`](../../docs/plano-backend-insights.md).

## Endpoints

| Rota | Método | Descrição |
|---|---|---|
| `/api/insights/` | GET | Insights calculados do aluno autenticado |
| `/api/insights/evolucao/` | GET | Panorama/comparações (`InsightsDashboard`) da aba Evolução |
| `/api/insights/<id>/feedback/` | POST | Persiste 👍/👎 do aluno (`{"useful": bool, "reason": "..."}`) |

Todos exigem autenticação por token (aluno logado).

## Como funciona

- `services.py` (`InsightsService`) lê os dados já coletados
  (`SessaoEstudo`, `BlocoPomodoro`, `TarefaDisciplina`, `EventoAcademico`) numa
  janela de 42 dias e calcula os insights. A **produtividade de uma sessão** é a
  média das avaliações dos seus `BlocoPomodoro`.
- `statistics.py` traz correlação (Pearson/Spearman) e regressão quadratica em
  Python puro — sem numpy/scipy (mantém o `requirements.txt` enxuto). Nada de
  ML/LLM, conforme decisão do produto.
- **Gate de N mínimo**: todo insight agregado só aparece com amostra suficiente
  (`MIN_AMOSTRA = 5`); `confianca` = `alta` (≥15), `media` (≥5) ou
  `insuficiente`. Sem dados, retorna o insight `amostra_insuficiente`.
- `InsightFeedback` (`models.py`) guarda o feedback e a personalização é
  determinística: insight marcado como não útil é ocultado; útil sobe ao topo.

## Insights implementados

Fase 1/3 (a partir do dado que já existe):
`melhor_horario`, `melhor_dia_semana`, `duracao_ideal`, `foco_sem_interrupcoes`,
`vies_estimativa`, `tarefas_no_prazo`, `taxa_furo`, `sequencia_produtiva`,
`cramming`, `ritmo_disciplina`, `progresso`, `equilibrio_metodo`.

## Pendências (fases seguintes do roadmap)

- **Fase 4 — origem da recomendação + `efeito_acao` + jornada.** Requer rastrear
  qual insight originou uma sessão (FK/tag em `SessaoEstudo`). É uma decisão de
  produto sobre atribuição (ver plano). Enquanto não existe, `obter_evolucao`
  devolve `experimentos: []` e o frontend `fetchJourney()` retorna vazio.
- **Fase 5 — fora de escopo (esforço alto, dependência de SO).** Os insights
  `sono_x_rendimento`, `tela_antes_sessao` e `desgaste` completo dependem de
  integração com HealthKit/Health Connect e UsageStatsManager (permissões de
  sistema). Devem virar issue própria quando houver decisão de produto — não são
  calculados aqui.
