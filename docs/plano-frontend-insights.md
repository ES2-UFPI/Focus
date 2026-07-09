# Plano de desenvolvimento — Frontend do módulo Insights

> Compilado a partir de `relatorio-implementacao-insights-frontend.md`,
> `relatorio-dados-calculos-insights.md` e `test.md`. Serve de base para as
> mudanças de frontend necessárias — tanto para plugar no backend real quanto
> para coletar os dados novos que a análise estatística precisa.

---

## 0. Status da implementação (05/07/2026)

Legenda: **concluído** significa UI, transporte e persistência cobertos;
**parcial** significa que a base existe, mas ainda depende de outro contrato;
**bloqueado** significa que o backend necessário ainda não existe ou que falta
uma decisão de produto.

### Concluído nesta rodada

- **Energia/disposição pré-sessão:** prompt opcional de 1–5 exibido antes do
  primeiro ciclo de foco da sessão, com ação "Agora não". O valor acompanha a
  sessão e é persistido em `energia_inicial`. O modal usa superfície clara,
  textos de alto contraste e grade responsiva (cinco ou três colunas) para
  manter números e rótulos legíveis. Um controle permanente mostra
  "Informar energia" ou a nota atual e permite reabrir a pergunta antes do
  foco. Ao selecionar uma sessão, o primeiro início sempre pede a confirmação
  da energia; pausas e retomadas do mesmo ciclo não repetem o prompt.
- **Contador de interrupções:** botão no Pomodoro, habilitado depois que o foco
  começa, acumula tanto por bloco quanto por sessão. O total da sessão segue no
  mesmo `PATCH` de `duracao_realizada`; o valor do bloco é salvo no respectivo
  `BlocoPomodoro`.
- **Produtividade por bloco:** ao término natural de cada ciclo de foco, abre
  o prompt opcional "Como foi seu foco neste bloco?" em escala 1–5. A resposta
  é de um toque; fechar ou usar "Agora não" mantém `produtividade = null`.
  Pausar/retomar não abre o prompt. Pular também pergunta: responder promove o
  bloco para `ENCERRADO_ANTECIPADAMENTE`; fechar ou usar "Não responder e
  descartar bloco" mantém o registro `INCOMPLETO`, sem produtividade. Nos dois
  casos, a duração efetivamente transcorrida é preservada e o ciclo não soma
  os 25 minutos integrais como estudados.
- **Tipo de atividade:** chips opcionais de leitura/exercício/revisão na criação
  e edição de sessão, persistidos em `tipo_atividade`.
- **Contrato mínimo de persistência:** foram adicionados os três campos em
  `SessaoEstudo`, no serializer, na resposta da Agenda e na migration
  `0003_sessaoestudo_dados_insights.py`. Isso foi necessário para os novos
  controles não apenas parecerem funcionais, mas realmente coletarem dados.
- **Histórico por ciclo:** o model `BlocoPomodoro`, a rota
  `POST /api/blocos-pomodoro/`, o `PATCH /api/blocos-pomodoro/{id}/` e a
  migrations `0004_blocopomodoro.py` e
  `0005_bloco_encerrado_antecipadamente.py` guardam sessão, número do ciclo,
  início/fim, duração planejada/real, interrupções, status e produtividade
  opcional. O model preexistente `FeedbackSessaoEstudo` permanece como
  avaliação global 1:1 da sessão e não é sobrescrito pelos ciclos.
- **Preservação na edição:** energia, interrupções e tipo de atividade voltam
  nos modelos do Flutter e não são apagados ao editar uma sessão existente.
- **Validação:** `flutter analyze` sem avisos; 60 testes Flutter e os 114
  testes do backend passaram (incluindo 49 do app `sessao_estudo`).
  `flutter build web`, `manage.py check` e
  `makemigrations --check --dry-run` também passaram.

### Parcial

- **Camada de serviço de Insights:** `InsightsService` já isola a UI, e a tela
  já possui carregamento/erro/retry, mas seus métodos ainda retornam os mocks.
  Não foi feita uma troca falsa para HTTP porque as rotas correspondentes não
  existem no backend atual.
- **Gráficos, evidências e Evolução:** os modelos e componentes estão prontos
  para desserializar dados reais, mas continuam alimentados por mock.

### Não implementado / bloqueado

- **`GET /api/insights/`, evolução e feedback persistente:** o backend ainda
  não possui as rotas nem o model `InsightFeedback`. Portanto, o painel
  continua mock-first e o 👍/👎 continua apenas no estado da tela.
- **Origem da recomendação:** não implementada. Ainda é preciso decidir se a
  atribuição será pelo ID de uma ocorrência calculada, pelo tipo do insight ou
  por uma entidade de recomendação persistida — decisões que mudam o schema e
  o cálculo de `efeito_acao`.
- **Saúde/sono/tempo de tela e motor _n-of-1_:** permanecem fora de escopo,
  conforme §4.

---

## 1. Estado atual (protótipo mock-first, cinco rodadas incrementais)

Já implementado e funcional na UI (dados mock, decisão consciente de escopo):

