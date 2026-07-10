<div align="center">

# 🎯 Focus

### Organize seus estudos, mantenha a consistência e acompanhe sua evolução.

Aplicação acadêmica desenvolvida para ajudar estudantes universitários a planejar atividades, realizar sessões de foco e analisar o próprio desempenho.

[🌐 Acessar aplicação](https://es2-ufpi.github.io/Focus/) · [📦 Repositório](https://github.com/ES2-UFPI/Focus)

</div>

---

## 📖 Introdução

O **Focus** é uma aplicação de organização e acompanhamento de estudos voltada principalmente para estudantes universitários.

O projeto reúne, em um único ambiente, recursos para cadastrar disciplinas, organizar atividades acadêmicas, planejar sessões de estudo, utilizar a técnica Pomodoro, registrar notas e materiais e acompanhar a consistência semanal.

Além de auxiliar no planejamento, o sistema utiliza os dados das sessões concluídas para apresentar indicadores e insights sobre a rotina de estudos do usuário.

---

## 🛠️ Tecnologias

### Frontend

- **Flutter**
- **Dart**
- **Provider** para gerenciamento de estado
- **HTTP** para comunicação com a API
- **Sqflite** e **SharedPreferences** para armazenamento local
- **FL Chart** para gráficos e indicadores
- **Audioplayers** para alertas sonoros do Pomodoro
- **Shadcn UI** para componentes visuais

### Backend

- **Python**
- **Django**
- **Django REST Framework**
- **Django CORS Headers**
- **SQLite** no ambiente local
- Suporte a **PostgreSQL** no ambiente de produção
- **Gunicorn** e **WhiteNoise** para deploy

### Desenvolvimento e entrega

- **Git e GitHub**
- **GitHub Issues e Projects**
- **GitHub Actions**
- Testes automatizados de frontend e backend
- Deploy do frontend no **GitHub Pages**

---

## 🚀 Features

Com o Focus, o estudante pode:

- Criar uma conta e realizar login;
- Cadastrar e organizar disciplinas;
- Criar provas, trabalhos, eventos e outras atividades acadêmicas;
- Visualizar compromissos em uma agenda;
- Planejar e registrar sessões de estudo;
- Utilizar um timer **Pomodoro** com:
  - período de foco;
  - pausa curta;
  - pausa longa;
  - associação com disciplinas e sessões;
  - registro de interrupções;
  - avaliação de produtividade;
- Criar e consultar notas de estudo;
- Organizar uma biblioteca de materiais;
- Definir metas semanais;
- Acompanhar a consistência dos estudos;
- Consultar relatórios e indicadores;
- Receber insights baseados nas sessões realizadas;
- Utilizar uma interface responsiva em diferentes tamanhos de tela.

---

## ⌨️ Keyboard Shortcuts

Atualmente, o Focus não possui atalhos de teclado exclusivos configurados. A navegação é realizada pelos botões, menus e campos disponíveis na interface.

Como melhoria futura, podem ser adicionados atalhos como:

| Atalho | Ação sugerida |
|---|---|
| `Ctrl + N` | Criar uma nova atividade |
| `Ctrl + P` | Abrir o Pomodoro |
| `Ctrl + D` | Abrir as disciplinas |
| `Ctrl + M` | Abrir os materiais |
| `Espaço` | Iniciar ou pausar o Pomodoro |
| `Esc` | Fechar janelas e formulários |

---

## 🔄 O Processo

O desenvolvimento foi organizado de forma colaborativa, utilizando práticas de Engenharia de Software:

1. As necessidades do sistema foram transformadas em histórias e tarefas no GitHub Issues;
2. As atividades foram organizadas em um quadro do GitHub Projects;
3. Cada funcionalidade foi desenvolvida em uma branch específica;
4. O frontend foi construído com Flutter e integrado à API criada com Django REST Framework;
5. Foram implementados testes para validar regras de negócio, componentes e integrações;
6. As alterações foram enviadas por Pull Requests para revisão;
7. O GitHub Actions passou a executar automaticamente:
   - testes do backend;
   - análise estática do Flutter;
   - testes do frontend;
   - build da aplicação Web;
8. Após a validação, o frontend foi publicado no GitHub Pages.

---

## 🧠 O Que Eu Aprendi

Durante o desenvolvimento do Focus, aprendi e pratiquei:

- Desenvolvimento de uma aplicação full stack;
- Criação e consumo de APIs REST;
- Integração entre Flutter e Django;
- Gerenciamento de estado com Provider;
- Modelagem e persistência de dados;
- Criação de interfaces responsivas;
- Implementação de funcionalidades baseadas em regras de negócio;
- Escrita e execução de testes automatizados;
- Configuração de CI/CD com GitHub Actions;
- Trabalho colaborativo com branches, commits, Pull Requests e revisão de código;
- Resolução de conflitos de merge;
- Organização de tarefas utilizando Issues e Projects;
- Transformação de dados de estudo em métricas e insights úteis para o usuário.

---

## 🔧 Como Ele Pode Ser Melhorado

Algumas melhorias que podem ser desenvolvidas futuramente:

- Adicionar atalhos de teclado e ampliar os recursos de acessibilidade;
- Criar notificações e lembretes para sessões, provas e trabalhos;
- Integrar o sistema ao Google Calendar;
- Permitir funcionamento offline com sincronização posterior;
- Tornar persistentes todas as listas de tarefas das atividades;
- Criar testes de ponta a ponta;
- Ampliar a cobertura dos testes automatizados;
- Permitir exportação de relatórios em PDF ou CSV;
- Adicionar mais opções de personalização do Pomodoro;
- Criar recomendações de estudo mais personalizadas;
- Melhorar o onboarding para novos usuários;
- Adicionar gráficos comparativos por disciplina e período;
- Disponibilizar uma versão instalável como PWA.

---

## ▶️ Como Iniciar o Projeto

### Pré-requisitos

Antes de começar, instale:

- [Git](https://git-scm.com/)
- [Python 3.11 ou superior](https://www.python.org/)
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Google Chrome, Edge ou outro dispositivo compatível com Flutter

### 1. Clonar o repositório

```bash
git clone https://github.com/ES2-UFPI/Focus.git
cd Focus
```

### 2. Iniciar o backend

#### Windows — PowerShell

```powershell
cd backend

py -3.11 -m venv venv
.\venv\Scripts\Activate.ps1

python -m pip install --upgrade pip setuptools wheel
python -m pip install -r requirements.txt

python manage.py migrate
python manage.py runserver 127.0.0.1:8000
```

#### Linux ou macOS

```bash
cd backend

python3 -m venv venv
source venv/bin/activate

python -m pip install --upgrade pip setuptools wheel
python -m pip install -r requirements.txt

python manage.py migrate
python manage.py runserver 127.0.0.1:8000
```

O backend ficará disponível em:

```text
http://127.0.0.1:8000
```

### 3. Iniciar o frontend

Abra outro terminal na raiz do projeto:

```bash
cd frontend
flutter pub get
flutter run -d chrome --web-hostname 127.0.0.1 --web-port 5173
```

O frontend ficará disponível em:

```text
http://127.0.0.1:5173
```

> Mantenha o backend em execução enquanto estiver utilizando o frontend.

### 4. Executar os testes

#### Backend

```bash
cd backend
python manage.py test
```

#### Frontend

```bash
cd frontend
flutter analyze
flutter test
```

### 5. Gerar o build Web

```bash
cd frontend
flutter build web
```

---

## 🎥 Vídeo do Projeto

Adicione abaixo o link do vídeo de apresentação ou demonstração do Focus:

```markdown
[▶️ Assistir ao vídeo de demonstração] (https://youtu.be/kiSLTTfJfxI)


```

---

<div align="center">

Desenvolvido durante a disciplina de **Engenharia de Software II — UFPI**.

</div>
