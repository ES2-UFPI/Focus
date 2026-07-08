# Prompt: implementar backend simplificado de Insights

Voce e um agente de engenharia trabalhando no projeto Focus.

Sua tarefa e ajustar o backend do modulo de Insights para refletir exatamente a
experiencia consolidada no frontend atual. Nao implemente o roadmap antigo
completo. O objetivo agora e simples: substituir os mocks restantes apenas no
que a UI realmente usa.

## Contexto

O frontend de Insights foi simplificado. A experiencia atual possui apenas duas
abas:

1. **Insights**
   - Secao "Pontos para melhorar"
   - Secao "Descobertas"

2. **Evolucao**
   - Historico de melhorias observadas

O backend ja possui uma app `insights`, mas parte dela foi planejada para um
escopo maior do que a interface atual precisa. Siga a interface consolidada, nao
o plano antigo completo.

Parte do backend atual foi implementada olhando para o plano antigo. Essas
partes devem ser removidas, simplificadas ou deixadas sem uso quando estiverem
em dissonancia com o frontend atual. O resultado final deve conter apenas o que
alimenta a experiencia consolidada.

Antes de implementar, leia:

- `frontend/lib/screens/insights_screen.dart`
- `frontend/lib/widgets/insights/insight_feed_row.dart`
- `frontend/lib/widgets/insights/insight_feed_section.dart`
- `frontend/lib/widgets/insights/insight_evolution_view.dart`
- `frontend/lib/widgets/insights/insight_evolution_card_strategy.dart`
- `frontend/lib/models/insights_model.dart`
- `frontend/lib/services/insights_service.dart`
- `backend/insights/services.py`
- `backend/insights/views.py`
- `backend/insights/urls.py`
- `backend/insights/models.py`
- `backend/insights/tests.py`

## Objetivo principal

Implementar o backend necessario para alimentar a tela atual de Insights sem
depender dos mocks.

O backend deve entregar:

- lista de insights atuais
- lista de melhorias observadas para a aba Evolucao
- feedback simples do usuario

Nao crie funcionalidades que nao aparecem mais no frontend.

Tambem remova as implementacoes antigas que nao fazem mais sentido para essa
interface. Nao mantenha codigo complexo apenas porque ele ja existe.

## Endpoints desejados

### 1. `GET /api/insights/`

Deve retornar a lista de insights do aluno autenticado.

Cada item deve seguir o contrato `Insight` do frontend:

```json
{
  "id": "taxa_furo:banco-de-dados",
  "tipo": "taxa_furo",
  "titulo": "Sexta a noite segue sendo o horario mais fragil",
  "descricao": "Sexta a noite concentra cancelamentos de Banco de Dados.",
  "numeros": {
    "taxa_pct": 60
  },
  "categoria": "rotina",
  "disciplina": "Banco de Dados",
  "amostra": 5,
  "confianca": "media",
  "natureza": "observacional",
  "severidade": "critico",
  "acao": {
    "tipo": "reagendar",
    "label": "Reagendar sessao",
    "disciplina_id": "uuid-da-disciplina",
    "horario_sugerido": "08:00"
  },
  "grafico": null,
  "sessoes_evidencia": []
}
```

### Como o frontend classifica os insights

O frontend nao precisa de um campo extra de tag.

Ele calcula:

- `Pontos para melhorar`: `severidade == "critico"` ou `severidade == "atencao"`
- `Descobertas`: `severidade == "positivo"` ou `severidade == "info"`
- `Acao recomendada`: quando `acao != null`
- `Informativo`: quando `acao == null`

Logo, o backend deve preencher corretamente:

- `severidade`
- `acao`
- `disciplina`
- `categoria`
- `tipo`

## Insights que devem ser priorizados

Implemente apenas insights que fazem sentido para a UI atual e para os dados ja
existentes no sistema.

### Pontos para melhorar

Priorize:

1. `taxa_furo`
   - Detecta cancelamentos recorrentes por dia/horario/disciplina.
   - Exemplo: Banco de Dados na sexta a noite.
   - Deve ter acao quando fizer sentido: `reagendar`.

2. `duracao_ideal`
   - Detecta queda de produtividade em blocos longos.
   - Deve sugerir blocos menores quando houver amostra suficiente.

3. `ritmo_disciplina`
   - Detecta materia negligenciada ou ritmo irregular.
   - Deve apontar a disciplina e sugerir uma sessao.

4. `vies_estimativa`
   - Detecta quando o aluno subestima tempo de tarefas/sessoes.
   - Pode ser informativo ou ter acao leve.

### Descobertas

Priorize:

1. `melhor_horario`
   - Detecta horario em que o aluno rende melhor.
   - Deve aparecer como descoberta positiva.

2. `tarefas_no_prazo`
   - Detecta comportamento bom de cumprir tarefas.
   - Deve aparecer como informativo.

3. `sequencia_produtiva`
   - Detecta sequencia consistente/produtiva.
   - Deve aparecer como descoberta.

