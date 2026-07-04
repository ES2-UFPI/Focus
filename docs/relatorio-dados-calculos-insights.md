# Relatório de dados e cálculos — módulo "Insights" (backend)

> Mapeamento **detalhado e verificado no código** (não no mock) do que a
> aplicação **coleta de verdade** hoje, do que **não coleta**, do que já é
> **calculado de verdade** e do que **ainda não é calculado** — para os 16
> tipos de insight hoje exibidos via `frontend/lib/data/insights_mock.dart`.
>
> Complementa o [`relatorio-implementacao-insights-frontend.md`](relatorio-implementacao-insights-frontend.md)
> (que descreve a UI) com o lado de dados/backend.

---

## 1. Objetivo

Responder, campo a campo e cálculo a cálculo: **de onde viria cada número que
aparece hoje mockado na tela de Insights, se o dado já existe no banco, e se
já existe algum código que o calcula.** Dados de saúde (sono, tempo de tela)
são tratados à parte porque dependem de permissão de SO/HealthKit e já eram
sabidamente mock — o foco aqui é tudo o que **não** depende disso.

---

## 2. Dados coletados hoje (modelo a modelo)

### 2.1 `Aluno` — `backend/alunos/models.py`

| Campo | Tipo | Observação |
|---|---|---|
| `id` | UUID | PK |
| `nome` | CharField(255) | |
| `email` | EmailField, único | `USERNAME_FIELD` |
| `data_nascimento` | DateField, opcional | |
| `data_cadastro` | DateTimeField, auto | |
| `username` | CharField, único, opcional | espelha o e-mail se vazio |
| + campos padrão de `AbstractUser` | (senha, `is_active`, etc.) | |

**Não existe:** preferência de horário de estudo, sono habitual, meta de
foco, onboarding/perfil comportamental — nada disso é perguntado ao aluno.

### 2.2 `Disciplina` — `backend/disciplinas/models.py`

| Campo | Tipo | Observação |
|---|---|---|
| `id` | UUID | PK |
| `aluno` | FK → Aluno | |
| `nome` | CharField(255) | |
| `codigo` | CharField(50), opcional | |
| `descricao` | TextField, opcional | |
| `cor` | CharField, default `#2196F3` | usado só na UI |
| `meta_horas_semanais` | DecimalField(5,2), default 0 | **já usado** no cálculo de metas |
| `ativo` | BooleanField, default True | |
| `data_criacao` | DateTimeField, auto | |

### 2.3 `EventoAcademico` — `backend/eventos_academicos/models.py`

| Campo | Tipo | Observação |
|---|---|---|
| `id` | UUID | PK |
| `disciplina` | FK → Disciplina | |
| `titulo` | CharField(255) | |
| `tipo` | choices: `PROVA`, `TRABALHO`, `SEMINARIO`, `APRESENTACAO`, `OUTRO` | |
| `descricao` | TextField, opcional | |
| `data_evento` | DateField | |
| `hora_inicio` / `hora_fim` | TimeField, opcionais | |
| `concluido` | BooleanField, default False | |
| `data_conclusao` | DateField, opcional | |
| `data_criacao` | DateTimeField, auto | |
| `dias_restantes` (`@property`) | int, **calculado, não persistido** | `data_evento - hoje` |
| `urgencia` (`@property`) | `ATRASADO`/`ALTA`/`MEDIA`/`BAIXA`, **calculado** | por faixa de `dias_restantes` (≤0 / ≤3 / ≤7 / >7) |

**Não existe:** nenhum campo de "cancelamento"/"não compareceu" no evento em
si — só a sessão de estudo tem status de cancelamento (§2.5).

### 2.4 `TarefaDisciplina` — `backend/tarefas_disciplina/models.py`

| Campo | Tipo | Observação |
|---|---|---|
| `id` | UUID | PK |
| `disciplina` | FK → Disciplina | |
| `evento` | FK → EventoAcademico, opcional | vínculo opcional a uma prova/trabalho |
| `titulo` | CharField(255) | |
| `descricao` | TextField, opcional | |
| `prazo` | DateTimeField | |
| `concluida` | BooleanField, default False | |
| `data_conclusao` | DateTimeField, opcional | |
| `prioridade` | choices: `BAIXA`, `MEDIA`, `ALTA` | |

