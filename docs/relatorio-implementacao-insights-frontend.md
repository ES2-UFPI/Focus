# Relatório de implementação — Módulo "Insights" (frontend)

> Estado do que foi **efetivamente implementado** nesta linha de trabalho, com
> base no **código atual** da branch `feat/insights-perfil-estudo`.
>
> **Natureza:** protótipo **frontend, com dados mockados**. Nenhuma parte usa
> backend, rede, IA, permissão ou integração nativa — por decisão de escopo
> (demonstrar a visão a baixo risco). A ligação com dados reais é fase futura.

---

## 1. Contexto — como chegamos aqui

O trabalho começou avaliando uma funcionalidade de **RAG/IA generativa (Gemini)**
que vinha dando problema (cotas, credencial de staging, citações opacas, saída
mal-formatada, complexidade operacional). A conclusão foi que a dor vinha de
**depender de um provedor com cota** e de **gerar texto**.

A direção pivotou para **análise de dados dos hábitos de estudo** — um módulo de
**Insights** que interpreta o que o aluno já registra e sugere ações, **sem IA
generativa, sem cota, sem provedor externo**. Ficou decidido:

- foco em **gestão de tempo/estudo** (não virar ferramenta de conteúdo);
- **estatística determinística**, não LLM;
- construção **mock-first no frontend** para validar a experiência antes de
  investir no backend.

Também se confirmou que a camada **descritiva** (consistência, streak, metas) já
existe no `dev` (trabalho do Diogo). O módulo de Insights **complementa** essa
base com a camada **diagnóstica/prescritiva**.

---

## 2. O que foi implementado (frontend)

Entregue em **cinco rodadas incrementais** (commits `e6b86f57` → `fbd001d2`).

### 2.1. Painel "Insights"
`frontend/lib/screens/insights_screen.dart`, `StatefulWidget`:
- `SliverAppBar` com gradiente (identidade `AppGradients.reportsHeader`);
- **grid responsivo** de cards (1 coluna no mobile, 2 em telas largas);
- **filtro por categoria** e **filtro por disciplina** (combinados);
- **barra de resumo** com contadores por severidade, tocáveis como **filtro por
  severidade** (combina com categoria/disciplina);
- resumo semanal orientado a decisão, com **"Continue / Ajuste / Teste"**;
- alerta crítico separado dos demais padrões, para não competir visualmente com
  conquistas e observações comuns;
- panorama independente de **tempo, foco, planejamento, consistência e
  recuperação**, sem produzir uma nota geral artificial;
- biblioteca completa de padrões recolhível, mantendo filtros, cards, feedback
  e drill-down como camada de exploração;
- **abas "Insights" / "Evolução"** (ver §2.10);
- estados de **vazio** e de **lista filtrada sem itens**;
- rótulo/menu exibido como **"Insights"**.

### 2.2. Card de insight
`frontend/lib/widgets/insight_card.dart`:
- número-herói + título + descrição + métricas de suporte;
- cor por **severidade** (info/positivo/atenção/crítico);
- **tag colorida da disciplina**;
- badges de **amostra**, **confiança** e **natureza** ("padrão observado");
- estado **"dados insuficientes"** (visual apagado);
- **botão de ação** nos insights acionáveis;
- **controle de feedback 👍/👎** com seletor de motivo;
- **tocar no card abre o detalhe** (§2.9).

### 2.3. Modelo e contrato
`frontend/lib/models/insights_model.dart`:
- `Insight`: `tipo`, `categoria`, `disciplina?`, `titulo`, `descricao`,
  `numeros` (Map), `amostra`, `confianca`, `natureza`, `severidade`, `acao?`,
  **`grafico?`** e **`sessoesEvidencia?`** (novos — alimentam o detalhe);
- `InsightAction`: `tipo`, `label`, `disciplinaId?`, `horarioSugerido?`;
- `grafico`: `tipo` (`barras` / `comparacao` / `linha`), `labels`, `valores`,
  `destaqueIndex?`;
- `sessoesEvidencia`: lista de `{ data, disciplina?, duracaoMin, produtividade }`;
- `InsightsDashboard`: período e atualização, dimensões do estudo, comparações
  temporais e experimentos observacionais;