4. `progresso`
   - Detecta melhora simples entre periodos.
   - Pode ser descoberta ou alimentar Evolucao.

## O que nao implementar agora

Nao implemente nesta tarefa e remova/descontinue o que ja foi implementado
nessa direcao se estiver sem uso na UI atual:

- dashboard completo antigo
- `dimensoes`
- `comparacoes`
- `experimentos`
- motor sofisticado de `efeito_acao`
- jornada completa diagnostico -> acao -> resultado
- rastro complexo de origem de recomendacao
- HealthKit
- Health Connect
- Google Fit
- Samsung Health
- Mi Fitness
- UsageStatsManager
- tempo de tela real
- sono real
- `desgaste` completo baseado em sono
- avaliacao estatistica pesada
- ML
- LLM

Se algum desses pontos existir no codigo atual, nao expanda. Apenas mantenha
compatibilidade se a remocao for arriscada.

### Implementacoes antigas que devem sair ou ser neutralizadas

Remova ou simplifique estas partes do backend atual:

1. `dimensoes`
   - Hoje `GET /api/insights/evolucao/` monta uma lista de dimensoes do estudo.
   - A interface atual nao exibe mais esse painel.
   - Remova a montagem de `dimensoes` ou retorne lista vazia apenas por
     compatibilidade de contrato.

2. `comparacoes`
   - Hoje o backend monta comparacoes temporais para o dashboard antigo.
   - A interface atual nao usa essas comparacoes.
   - Remova essa logica ou retorne lista vazia.

3. `experimentos`
   - Hoje aparece como `experimentos: []`, resquicio da Fase 4 antiga.
   - Nao implementar experimentos observacionais agora.
   - Se o campo permanecer por compatibilidade, mantenha vazio.

4. Insights pouco alinhados ao template atual
   - `melhor_dia_semana`
   - `foco_sem_interrupcoes`
   - `cramming`
   - `equilibrio_metodo`

   Esses insights nao sao prioridade para o frontend consolidado. Eles podem
   ser removidos do retorno de `GET /api/insights/` nesta etapa, a menos que
   sejam reescritos para aparecer claramente como:

   - ponto para melhorar
   - descoberta
   - melhoria observada

5. Referencias ao roadmap antigo
   - Atualize `backend/insights/README.md` se necessario.
   - Remova texto que indique que o objetivo atual ainda e implementar
     `InsightsDashboard`, Fase 4 completa ou Fase 5 de integracoes externas.

O backend final deve parecer pequeno e intencional, nao uma mistura do plano
antigo com o frontend novo.

## Evolucao simplificada

A aba Evolucao atual nao precisa de dashboard grande.

Ela precisa apenas de uma lista de melhorias observadas.

Hoje o frontend usa:

```dart
Future<List<InsightJourneyEvent>> fetchJourney()
```

Implemente uma forma real de buscar esses eventos.

Opcao preferida:

```text
GET /api/insights/evolucao/
```

Retornar algo simples, por exemplo:

```json
{
  "periodo": "01/07 a 07/07",
  "atualizado_em": "Atualizado em 07/07 19:30",
  "jornada": [
    {
      "data": "Ha 3 dias",
      "tipo": "melhora",
      "texto": "Cancelamentos de Banco de Dados cairam depois de evitar sexta a noite.",
      "insight_tipo": "taxa_furo"
    }
  ],
  "dimensoes": [],
  "comparacoes": [],
  "experimentos": []
}
```

Os campos `dimensoes`, `comparacoes` e `experimentos` so devem continuar na
resposta se forem necessarios para manter compatibilidade com o parser atual do
frontend. Eles devem vir vazios e nao devem ter logica propria.

Se preferir criar endpoint separado:

```text
GET /api/insights/jornada/
```

entao atualize `frontend/lib/services/insights_service.dart` para consumir esse
endpoint em `fetchJourney()`.

### Regras para melhoria observada

Uma melhoria so deve aparecer quando houver comparacao simples e objetiva:

- cancelamentos cairam
- produtividade subiu
- entregas no prazo melhoraram
- uma materia saiu de ritmo ruim para ritmo melhor
- a duracao media ficou mais adequada

Nao precisa provar causalidade.

Texto deve ser direto e relacionado a um insight ruim anterior.

Exemplo:

```json
{
  "data": "Ha 6 dias",
  "tipo": "melhora",
  "texto": "Ao encurtar as revisoes de Banco de Dados para 50 min, o fim do bloco deixou de derrubar tanto o foco.",
  "insight_tipo": "duracao_ideal"
}
```

## Feedback simples

Mantenha:

```text
POST /api/insights/<id>/feedback/
```

O feedback deve continuar aceitando:

```json
{
  "useful": true,
  "reason": "..."
}
```

Uso esperado:

- `Ciente` em insight informativo pode enviar feedback positivo/visto.
- feedback positivo nao deve aplicar nenhuma regra especial.
- feedback positivo nao deve priorizar, promover, pontuar nem reforcar o
  insight.
- feedback negativo deve aplicar uma punicao temporaria: ocultar aquele insight
  daquele usuario por 7 dias.

Nao implemente personalizacao complexa.

### Regra de punicao por feedback negativo

Quando o usuario enviar feedback negativo para um insight:

```json
{
  "useful": false,
  "reason": "..."
}
```

o backend deve registrar uma punicao temporaria para aquele aluno e aquele
insight.

Comportamento esperado:

- ocultar propositalmente o insight por 7 dias
- a punicao vale para qualquer motivo de feedback negativo
- a punicao e individual por aluno
- a punicao e individual por insight
- depois de 7 dias, o insight pode voltar a aparecer se o aluno cair novamente
  no caso de uso daquele insight
- feedback positivo nao remove nem cria punicao
- feedback positivo nao muda ordenacao
- feedback positivo nao aumenta confianca
- feedback positivo nao deve criar reforco ou recompensa

Modelo de implementacao sugerido:

- reaproveitar `InsightFeedback`
- adicionar campo como `ocultar_ate`
- ao receber `useful == false`, preencher `ocultar_ate = agora + 7 dias`
- ao listar insights, filtrar fora os registros com punicao ativa
- se `ocultar_ate` estiver no passado, o insight volta a poder aparecer

Se preferir outro nome de campo, tudo bem, mas o comportamento precisa ser esse.

## Compatibilidade com o frontend atual

O frontend atual usa:

- `Insight.tipo`
- `Insight.titulo`
- `Insight.descricao`
- `Insight.numeros`
- `Insight.categoria`
- `Insight.disciplina`
- `Insight.amostra`
- `Insight.confianca`
- `Insight.natureza`
- `Insight.severidade`
- `Insight.acao`
- `Insight.grafico`
- `Insight.sessoesEvidencia`
- `InsightJourneyEvent.data`
- `InsightJourneyEvent.texto`
- `InsightJourneyEvent.tipo`
- `InsightJourneyEvent.insightTipo`

Preserve esses campos.

Se algum campo nao for usado na UI atual, pode retornar vazio ou `null`, desde
que nao quebre o parser.

Nao preserve campos complexos apenas por apego ao plano antigo. Preserve apenas
o suficiente para nao quebrar o frontend.

## Arquivos provaveis de alteracao

Backend:

- `backend/insights/services.py`
- `backend/insights/views.py`
- `backend/insights/urls.py`
- `backend/insights/tests.py`
- `backend/insights/serializers.py`, se necessario
- `backend/insights/models.py`, apenas se precisar ajustar feedback

Frontend, se necessario:

- `frontend/lib/services/insights_service.dart`
- `frontend/lib/models/insights_model.dart`
- `frontend/test/services/insights_service_test.dart`

Evite mexer nos widgets visuais se o contrato puder ser adaptado no service.

## Criterios de aceite

A tarefa so esta pronta quando:

- `GET /api/insights/` retorna dados reais suficientes para as duas secoes:
  - `Pontos para melhorar`
  - `Descobertas`
- insights com `acao` aparecem como "Acao recomendada" no frontend
- insights sem `acao` aparecem como "Informativo"
- `GET /api/insights/evolucao/` ou endpoint equivalente retorna melhorias reais
  simples
- `fetchJourney()` nao retorna mais vazio quando houver melhoria observada
- feedback continua funcionando
- feedback negativo oculta o insight por 7 dias para aquele aluno
- feedback positivo nao aplica priorizacao, reforco ou punicao
- `dimensoes`, `comparacoes` e `experimentos` nao possuem mais logica ativa
  quando nao forem usados pela UI atual
- insights desalinhados com os templates atuais nao aparecem no retorno, exceto
  se forem reescritos para se encaixar claramente em "Pontos para melhorar",
  "Descobertas" ou "Historico de melhorias"
- nao existem dependencias de sono, tempo de tela ou integracao de celular
- os testes existentes continuam passando
- novos testes cobrem:
  - classificacao de problemas e descobertas por severidade
  - insight com acao
  - insight informativo sem acao
  - evolucao com melhoria observada
  - evolucao vazia quando nao ha dados suficientes
  - feedback util/nao util
  - isolamento por aluno

## Validacao minima

Backend:

```bash
cd backend
python manage.py check
python manage.py test insights
```

Frontend, se Flutter estiver disponivel:

```bash
cd frontend
flutter test test/services/insights_service_test.dart
flutter test test/screens/insights_screen_test.dart
```

## Observacao importante

Nao tente "completar" o modulo antigo.

O novo objetivo e menor e mais pratico:

- alimentar a tela atual
- substituir os mocks que ainda importam
- manter o codigo simples
- mostrar melhorias objetivas
- evitar features que dependem de avaliacao, saude, celular ou causalidade
  complexa
