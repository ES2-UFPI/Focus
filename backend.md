1. Backend (Django REST Framework)

Projeto Django com apps modulares por domínio, autenticação por token, usuário customizado por e‑mail, banco sqlite3.

backend/
├── manage.py
├── focus_api/            # config do projeto (settings, urls, wsgi/asgi)
├── services/
│   └── consistencia_service.py   # regras de negócio (métricas de consistência)
├── alunos/                # AUTH_USER_MODEL = 'alunos.Aluno'
├── disciplinas/
├── tarefas_disciplina/
├── eventos_academicos/
├── sessao_estudo/
├── feedback_sessao_estudo/
└── materiais_estudo/
Cada app segue o padrão Django: models.py, serializers.py, views.py, admin.py, migrations/.

Entidades e campos

Aluno (alunos, é o AUTH_USER_MODEL, estende AbstractUser)
- id UUID (PK), nome, email (único, login), data_nascimento, data_cadastro, username (auto = email)
- Autenticação por e-mail via AlunoManager customizado + Token (rest_framework.authtoken)

Disciplina (disciplinas)
- id UUID, aluno → FK Aluno (CASCADE), nome, codigo, descricao, cor, meta_horas_semanais, ativo, data_criacao

TarefaDisciplina (tarefas_disciplina)
- id UUID, disciplina → FK Disciplina (CASCADE), evento → FK EventoAcademico (SET_NULL, opcional), titulo, descricao, prazo, concluida, data_conclusao, prioridade (BAIXA/MEDIA/ALTA)

EventoAcademico (eventos_academicos)
- id UUID, disciplina → FK Disciplina (CASCADE), titulo, tipo (PROVA/TRABALHO/SEMINARIO/APRESENTACAO/OUTRO), descricao, data_evento, hora_inicio, hora_fim, concluido, data_conclusao, data_criacao
- Propriedades calculadas: dias_restantes, urgencia

SessaoEstudo (sessao_estudo)
- id UUID, disciplina → FK Disciplina (CASCADE), inicio, fim, duracao_realizada, status (AGENDADO/EM_ANDAMENTO/CONCLUIDO/CANCELADO), descricao, data_criacao
- Validação: impede sobreposição de sessões do mesmo aluno

FeedbackSessaoEstudo (feedback_sessao_estudo)
- id UUID, sessao_estudo → OneToOne SessaoEstudo (CASCADE), produtividade (1–5), descricao, hora_registro

MaterialEstudo (materiais_estudo)
- id UUID, disciplina → FK Disciplina (CASCADE), titulo, tipo (PDF/Resumo/Link/Video/Outro), url, arquivo (upload), descricao, data_insercao

Diagrama entidade-relacionamento

mermaid
erDiagram
    ALUNO ||--o{ DISCIPLINA : possui
    DISCIPLINA ||--o{ TAREFA_DISCIPLINA : contem
    DISCIPLINA ||--o{ EVENTO_ACADEMICO : contem
    DISCIPLINA ||--o{ SESSAO_ESTUDO : contem
    DISCIPLINA ||--o{ MATERIAL_ESTUDO : contem
    EVENTO_ACADEMICO |o--o{ TAREFA_DISCIPLINA : "vincula (opcional)"
    SESSAO_ESTUDO ||--|| FEEDBACK_SESSAO_ESTUDO : avaliada_por

    ALUNO {
        uuid id PK
        string nome
        string email UK
        date data_nascimento
        datetime data_cadastro
    }
    DISCIPLINA {
        uuid id PK
        uuid aluno_id FK
        string nome
        string codigo
        string cor
        decimal meta_horas_semanais
        bool ativo
    }
    TAREFA_DISCIPLINA {
        uuid id PK
        uuid disciplina_id FK
        uuid evento_id FK "nullable"
        string titulo
        datetime prazo
        bool concluida
        string prioridade
    }
    EVENTO_ACADEMICO {
        uuid id PK
        uuid disciplina_id FK
        string titulo
        string tipo
        date data_evento
        time hora_inicio
        time hora_fim
        bool concluido
    }
    SESSAO_ESTUDO {
        uuid id PK
        uuid disciplina_id FK
        datetime inicio
        datetime fim
        int duracao_realizada
        string status
    }
    FEEDBACK_SESSAO_ESTUDO {
        uuid id PK
        uuid sessao_estudo_id FK "OneToOne"
        int produtividade
        string descricao
    }
    MATERIAL_ESTUDO {
        uuid id PK
        uuid disciplina_id FK
        string titulo
        string tipo
        string url
        file arquivo
    }

Rotas principais (/api/)

- POST auth/registro/, POST auth/login/ (Token)
- CRUD via DefaultRouter: alunos/, disciplinas/, tarefas-disciplina/, materiais-estudo/, eventos-academicos/, sessoes-estudo/, feedbacks-sessao/
- Extras: eventos-academicos/proximos/, sessoes-estudo/semana_atual/, sessoes-estudo/dashboard/, sessoes-estudo/ranking/, sessoes-estudo/disciplina_negligenciada/, sessoes-estudo/disciplina/{id}/desempenho/
- GET agenda/ — agenda unificada (eventos + sessões + recomendações)
- Tudo escopado ao aluno autenticado (IsAuthenticated + filtro por usuário)

        string descricao
    }
    MATERIAL_ESTUDO {
        uuid id PK
        uuid disciplina_id FK
        string titulo
        string tipo
        string url
        file arquivo
    }

Rotas principais (/api/)

- POST auth/registro/, POST auth/login/ (Token)
- CRUD via DefaultRouter: alunos/, disciplinas/, tarefas-disciplina/, materiais-estudo/, eventos-academicos/, sessoes-estudo/, feedbacks-sessao/
- Extras: eventos-academicos/proximos/, sessoes-estudo/semana_atual/, sessoes-estudo/dashboard/, sessoes-estudo/ranking/, sessoes-estudo/disciplina_negligenciada/, sessoes-estudo/disciplina/{id}/desempenho/
- GET agenda/ — agenda unificada (eventos + sessões + recomendações)
- Tudo escopado ao aluno autenticado (IsAuthenticated + filtro por usuário)