- `InsightComparison`: antes, agora, unidade, variação e série para minitendência;
- `InsightExperiment`: hipótese, estágio, métrica inicial/atual, amostra e
  confiança;
- `fromJson` tolerante em todos — **alinhado ao contrato de resposta do insight**
  (o backend futuro emite este mesmo formato), para o swap sem mexer na UI.

### 2.4. Dados mockados
`frontend/lib/data/insights_mock.dart` — `getInsightsMock()`, fonte única e
isolada (**ponto de swap** para a API futura). Contém **17 insights** em
**6 categorias** e **4 disciplinas** (+ globais):

- **tempo:** `melhor_horario`, `efeito_acao`;
- **foco:** `duracao_ideal`, `foco_sem_interrupcoes`, `amostra_insuficiente`;
- **planejamento:** `vies_estimativa`, `tarefas_no_prazo`;
- **rotina:** `melhor_dia_semana`, `taxa_furo`, `sequencia_produtiva`,
  `ritmo_disciplina`, `progresso`;
- **saúde:** `sono_x_rendimento`, `tela_antes_sessao`, `desgaste`;
- **método:** `equilibrio_metodo` (teoria × questões);
- disciplinas usadas: **ES2, Cálculo, Física, Banco de Dados**.

Os insights-chave trazem `grafico` + `sessoesEvidencia` para o detalhe; há também
um `getJornadaMock()` e um `getInsightsDashboardMock()` para a aba Evolução e o
resumo semanal. Todos com `natureza: "observacional"`; inclui um item
`confianca: "insuficiente"`.

### 2.5. Feedback do usuário (personalização)
Na `insights_screen.dart`:
- estado local `Map<String, InsightFeedbackState>` (`useful` / `rejected` + motivo);
- **👍** marca como útil; **👎** abre motivos e **oculta/rebaixa** o card;
  possibilidade de **limpar/reverter**;
- comentário no código indicando o destino real:
  `POST /api/insights/{id}/feedback` (modelo `InsightFeedback`), alimentando uma
  personalização **determinística** — sem IA.

### 2.6. Insight → ação (loop prescritivo)
- insights acionáveis exibem botão que abre o **fluxo real de criar sessão**;
- `frontend/lib/screens/criar_sessao_screen.dart` recebeu **parâmetros opcionais
  aditivos** (`disciplinaIdInicial`, `horarioSugerido`) — default nulo, então o
  comportamento anterior é preservado; quando vêm preenchidos, **pré-selecionam a
  disciplina e sugerem o horário** (manhã/tarde/noite);
- ações curadas (agendar/reagendar) só nos insights com próximo passo óbvio.

### 2.7. Ajustes → "Sincronização e Dados"
`frontend/lib/screens/configuracoes_screen.dart` ganhou uma seção nova (no padrão
Material existente da tela), que **justifica de onde viriam os dados de saúde**:
- **Google Fit / Health Connect**
- **Mi Fitness (Xiaomi)**
- **Samsung Health**
- **Apple Saúde (HealthKit)**
- **Uso do celular / Tempo de tela**

Cada fonte tem "Conectar" **mock** (estado local / placeholder). É o que dá
lastro visual ao insight de sono e ao de tempo de tela.

### 2.8. Navegação
- novo valor no enum `AppPage` (`providers/app_shell_provider.dart`) — nome
  interno `perfil`, **rótulo visível "Insights"**;
- item na `AppSidebar` e render no shell (`app_scaffold.dart`).

### 2.9. Detalhe do insight (drill-down + "a prova")
`frontend/lib/screens/insight_detail_screen.dart` (novo):
- aberto ao tocar num card; recebe o `Insight`;
- **gráfico** que sustenta o insight com **`fl_chart`** (mesmo estilo da
  `consistencia_screen`), no tipo indicado por `grafico` (`barras`/`comparacao`/
  `linha`), destacando o ponto relevante pela cor da severidade;
- lista de **sessões de evidência** (`sessoesEvidencia`) + amostra + confiança;
- recomendação + **botão de ação** (reusa `acao`) + **feedback**;
- insight sem `grafico` degrada graciosamente (mostra números/descrição).

### 2.10. Resumo semanal, Evolução e experimentos
- aba **"Insights"**: contexto da semana, alerta prioritário, plano
  **Continue / Ajuste / Teste**, panorama por dimensão e biblioteca recolhível;