**Não existe:** tempo estimado para a tarefa, nem qualquer campo de "atraso
registrado" — só dá pra derivar comparando `prazo` com `data_conclusao` na
hora da leitura.

### 2.5 `SessaoEstudo` — `backend/sessao_estudo/models.py`

| Campo | Tipo | Observação |
|---|---|---|
| `id` | UUID | PK |
| `disciplina` | FK → Disciplina | |
| `evento_academico` | FK → EventoAcademico, opcional | liga a sessão a uma prova/trabalho específico |
| `inicio` / `fim` | DateTimeField | **horário planejado no agendamento** — não é o horário real de execução |
| `duracao_realizada` | PositiveIntegerField (min), default 0 | ver nota abaixo — **é medido, não estimado** |
| `status` | choices: `AGENDADO`, `EM_ANDAMENTO`, `CONCLUIDO`, `CANCELADO` | |
| `descricao` | TextField, opcional | |
| `data_criacao` | DateTimeField, auto | |

**Nota importante sobre `duracao_realizada`:** não é digitado manualmente
pelo aluno. Em `frontend/lib/providers/pomodoro_provider.dart`
(`_persistirSessaoConcluida`), cada ciclo de foco do Pomodoro concluído soma
seus minutos a `duracao_realizada` via `PATCH`, **sem alterar `inicio`/`fim`
da sessão**. Ou seja: `inicio`/`fim` = janela **planejada**;
`duracao_realizada` = tempo de foco **medido** pelo timer. Essa dupla já
existe pronta para qualquer comparação planejado × realizado.

**Não existe:** contagem de interrupções/pausas, tipo de atividade (leitura
vs. exercício vs. revisão), nota subjetiva de energia/disposição antes da
sessão, tempo de tela antes de começar.

### 2.6 `FeedbackSessaoEstudo` — `backend/feedback_sessao_estudo/models.py`

| Campo | Tipo | Observação |
|---|---|---|
| `id` | UUID | PK |
| `sessao_estudo` | **OneToOne** → SessaoEstudo | um feedback por sessão |
| `produtividade` | IntegerChoices 1–5 (`Muito Baixa`…`Muito Alta`) | **autodeclarado pelo aluno**, não inferido de nenhum outro dado |
| `descricao` | TextField, opcional | "o que atrapalhou ou ajudou no foco" — texto livre, não estruturado |
| `hora_registro` | DateTimeField, auto | |

**Ponto-chave sobre "produtividade":** todo insight do mock que fala em
"produtividade média" (melhor horário, duração ideal, sono × rendimento
etc.) está, na prática, tirando a **média de uma opinião subjetiva de 1 a 5
que o próprio aluno atribuiu à sessão** — não é uma métrica objetiva
calculada a partir de comportamento (tempo de foco, conclusão de tarefas
etc.). Isso é importante para calibrar expectativa: os insights de
"produtividade" são baseados em autoavaliação, com todos os vieses que isso
implica (dia ruim, humor, expectativa), e não em uma medição direta.

### 2.7 Endpoints REST que já existem hoje

Registrados em `backend/focus_api/urls.py`:

| Rota | Recurso |
|---|---|
| `/api/alunos/` | CRUD `Aluno` |
| `/api/disciplinas/` | CRUD `Disciplina` |
| `/api/tarefas-disciplina/` | CRUD `TarefaDisciplina` — **CRUD puro, sem nenhuma action de análise** |
| `/api/eventos-academicos/` | CRUD `EventoAcademico` + `GET .../proximos/` (eventos nos próximos 7 dias) |
| `/api/sessoes-estudo/` | CRUD `SessaoEstudo` + ações abaixo |
| `/api/feedbacks-sessao/` | CRUD `FeedbackSessaoEstudo` — **CRUD puro** |
| `/api/materiais-estudo/` | CRUD de materiais (fora do escopo de insights) |