- **Painel** (`insights_screen.dart`): grid responsivo, filtro por
  categoria/disciplina/severidade, resumo semanal com plano
  "Continue/Ajuste/Teste", abas **Insights**/**Evolução**.
- **Card de insight** (`insight_card.dart`): severidade, tag de disciplina,
  badges de amostra/confiança/natureza, estado "dados insuficientes", botão
  de ação, feedback 👍/👎, abre detalhe ao tocar.
- **Modelo/contrato** (`insights_model.dart`): `Insight`, `InsightAction`,
  `grafico`, `sessoesEvidencia`, `InsightsDashboard`, `InsightComparison`,
  `InsightExperiment` — `fromJson` tolerante, pronto para o backend real
  emitir o mesmo formato sem mudar UI (ver `plano-backend-insights.md`, §3).
- **Dados mock** (`insights_mock.dart`): 17 insights, 6 categorias, 4
  disciplinas — único ponto de swap para a API futura.
- **Feedback do usuário:** 👍/👎 com motivo, oculta/rebaixa card — hoje só
  estado local (`Map<String, InsightFeedbackState>`), não persiste.
- **Insight → ação:** botão que abre `criar_sessao_screen.dart` já recebendo
  `disciplinaIdInicial`/`horarioSugerido` (parâmetros opcionais aditivos, não
  quebram o fluxo antigo).
- **Ajustes → "Sincronização e Dados":** cards mock para Google Fit/Health
  Connect, Mi Fitness, Samsung Health, Apple Saúde, tempo de tela — dá lastro
  visual aos insights de sono/tela, sem conexão real.
- **Detalhe do insight** (`insight_detail_screen.dart`): gráfico via
  `fl_chart`, lista de sessões de evidência, recomendação + ação + feedback.
- **Evolução:** comparações antes×agora, ciclo padrão→ação→teste→resultado.

---

## 2. O que falta para plugar no backend real (sem redesenhar UI)

1. **Bloqueado pelo backend:** trocar `getInsightsMock()` por
   `InsightsService.fetchInsights()` via HTTP quando `GET /api/insights/`
   existir. O contrato já foi desenhado para isso (`fromJson` tolerante).
2. **Bloqueado pelo backend:** persistir feedback com
   `POST /api/insights/{id}/feedback`; hoje o método da camada de serviço ainda
   é um _no-op_ e o estado visível é local.
3. **Bloqueado pelo backend:** alimentar `grafico`, `sessoesEvidencia`,
   dashboard e timeline da aba Evolução com dado real.
4. **Frontend concluído:** card e detalhe já renderizam
   `amostra`/`confianca`/estado "dados insuficientes". Falta o backend popular
   esses campos a partir do gate de N mínimo.

---

## 3. Campos novos a coletar (o que falta capturar na UI)

Prioridade definida por valor estatístico ÷ esforço (ver `test.md`,
"Priorização de novos dados a coletar"):

### Prioridade 1
- **[Concluído] Energia/disposição pré-sessão:** prompt rápido ao *iniciar* a
  sessão (não ao concluir), com escala 1–5 e opção de ignorar.
  Sem isso, hoje é impossível saber se uma sessão boa foi efeito do
  horário/duração ou porque o aluno já estava bem antes de começar.
- **[Concluído] Contador de interrupções:** botão simples dentro do timer do
  Pomodoro
  (`pomodoro_provider.dart`) que incrementa um contador por sessão, enviado
  junto com `duracao_realizada` no mesmo `PATCH` que já existe em
  `_persistirSessaoConcluida`.
- **[Concluído] Produtividade por ciclo Pomodoro:** escala opcional 1–5 após
  cada término natural ou ação de pular, persistida no `BlocoPomodoro`; pausa
  manual não gera avaliação. No ciclo pulado, responder gera
  `ENCERRADO_ANTECIPADAMENTE`; não responder mantém `INCOMPLETO`.

### Prioridade 2
- **[Concluído] Tipo de atividade:** seletor simples (chips:
  leitura/exercício/revisão)
  ao criar ou iniciar a sessão.

### Prioridade 3 (decisão de produto, não só UI)
- **[Bloqueado por decisão] Origem de recomendação:** quando a sessão é criada
  a partir do botão de ação de um insight (fluxo já existe, §1), marcar/enviar
  que essa sessão "nasceu" daquela recomendação — fecha o loop necessário para
  `efeito_acao`.

### Cuidado de UX (vale para todos os itens acima)
Manter os campos **opcionais e de um toque só** — nunca formulário
obrigatório. Cada campo a mais no fluxo de registrar sessão reduz a chance do
aluno efetivamente registrar, e menos sessão registrada significa o gate de N
mínimo bloqueando mais insight no backend — o que anula o ganho de coletar o
dado.

---

## 4. Fora de escopo por enquanto

- **Conectar de verdade** as integrações de saúde (Health Connect, HealthKit,
  Mi Fitness, Google Fit) e tempo de tela (`UsageStatsManager`, Android-only)
  — hoje é mock em Ajustes; manter mock até o backend priorizar
  `sono_x_rendimento`/`tela_antes_sessao` (esforço alto, depende de permissão
  de SO).
- **Motor de experimento _n-of-1_** — a "prova causal" por trás de um
  insight; planejado, tela de detalhe já prepara o terreno visual, mas
  implementação não iniciada.
- Ideias já descartadas/pausadas para este módulo: biblioteca semântica de
  materiais, canvas de anotação, planejador adaptativo, repetição espaçada,
  projeção de nota.

---

## 5. Ordem sugerida

1. ⏳ Wiring com backend real (§2) assim que `GET /api/insights/` existir —
   sem mudança visual, só troca de fonte de dado.
2. ⏳ Persistência real de feedback (§2.2), após a criação da rota/model no
   backend.
3. ✅ Prompt de energia pré-sessão + contador de interrupções (§3,
   Prioridade 1).
4. ✅ Seletor de tipo de atividade (§3, Prioridade 2).
5. ⛔ Marcação de origem de recomendação (§3, Prioridade 3) — alinhar a regra
   de atribuição antes de definir o schema.
