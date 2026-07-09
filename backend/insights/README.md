# App `insights` — backend do módulo de Insights

Alimenta a tela atual de Insights (perfil de estudo/produtividade), antes 100%
mock no frontend. O escopo é pequeno e intencional: entregar só o que as duas
abas da UI usam hoje. Não implementa o roadmap antigo (dashboard completo,
dimensões, comparações, experimentos, integrações de saúde/celular).

## Endpoints

| Rota | Método | Descrição |
|---|---|---|
| `/api/insights/` | GET | Insights calculados do aluno autenticado |
| `/api/insights/evolucao/` | GET | Melhorias observadas (`jornada`) da aba Evolução |
| `/api/insights/<id>/feedback/` | POST | Registra 👍/👎 do aluno (`{"useful": bool, "reason": "..."}`) |

Todos exigem autenticação por token (aluno logado).

## O que a tela usa

- **Insights** — duas seções, classificadas pelo frontend a partir da
  `severidade` de cada insight:
  - *Pontos para melhorar*: `severidade` `critico` ou `atencao`.
  - *Descobertas*: `severidade` `positivo` ou `info`.
  - Um insight com `acao != null` aparece como "Ação recomendada"; sem `acao`,
    como "Informativo".
- **Evolução** — apenas a lista `jornada` de melhorias observadas.

## Insights produzidos

Só os que a UI atual exibe:

- Pontos para melhorar: `taxa_furo`, `duracao_ideal`, `ritmo_disciplina`,
  `vies_estimativa`.
- Descobertas: `melhor_horario`, `tarefas_no_prazo`, `sequencia_produtiva`,
  `progresso`.

Sem dados suficientes, retorna o insight `amostra_insuficiente`.

## Como funciona

- `services.py` (`InsightsService`) lê os dados já coletados (`SessaoEstudo`,
  `BlocoPomodoro`, `TarefaDisciplina`) numa janela de 42 dias. A
  **produtividade de uma sessão** é a média das avaliações dos seus
  `BlocoPomodoro`.
- `statistics.py` traz média e variação percentual em Python puro. Nada de
  ML/LLM, saúde, tempo de tela ou causalidade — apenas comparação de médias por
  grupo.
- **Gate de N mínimo**: todo insight agregado só aparece com amostra suficiente
  (`MIN_AMOSTRA = 5`); `confianca` = `alta` (≥15), `media` (≥5) ou
  `insuficiente`.
- **Evolução**: `obter_evolucao` compara o começo e o fim da janela e emite uma
  melhoria (`jornada`) quando há queda objetiva ligada a um insight ruim ainda
  ativo (ex.: cancelamentos caindo com `taxa_furo` presente). Não prova
  causalidade. Os campos `dimensoes`, `comparacoes` e `experimentos`
  permanecem na resposta apenas por compatibilidade do parser do frontend e
  vêm sempre vazios.

## Feedback (`InsightFeedback`)

Determinístico, sem ML e sem reforço:

- 👎 (`useful: false`) aplica uma punição temporária: preenche `ocultar_ate` com
  `agora + 7 dias` e o insight some daquele aluno até lá. Depois disso, ele pode
  voltar se o aluno cair de novo no caso de uso. A punição é individual por
  aluno e por insight.
- 👍 (`useful: true`) apenas registra o "visto". Não cria, não remove e não
  altera punição; não prioriza, pontua nem reordena nada.