Ações extras em `SessaoEstudoViewSet` (`backend/sessao_estudo/views.py`):

| Rota | O que retorna |
|---|---|
| `GET /api/sessoes-estudo/semana_atual/` | sessões concluídas da semana |
| `GET /api/sessoes-estudo/dashboard/` | `ConsistenciaService.obter_dashboard_consistencia()` — ver §4 |
| `GET /api/sessoes-estudo/ranking/` | ranking de disciplinas por horas estudadas |
| `GET /api/sessoes-estudo/disciplina_negligenciada/` | disciplina com maior déficit de meta |
| `GET /api/sessoes-estudo/disciplina/<id>/desempenho/` | desempenho de uma disciplina |

Além disso, `AgendaView` (`backend/eventos_academicos/views.py`, registrada
em `GET /api/agenda/` — ver `backend/focus_api/urls.py:29`) já faz uma
leitura combinada de eventos + sessões e **gera recomendações simples
baseadas em regra**: se um evento do tipo prova/trabalho/seminário/
apresentação está a ≤3 dias e não há nenhuma sessão futura vinculada, ou a
≤7 dias com no máximo 1 sessão, ela produz um texto de recomendação. É o
único ponto do backend hoje que já gera "recomendação acionável" a partir de
dado real — mesmo padrão que o módulo de Insights quer generalizar.

**Não existe hoje:** nenhuma rota `/api/insights/` nem qualquer endpoint que
devolva os 16 tipos de insight do mock nesse formato.

---

## 3. Dados que NÃO são coletados hoje

| Dado | Por quê falta | Observação |
|---|---|---|
| Sono (horas, qualidade) | Sem modelo/campo algum | Exigiria HealthKit/Health Connect + permissão explícita — combinado que fica mock por ora |
| Tempo de tela antes da sessão | Sem modelo/campo algum | Exigiria `UsageStatsManager` (Android-only) + permissão — combinado que fica mock por ora |
| Interrupções/pausas durante a sessão | Sem campo em `SessaoEstudo` | Precisaria de um contador novo + captura na UI (Pomodoro) |
| Tipo de atividade (leitura vs. exercício vs. revisão) | Sem campo em `SessaoEstudo`/`FeedbackSessaoEstudo` | Precisaria de um campo de categoria simples |
| Duração **planejada** por sessão como conceito explícito | **Falso alarme — já existe** | É `fim - inicio`; só não tem nome próprio no modelo, mas o dado está lá (ver §2.5) |
| Energia/disposição antes da sessão | Não perguntado | Só existe o `descricao` de texto livre no feedback, não estruturado |
| Aceitação de recomendação (o aluno seguiu a sugestão?) | Nenhuma tabela liga uma `InsightAction`/recomendação a uma sessão criada por causa dela | Precisaria de uma FK ou tag "origem: recomendação X" na sessão |
| Cancelamento/"furo" vinculado a horário específico do evento | `EventoAcademico` não tem status de comparecimento; só `SessaoEstudo.status` tem `CANCELADO` | Dá pra aproximar cruzando `SessaoEstudo.status=CANCELADO` com `inicio` (dia/hora), mas não há um conceito de "furo" no evento em si |
| Preferências do aluno (horário preferido, sono habitual, metas pessoais) | Sem onboarding/perfil | `Aluno` só tem dado cadastral |

---

## 4. Cálculos que já existem hoje (dados reais)

Tudo abaixo está implementado e testado em `backend/services/consistencia_service.py`
(`ConsistenciaService`), consumido por `/api/sessoes-estudo/dashboard/` e
rotas irmãs. Nenhum destes 15 métodos usa produtividade — são só
frequência/horas/metas:

