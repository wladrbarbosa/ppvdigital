# Implementação da Política de Privacidade e Termos de Serviço do Seapruma

> **For Antigravity:** REQUIRED WORKFLOW: Use `.agent/workflows/execute-plan.md` to execute this plan in single-flow mode.

**Goal:** Criar duas páginas HTML públicas e estáticas (`web/privacidade.html` e `web/termos.html`) em conformidade com o Design System Pastel & Leveza do Seapruma, cobrindo LGPD, requisitos da Google Play Store e a Política de Dados de Usuário do Google (escopo Google Drive `drive.file`), com testes automatizados de validação de conteúdo.

**Architecture:** Páginas HTML5 autocontidas com folha de estilos CSS embutida, tipografia Google Fonts `Plus Jakarta Sans`, navegação rápida cruzada entre os documentos e com o app Flutter Web, sumário por âncoras e textos jurídicos estruturados sob a identidade exclusiva da marca Seapruma.

**Tech Stack:** HTML5 semântico, CSS3 Moderno (Design System Pastel com Flexbox/Grid e variáveis CSS), Dart Test para validação estática de conformidade e integridade dos documentos.

---

### Task 1: Testes de Validação das Páginas Legais (`test/web/legal_pages_test.dart`)

**Files:**
- Create: `test/web/legal_pages_test.dart`

**Step 1: Escrever os testes que validam as regras de negócio e conformidade das páginas**
- Verificar que `web/privacidade.html` existe e é não vazia.
- Verificar que `web/termos.html` existe e é não vazia.
- Garantir que a marca utilizada é estritamente **Seapruma** e que nenhuma ocorrência de "PPVDigital" está presente nas páginas.
- Validar seções críticas da Política de Privacidade:
  - Escopo restrito do Google Drive (`drive.file`).
  - LGPD (Lei 13.709/2018) e direitos do titular (Art. 18).
  - Exclusão de conta e eliminação de dados.
  - E-mail de suporte (`suporte@seapruma.app`).
  - Link de navegação para `termos.html`.
- Validar seções críticas dos Termos de Serviço:
  - Aceitação dos termos e objeto da plataforma.
  - Natureza não consultiva financeira.
  - Propriedade dos dados do usuário.
  - Link de navegação para `privacidade.html`.
  - Link de retorno ao app (`index.html` ou `./`).

**Step 2: Executar o teste para verificar a falha esperada (TDD)**
- Executar: `fvm flutter test test/web/legal_pages_test.dart`
- Resultado esperado: FALHA (arquivos HTML ainda não existem).

---

### Task 2: Implementação da Política de Privacidade (`web/privacidade.html`)

**Files:**
- Create: `web/privacidade.html`

**Step 1: Criar o arquivo HTML autocontido com Design System Pastel**
- Incluir metatags SEO, OpenGraph e responsivas (`viewport`).
- Importar fonte `Plus Jakarta Sans` via Google Fonts com `preconnect`.
- Declarar variáveis CSS com a paleta pastel oficial (`--bg: #F9FAFC`, `--card: #FFFFFF`, `--border: #E8EDF2`, `--primary: #7CB9A8`, `--primary-light: #E4F4EE`, `--secondary: #9B9CD6`, `--text: #2D3748`, `--text-muted: #718096`).
- Implementar barra de cabeçalho com logotipo em vetor do Seapruma e seletor em pílulas com link ativo para Política de Privacidade e inativo para Termos de Serviço.
- Adicionar sumário interativo com links de âncora (`#coleta`, `#finalidade`, `#googledrive`, `#lgpd`, `#seguranca`, `#exclusao`, `#contato`).
- Incluir as cláusulas jurídicas completas, com destaque visual em container menta suave para a declaração de uso do escopo `drive.file` do Google Drive.
- Adicionar rodapé com canais de contato e copyright.

**Step 2: Executar os testes para validar o progresso**
- Executar: `fvm flutter test test/web/legal_pages_test.dart`
- Resultado esperado: Passar nos testes de `privacidade.html` e falhar nos testes restantes de `termos.html`.

---

### Task 3: Implementação dos Termos de Serviço (`web/termos.html`)

**Files:**
- Create: `web/termos.html`

**Step 1: Criar o arquivo HTML autocontido com Design System Pastel**
- Manter total harmonia de layout, metatags, variáveis CSS e tipografia com `privacidade.html`.
- Implementar barra de cabeçalho com pílula ativa para Termos de Serviço e inativa para Política de Privacidade.
- Adicionar sumário interativo com links de âncora (`#aceitacao`, `#servicos`, `#responsabilidade`, `#propriedade`, `#backups`, `#isencao`, `#rescisao`, `#foro`).
- Detalhar as cláusulas contratuais de uso do Seapruma (propriedade dos dados, integridade dos backups, isenção de consultoria financeira, encerramento de conta e foro).
- Adicionar rodapé padronizado.

**Step 2: Executar os testes automatizados completos**
- Executar: `fvm flutter test test/web/legal_pages_test.dart`
- Resultado esperado: 100% dos testes APROVADOS.

---

### Task 4: Verificação Geral e Análise Estática

**Step 1: Executar análise estática do projeto**
- Executar: `fvm flutter analyze`
- Resultado esperado: Sem erros ou alertas no código.

**Step 2: Executar suíte completa de testes**
- Executar: `fvm flutter test`
- Resultado esperado: Todos os testes existentes e novos passando (280+ testes com 100% de sucesso).

**Step 3: Commit das alterações**
- `git add web/privacidade.html web/termos.html test/web/legal_pages_test.dart docs/plans/`
- `git commit -m "feat(web): add privacy policy and terms of service pages with pastel design system"`
