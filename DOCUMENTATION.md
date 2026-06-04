# Focus — Documentação do Projeto

## Sumário

1. [Visão Geral](#visão-geral)
2. [Arquitetura](#arquitetura)
3. [Primeiros Passos](#primeiros-passos)
4. [Backend](#backend)
   - [Tecnologias](#tecnologias-backend)
   - [Estrutura do Projeto](#estrutura-do-projeto-backend)
   - [Modelos de Dados](#modelos-de-dados)
   - [Referência da API](#referência-da-api)
   - [Autenticação](#autenticação)
5. [Frontend](#frontend)
   - [Tecnologias](#tecnologias-frontend)
   - [Estrutura do Projeto](#estrutura-do-projeto-frontend)
   - [Gerenciamento de Estado](#gerenciamento-de-estado)
   - [Componentes de UI](#componentes-de-ui)
6. [Fluxo de Desenvolvimento](#fluxo-de-desenvolvimento)
7. [Como Contribuir](#como-contribuir)

---

## Visão Geral

**Focus** é uma plataforma de produtividade acadêmica que ajuda estudantes a organizar sua vida universitária. Ela reúne planejamento de ciclos de estudo, gerenciamento de materiais, controle de atividades e monitoramento de consistência em um único aplicativo.

### Funcionalidades Principais

| Funcionalidade | Descrição | Status |
|----------------|-----------|--------|
| Biblioteca de Materiais | Organizar PDFs, links, resumos e vídeos por disciplina | ✅ Implementado |
| Ciclo de Estudos | Planejar sessões de estudo semanais por disciplina | 🔄 Em andamento |
| Atividades Acadêmicas | Gerenciar provas, trabalhos e seminários | ✅ Implementado |
| Metas Semanais | Definir e acompanhar metas de estudo | ✅ Implementado |
| Consistência Semanal | Visualizar índice de regularidade e horas estudadas | 🔄 Em andamento |
| Relatórios | Análise de desempenho e distribuição por disciplina | 📋 Planejado |

---

## Arquitetura

O Focus adota uma arquitetura cliente–servidor com uma API REST no backend e um frontend multiplataforma móvel/desktop.

```
┌──────────────────────────────────────────────────────┐
│                  Cliente Flutter                      │
│  (iOS · Android · Web · macOS · Windows · Linux)     │
│                                                       │
│  Provider (estado) → ApiService (HTTP) → REST API    │
└───────────────────────┬──────────────────────────────┘
                        │ HTTPS / Autenticação por Token
┌───────────────────────▼──────────────────────────────┐
│               Django REST Framework                   │
│                                                       │
│   ViewSets → Serializers → Models → SQLite/Postgres   │
└──────────────────────────────────────────────────────┘
```

### Princípios de Design

- **Isolamento de propriedade** — cada recurso é restrito ao `Aluno` autenticado; acessos entre usuários são bloqueados na camada do ViewSet.
- **Responsabilidade única** — cada app Django possui uma entidade de domínio e expõe seu próprio serializer e ViewSet.
- **Consistência visual** — o frontend Flutter utiliza `shadcn_ui` para manter uma linguagem de design coerente em todas as telas.

---

## Primeiros Passos

### Pré-requisitos

| Ferramenta | Versão Mínima |
|------------|---------------|
| Python | 3.11+ |
| Django | 5.1+ |
| Flutter SDK | 3.41.0+ |
| Dart SDK | 3.11.5+ |

### Backend

```bash
cd backend
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser   # cria um Aluno de teste
python manage.py runserver
```

API disponível em `http://localhost:8000/api/`

### Frontend

```bash
cd frontend
flutter pub get
flutter run
```

> **Observação sobre o emulador Android:** a URL base da API está configurada como `http://10.0.2.2:8000`, que mapeia para o `localhost` da máquina host dentro do emulador Android. Para dispositivos físicos ou web, ajuste o valor em `lib/services/api_service.dart`.

---

## Backend

### Tecnologias Backend

| Biblioteca | Versão | Finalidade |
|------------|--------|------------|
| Django | 5.1.6 | Framework web |
| Django REST Framework | 3.17.1 | API REST |
| rest_framework.authtoken | incluso | Autenticação por token |
| django-cors-headers | 4.9.0 | CORS para o cliente Flutter |
| SQLite | incluso | Banco de dados de desenvolvimento |

### Estrutura do Projeto Backend

```
backend/
├── focus_api/                 # Configurações do projeto Django
│   ├── settings.py
│   └── urls.py
├── alunos/                    # Entidade de usuário (AbstractUser)
├── disciplinas/               # Entidade de disciplina acadêmica
├── tarefas_disciplina/        # Tarefas vinculadas a disciplinas
├── avaliacoes_academicas/     # Avaliações acadêmicas (provas, trabalhos)
├── metas_semanais/            # Metas semanais de estudo
├── ciclos_estudo/             # Sessões do ciclo de estudos
└── materiais_estudo/          # Biblioteca de materiais de estudo ← funcionalidade principal
```

Cada app segue o layout padrão do Django:

```
<app>/
├── migrations/
│   └── 0001_initial.py
├── models.py          # Entidade de domínio
├── serializers.py     # Serializer do DRF (campos explícitos)
├── views.py           # ModelViewSet com filtro de propriedade
├── admin.py
└── tests.py
```

### Modelos de Dados

#### Aluno (alunos)
Estende `django.contrib.auth.models.AbstractUser`. Utilizado como `AUTH_USER_MODEL`.

| Campo | Tipo | Observação |
|-------|------|------------|
| id | UUIDField | Chave primária |
| nome | CharField(255) | Nome de exibição |
| email | EmailField | Único, usado como `USERNAME_FIELD` |
| data_cadastro | DateTimeField | Preenchido automaticamente na criação |

#### Disciplina (disciplinas)

| Campo | Tipo | Observação |
|-------|------|------------|
| id | UUIDField | Chave primária |
| aluno | FK → Aluno | Proprietário |
| nome | CharField(255) | |
| codigo | CharField(50) | Único por aluno |
| cor | CharField(20) | Cor hexadecimal para a UI |
| carga_horaria_oficial | IntegerField | |
| ativo | BooleanField | |

#### MaterialEstudo (materiais_estudo)

| Campo | Tipo | Observação |
|-------|------|------------|
| id | UUIDField | Chave primária |
| aluno | FK → Aluno | Proprietário (definido automaticamente na criação) |
| disciplina | FK → Disciplina | |
| titulo | CharField(255) | |
| tipo | CharField | `PDF`, `Resumo`, `Link`, `Video`, `Outro` |
| url | CharField(500) | Opcional |
| arquivo_path | CharField(500) | Opcional |
| descricao | TextField | Opcional |
| data_insercao | DateTimeField | Preenchido automaticamente na criação |

#### AtividadeAcademica (avaliacoes_academicas)

| Campo | Tipo | Observação |
|-------|------|------------|
| id | UUIDField | Chave primária |
| aluno | FK → Aluno | |
| disciplina | FK → Disciplina | |
| tipo | CharField | `Prova`, `Trabalho`, `Seminario`, `Outro` |
| data | DateField | |
| nota | DecimalField(5,2) | Opcional |
| peso | DecimalField(5,2) | Opcional |
| observacao | TextField | Opcional |

#### MetaSemanal (metas_semanais) · CicloEstudo (ciclos_estudo) · TarefaDisciplina (tarefas_disciplina)
Consulte os respectivos arquivos `models.py`.

### Referência da API

URL base: `/api/`

#### Autenticação

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| POST | `/api/auth/token/` | Obter token de autenticação (`{"username": "<email>", "password": "<senha>"}`) |

Todos os demais endpoints exigem o cabeçalho `Authorization: Token <token>`.

#### Materiais — `/api/materiais-estudo/`

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/api/materiais-estudo/` | Listar materiais (restrito ao proprietário) |
| POST | `/api/materiais-estudo/` | Criar material |
| GET | `/api/materiais-estudo/{id}/` | Detalhar material |
| PATCH | `/api/materiais-estudo/{id}/` | Atualizar material |
| DELETE | `/api/materiais-estudo/{id}/` | Remover material |

**Parâmetros de consulta:**

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `disciplina` | UUID | Filtrar por ID da disciplina |
| `tipo` | string | Filtrar por tipo (`PDF`, `Link`, etc.) |
| `search` | string | Busca textual em `titulo` e `descricao` |
| `ordering` | string | `data_insercao`, `titulo`; prefixo `-` para ordem decrescente |

#### Demais Recursos

| Recurso | Endpoint |
|---------|----------|
| Alunos | `/api/alunos/` |
| Disciplinas | `/api/disciplinas/` |
| Tarefas de Disciplina | `/api/tarefas-disciplina/` |
| Atividades Acadêmicas | `/api/avaliacoes-academicas/` |
| Metas Semanais | `/api/metas-semanais/` |
| Ciclos de Estudo | `/api/ciclos-estudo/` |

### Autenticação

O Focus utiliza **Autenticação por Token do DRF**. Obtenha um token via `POST /api/auth/token/` e passe-o em todas as requisições subsequentes:

```http
Authorization: Token 9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b
```

Tokens são por usuário e não expiram por padrão. Implemente rotação de tokens em produção.

---

## Frontend

### Tecnologias Frontend

| Biblioteca | Versão | Finalidade |
|------------|--------|------------|
| Flutter | 3.41.0+ | Framework de UI multiplataforma |
| shadcn_ui | 0.54.0 | Sistema de design (port do shadcn/ui) |
| provider | 6.1.5 | Gerenciamento de estado |
| http | 1.6.0 | Cliente HTTP |
| flutter_secure_storage | 9.2.4 | Armazenamento seguro do token |
| intl | 0.20.2 | Formatação de datas e números |

### Estrutura do Projeto Frontend

```
frontend/lib/
├── main.dart                           # Ponto de entrada — ShadApp + MultiProvider + AppShell
├── models/
│   ├── disciplina.dart                 # Classe Disciplina + fromJson
│   └── material_estudo.dart            # Classe MaterialEstudo + fromJson/toJson
├── services/
│   └── api_service.dart                # Camada HTTP — todas as chamadas à API
├── providers/
│   └── materiais_provider.dart         # ChangeNotifier — estado + lógica de filtros
├── pages/
│   └── biblioteca_materiais_page.dart  # Tela principal da Biblioteca de Materiais
└── widgets/
    ├── app_sidebar.dart                # Navegação lateral (fundo escuro, destaque violeta)
    ├── material_form_dialog.dart       # Formulário de adição/edição (ShadDialog)
    └── delete_confirm_dialog.dart      # Confirmação de remoção (ShadDialog.alert)
```

### Gerenciamento de Estado

O `MateriaisProvider` (ChangeNotifier) gerencia:
- Lista de materiais retornada pela API
- Lista de disciplinas para filtros e formulários
- Filtros ativos: `selectedDisciplinaId`, `selectedTipo`, `searchQuery`
- Estados de carregamento e erro

Os widgets utilizam `context.read<MateriaisProvider>()` para disparar ações (adicionar, atualizar, remover, definir filtros) e `context.watch<MateriaisProvider>()` para se reconstruir quando o estado muda.

### Componentes de UI

O app utiliza `ShadApp` como widget raiz com `ShadVioletColorScheme` para corresponder à identidade visual do Focus.

Principais componentes usados na Biblioteca de Materiais:

| Componente | Uso |
|------------|-----|
| `ShadCard` | Container da tabela |
| `ShadTable.list` | Tabela de materiais |
| `ShadButton` / `ShadButton.outline` / `ShadButton.ghost` | Todos os botões de ação |
| `ShadInput` | Campo de busca |
| `ShadSelect` | Seletores de Tipo e Disciplina no formulário |
| `ShadInputFormField` | Campos de formulário com validação |
| `ShadForm` | Wrapper de formulário com validação |
| `ShadDialog` | Dialog de adição/edição |
| `ShadDialog.alert` | Confirmação de remoção |
| `ShadBadge.secondary` | Badge de tipo na tabela |
| `ShadPopover` | Menu de ações por linha (editar / remover) |
| `ShadToaster` / `ShadToast` | Notificações de feedback |
| `LucideIcons` | Conjunto de ícones (incluído com shadcn_ui) |

---

## Fluxo de Desenvolvimento

### Estratégia de Branches

```
master          ← pronto para produção (protegido)
dev             ← branch de integração — todos os PRs fazem merge aqui
feat/<nome>     ← branches de funcionalidade (a partir de dev)
fix/<nome>      ← branches de correção (a partir de dev)
Samuel#<issue>  ← branches de issue seguindo a convenção do projeto
```

### Processo de Pull Request

1. Criar branch a partir de `dev`
2. Um commit por unidade lógica de trabalho
3. Abrir PR apontando para `dev`
4. Aprovação de pelo menos um revisor obrigatória
5. Resolver todos os conflitos antes do merge (rebase em cima de dev)
6. Squash merge recomendado para um histórico mais limpo

### Resolução de Conflitos

Quando múltiplos PRs adicionam entradas ao `settings.py` (INSTALLED_APPS) ou ao `urls.py` (router), surgem conflitos de rebase. A regra é: **sempre manter todas as entradas existentes e acrescentar a nova**. Consulte o histórico do git para exemplos.

---

## Como Contribuir

1. Escolha uma issue aberta no backlog do projeto
2. Comente na issue para sinalizar que está trabalhando nela
3. Crie uma branch seguindo a convenção de nomenclatura acima
4. Implemente a funcionalidade ou correção
5. Certifique-se de que `python manage.py check` passa (backend) e `flutter analyze` passa (frontend)
6. Abra um PR com uma descrição clara referenciando o número da issue (`closes #<n>`)
7. Responda aos comentários de revisão com novos commits (não faça force-push após o início da revisão)