| Método | O que calcula | Fórmula/regra |
|---|---|---|
| `obter_sessoes_semana` | sessões `CONCLUIDO` da semana corrente (cacheado por requisição) | filtro `inicio` dentro da semana (segunda 00:00 → próxima segunda) |
| `obter_sessoes_intervalo` | sessões concluídas em qualquer intervalo | usado para olhar semanas passadas |
| `calcular_horas_estudadas` | horas **realizadas** na semana | soma de `duracao_realizada` |
| `calcular_horas_planejadas` | horas **planejadas** na semana | soma de `(fim - inicio)` — **já é exatamente o "planejado" que faltaria para viés de estimativa, só que hoje só é somado no agregado da semana, não comparado sessão a sessão** |
| `calcular_horas_estudadas_disciplina` / `calcular_horas_planejadas_disciplina` | as duas anteriores, por disciplina | |
| `calcular_sessoes_concluidas` | contagem de sessões concluídas na semana | |
| `calcular_consistencia_por_dia` | quais dias da semana tiveram estudo | booleano por dia + contagem |
| `calcular_frequencia_semanal` | % de dias estudados na semana | `dias_estudados / 7 * 100` |
| `calcular_streak_atual` | sequência atual de dias consecutivos com estudo | conta pra trás a partir de hoje/ontem — **limitado à janela da semana corrente** (não olha além dos 7 dias atuais) |
| `calcular_meta_disciplinas` | por disciplina: horas estudadas vs. `meta_horas_semanais`, atingiu ou não | |
| `calcular_semanas_consecutivas` | quantas semanas seguidas todas as metas foram batidas | itera até 52 semanas para trás |
| `calcular_indice_consistencia` | **score composto de 0–100** | `40% frequência + 40% % de metas atingidas + 20% streak (streak/7, capado em 100)` |
| `obter_desempenho_disciplina` | horas, sessões, % da meta, se atingiu, para 1 disciplina | |
| `obter_ranking_disciplinas` | disciplinas ordenadas por horas estudadas | |
| `obter_disciplina_mais_negligenciada` | disciplina com maior déficit vs. meta | ordena as que não bateram meta pela diferença |
| `calcular_distribuicao_disciplinas` | % de horas por disciplina (para gráfico de pizza) | |
| `detectar_baixa_consistencia` | alertas por regra fixa | frequência <60%, meta não batida, streak <3, índice <50 |
| `comparar_semanas` | semana atual vs. anterior | diferença de sessões e horas |
| `obter_evolucao_consistencia` | histórico de 12 semanas | índice simplificado por semana: `min(horas/10*100, 100)` |
| `obter_dashboard_consistencia` | agrega **todos** os anteriores num payload único | é o que `/dashboard/` devolve |

Fora do `ConsistenciaService`, o único outro cálculo real de "recomendação"
é o de `AgendaView` descrito no §2.7 (regra por proximidade de evento ×
contagem de sessões futuras).

**Resumo:** hoje o backend calcula bem **consistência/frequência/metas**,
mas **nunca cruza isso com produtividade**, nunca olha **horário do dia**
ou **dia da semana** como variável, e nunca compara **sessão a sessão**
planejado vs. realizado (só no agregado semanal).

---

## 5. Cálculos que NÃO existem — mapeados aos 16 insights do mock