- aba **"Evolução"**: comparações **antes × agora** com minitendências, ciclos
  **padrão → ação → teste → resultado**, leitura por disciplina e timeline
  cronológica complementar;
- confiança e severidade passaram a aparecer diretamente nos cards completos,
  sem exigir abertura do detalhe.

---

## 3. Mock × real — o que é de verdade e o que é encenação

| Área | Situação |
|---|---|
| Painel, cards, filtros, resumo, foco da semana, navegação | **Real** (UI funcional) |
| Detalhe do insight (gráfico + evidências) | **Real na UI**, com **dados mock** |
| Aba Evolução (timeline) | **Real na UI**, com **dados mock** |
| Insights exibidos | **Mock** (`getInsightsMock()`), isolado para swap |
| Feedback 👍/👎 | **Real na UI**, mas **estado local** (não persiste) |
| Ação "agendar" → criar sessão pré-preenchida | **Real** (abre o fluxo verdadeiro) |
| Integrações de saúde em Ajustes | **Mock** (nenhuma conexão real) |
| Dados de sono / tempo de tela | **Mock** (sem HealthKit/Health Connect/UsageStats) |

---

## 4. O que NÃO foi implementado (consciente / fase futura)

- **Backend inteiro do módulo:** `insights_service`, endpoint que emite o
  contrato, seed sintético e testes — **não feitos** (protótipo é só frontend).
- **Persistência de feedback** (`InsightFeedback`) — só estado local hoje.
- **Gráficos e jornada a partir de dados reais** — hoje `grafico`,
  `sessoesEvidencia` e a timeline da Evolução vêm do mock.
- **Integração real de saúde/atividade:** Health Connect / HealthKit / Mi Fitness
  / Google Fit / `UsageStatsManager` (tempo de tela) — a de tela é **Android-only**
  e ambas exigem permissão/consentimento.
- **Motor de experimento _n-of-1_** (a "prova" causal) — planejado, não iniciado;
  o detalhe (§2.9) já prepara o terreno visual para ele.
- **Coleta de dado extra** que dá robustez (interrupções/pausas do Pomodoro,
  `inicio_real`, energia inicial, `tipo_atividade`, tags de distração, nota) —
  mapeada, não implementada.
- **Vitrine de "fontes de dados" dentro do painel** (proposta na rodada 4):
  **não** foi feita — a conexão de saúde ficou **apenas em Ajustes** (§2.7).
- **Ideias exploradas e descartadas/pausadas:** biblioteca semântica de
  materiais, canvas de anotação (Excalidraw-like), planejador adaptativo,
  repetição espaçada, projeção de nota — discutidas mas **fora** deste módulo.

---

## 5. Documentos e registro

- Os **prompts de execução** (rodadas 1–5) foram artefatos descartáveis e foram
  **removidos após a implementação**. Este relatório é o **registro** do que ficou.
- O **contrato de resposta do insight** (o formato que o backend futuro deve
  emitir) está descrito em **§2.3**, incluindo os campos `categoria`, `disciplina`,
  `acao`, `grafico` e `sessoesEvidencia`.

---

## 6. Próximo passo natural

**Fase de dados (backend):** implementar o `insights_service` calculando os
insights da Fase 1 a partir dos dados reais (produtividade × contexto, viés de
estimativa, cancelamento, cramming), expor o endpoint no **contrato do insight
(§2.3)** e trocar `getInsightsMock()` por `ApiService.getInsights()` — **sem
alterar a UI**, graças ao mock isolado. Em seguida: `InsightFeedback`, gráficos/
evidências vindos de sessões reais, coleta extra e as integrações reais de saúde.

---

## 7. Balanço

Em cinco rodadas mock-first, o app saiu de um CRUD + camada descritiva para um
**módulo de Insights** que **interpreta hábitos, mostra a evidência por trás de
cada padrão, recomenda ações, aprende com o feedback do aluno, acompanha a
evolução e declara suas fontes de dados** — tudo determinístico, sem IA
generativa e sem as dores do RAG. É um protótipo de frontend pronto para demo, com
o caminho de dados reais já contratualizado e isolado para plugar depois.