| Insight (`tipo` no mock) | Dado necessário | Coletado? | Calculado hoje? | Esforço para implementar |
|---|---|---|---|---|
| `melhor_horario` | `inicio` (hora) × `produtividade` | ✅ Sim | ❌ Não | **Baixo** — agrupar por faixa de hora, cruzar com feedback |
| `melhor_dia_semana` | `inicio` (dia da semana) × `produtividade` | ✅ Sim | ❌ Não | **Baixo** — mesma ideia, agrupado por `weekday()` |
| `duracao_ideal` | `duracao_realizada` × `produtividade` | ✅ Sim | ❌ Não | **Baixo** — bucketizar duração e ver onde a produtividade cai |
| `foco_sem_interrupcoes` | contagem de interrupções por sessão | ❌ Não | ❌ Não | **Médio** — precisa de campo novo + captura na UI |
| `vies_estimativa` | `(fim-inicio)` vs. `duracao_realizada` | ✅ Sim (e já agregado por semana em `calcular_horas_planejadas`) | ⚠️ Parcial (só agregado, não por sessão/disciplina) | **Baixo** — comparar por sessão/disciplina, não só o total da semana |
| `tarefas_no_prazo` | `prazo` vs. `data_conclusao` de `TarefaDisciplina` | ✅ Sim | ❌ Não (CRUD puro) | **Baixo** — comparação direta, sem cruzar tabelas |
| `taxa_furo` | `SessaoEstudo.status=CANCELADO` agrupado por dia/horário | ✅ Sim | ❌ Não | **Baixo/Médio** — agrupar cancelamentos por dia da semana + horário |
| `sequencia_produtiva` | streak de sessões com produtividade alta | ⚠️ Streak existe, mas não ponderado por produtividade | ⚠️ Parcial | **Baixo** — adaptar `calcular_streak_atual` para exigir produtividade ≥ X |
| `cramming` | horas estudadas nas 48h antes de `EventoAcademico.data_evento` vs. total antes do evento | ✅ Sim | ❌ Não | **Baixo/Médio** — filtrar sessões por proximidade da data do evento vinculado |
| `sono_x_rendimento` | horas de sono | ❌ Não (fora de escopo combinado) | ❌ Não | **Alto** — HealthKit/Health Connect + permissão |
| `ritmo_disciplina` | sessões por disciplina no período vs. "ritmo esperado" | ✅ Sim | ⚠️ Parcial (`meta_horas_semanais` existe, mas não há noção de "ritmo em nº de sessões") | **Baixo** — definir "mínimo sugerido" e comparar contagem |
| `tela_antes_sessao` | tempo de tela antes da sessão | ❌ Não (fora de escopo combinado) | ❌ Não | **Alto** — `UsageStatsManager`, Android-only, permissão |
| `equilibrio_metodo` | % leitura vs. % exercício por sessão | ❌ Não | ❌ Não | **Médio** — precisa de campo novo de categoria |
| `efeito_acao` | produtividade antes/depois de aceitar uma recomendação | ❌ Não (sem rastro de "aceitou recomendação X") | ❌ Não | **Médio/Alto** — decisão de produto sobre como marcar/atribuir "antes vs. depois" |
| `progresso` | comparação de uma métrica específica entre dois períodos | ⚠️ `comparar_semanas` existe para horas/sessões, mas não para taxa de cancelamento específica | ⚠️ Parcial | **Baixo** — generalizar `comparar_semanas` para outras métricas |
| `desgaste` | sessões longas em sequência + sono curto + queda de produtividade | ❌ Não (depende de sono) | ❌ Não | **Alto** (por depender de sono) — sem sono, dá pra fazer uma versão reduzida só com duração+produtividade |

**Legenda de esforço:** Baixo = só escrever a query/serviço, nenhuma
migração de banco. Médio = 1 campo novo simples + pequena mudança de UI.
Alto = integração externa com permissão de SO, ou decisão de produto não
trivial sobre atribuição causal.

---

## 6. Síntese

- O backend coleta, de verdade: sessões de estudo (com horário planejado e
  duração real medida pelo Pomodoro), uma nota de produtividade autodeclarada
  de 1 a 5 por sessão, eventos acadêmicos com data/tipo, tarefas com prazo, e
  metas de horas por disciplina.
- Já existe um serviço real e testado (`ConsistenciaService`) cobrindo
  frequência, horas, metas, streak, ranking, distribuição e um índice
  composto — mas **nunca envolvendo produtividade, horário do dia ou dia da
  semana**.
- **10 dos 16 insights do mock** dependem só de dado que **já existe** e só
  falta escrever a query/serviço (esforço baixo a médio).
- **3 insights** (`sono_x_rendimento`, `tela_antes_sessao`, `desgaste`)
  dependem de integração de saúde/uso de tela — combinado que ficam mock por
  ora.
- **3 insights** (`foco_sem_interrupcoes`, `equilibrio_metodo`, `efeito_acao`)
  precisam de um campo novo simples ou de uma decisão de produto sobre
  atribuição causal — nenhum deles exige integração externa.
- Não existe endpoint `/api/insights/` hoje — a tela de Insights continua
  100% alimentada por `insights_mock.dart`.
