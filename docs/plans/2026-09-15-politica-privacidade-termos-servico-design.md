# Documento de Design: Política de Privacidade e Termos de Serviço do Seapruma

Data: 15 de setembro de 2026  
Status: Aprovado  
Autor: Equipe Seapruma  

---

## 1. Visão Geral e Contexto

O objetivo deste projeto é disponibilizar duas páginas HTML públicas e estáticas para o aplicativo **Seapruma**:
1. **Política de Privacidade** (`web/privacidade.html`)
2. **Termos de Serviço** (`web/termos.html`)

Essas páginas atendem diretamente aos seguintes propósitos:
- Fornecer URLs públicas e permanentes para publicação e conformidade na **Google Play Store** e **Apple App Store**.
- Atender aos requisitos rigorosos do **Google Cloud Console OAuth Verification** quanto ao uso do escopo restrito do Google Drive (`https://www.googleapis.com/auth/drive.file`) para backup e restauração do Seapruma.
- Cumprir integralmente a **LGPD (Lei Geral de Proteção de Dados - Lei 13.709/2018)** no Brasil, detalhando direitos de acesso, exclusão de dados e segurança.
- Oferecer uma experiência de leitura polida aos usuários do Seapruma, alinhada à identidade visual do aplicativo.

> **Importante:** Em consonância com as diretrizes do projeto, o nome **Seapruma** é utilizado com exclusividade em todos os documentos, textos, títulos e metadados, sem menção a nomes legados.

---

## 2. Arquitetura e Decisões Técnicas

### 2.1. Abordagem: Páginas Autocontidas com CSS Embutido
- **Localização dos Arquivos**: Diretamente em `web/privacidade.html` e `web/termos.html`.
- **Compatibilidade Flutter Web**: O diretório `web/` é automaticamente embutido na pasta `build/web/` ao executar `flutter build web`, sendo servido sob as rotas relativas `/privacidade.html` e `/termos.html` sem qualquer configuração adicional de servidor ou roteamento.
- **Autonomia Total**: Cada arquivo é autocontido, incluindo tags semânticas HTML5, metatags OpenGraph/SEO e folha de estilo moderna no elemento `<style>`. Dispensam dependências de build ou bundlers adicionais e podem ser abertos localmente (`file://`) ou hospedados em qualquer CDN ou servidor estático.
- **Tipografia**: Integração com a fonte oficial do aplicativo, `Plus Jakarta Sans`, via Google Fonts com `<link rel="preconnect">` para carregamento de alta performance.

---

## 3. Design System Pastel & Leveza (Identidade Visual)

As páginas reproduzem os princípios visuais definidos em `docs/design_system.md`:

| Elemento | Token / Valor Hex | Aplicação |
|---|---|---|
| **Fundo da Página** | `#F9FAFC` | Fundo claro, sereno e arejado |
| **Superfície do Cartão** | `#FFFFFF` | Cartão central de leitura com `max-width: 880px` |
| **Bordas** | `#E8EDF2` | Contorno sutil com raio suave (`border-radius: 16px`) |
| **Sombra** | `0 4px 24px rgba(0, 0, 0, 0.04)` | Sombra ultra-leve difusa |
| **Cor Primária** | `#7CB9A8` | Menta Pastel (títulos, ícone da marca, abas ativas) |
| **Container Primário** | `#E4F4EE` | Destaques suaves, badges e caixas informativas |
| **Cor Secundária** | `#9B9CD6` | Lavanda Pastel (subtítulos e links interativos) |
| **Texto Principal** | `#2D3748` | Alto contraste para leitura prolongada e acessível |
| **Texto Secundário** | `#718096` | Metadados, datas e legendas de apoio |

### 3.1. Componentes de Interface
1. **Barra Superior (Header / Brand Navigation)**:
   - Logomarca em vetor estilizado com o nome **Seapruma**.
   - Navegação cruzada estilo abas/pílulas (`pills`):
     - Botão ativo/inativo para **Política de Privacidade** (`privacidade.html`).
     - Botão ativo/inativo para **Termos de Serviço** (`termos.html`).
     - Botão de atalho "Voltar ao App" (`index.html`).
2. **Banner de Cabeçalho do Documento**:
   - Título principal (`h1`), subtítulo explicativo e badge com data de vigência: `15 de setembro de 2026`.
3. **Sumário Rápido (Table of Contents)**:
   - Caixa com links de âncora navegáveis para rápido salto entre seções jurídicas.
4. **Blocos de Destaque Semântico**:
   - Caixas de aviso estilizadas para regras críticas (ex.: uso restrito do Google Drive, canais de exclusão de dados).
5. **Rodapé Unificado**:
   - Informações de copyright, e-mail de contato (`suporte@seapruma.app`) e links para retorno.

---

## 4. Estrutura de Conteúdo

### 4.1. Política de Privacidade (`web/privacidade.html`)
1. **Visão Geral e Identificação do Seapruma**
2. **Princípios de Privacidade e Base Legal (LGPD)**
3. **Dados Tratados e Finalidades de Uso**:
   - Dados cadastrais (e-mail, identificador de sessão gerenciados pelo Appwrite).
   - Dados gerenciais inseridos pelo usuário (finanças, contas, categorias, tarefas, hábitos e metas).
   - Armazenamento local SQLite/Drift no dispositivo do usuário (offline-first).
4. **Integração com Google Drive e Escopo OAuth (`drive.file`)**:
   - Declaração explícita de uso restrito do escopo `drive.file`.
   - Garantia de que o Seapruma acessa exclusivamente os arquivos criados pelo próprio aplicativo na pasta de backups (`Seapruma_Backup_*.json`).
   - Política de Não Comercialização e Não Compartilhamento com terceiros, parceiros de publicidade ou para treinamento de modelos de IA.
5. **Segurança e Armazenamento dos Dados**:
   - Criptografia em trânsito (HTTPS / TLS / WSS) e validação de integridade por hash SHA-256.
6. **Direitos do Titular (Art. 18 da LGPD)**:
   - Confirmação de tratamento, acesso, correção, anonimização e portabilidade.
   - **Procedimento para Exclusão de Conta e Eliminação Total de Dados**.
7. **Cookies e Armazenamento Local**
8. **Alterações nesta Política e Contato do Suporte/Encarregado**

### 4.2. Termos de Serviço (`web/termos.html`)
1. **Aceitação dos Termos e Condições**
2. **Definição e Finalidade da Plataforma Seapruma**
3. **Cadastro, Credenciais e Conduta do Usuário**
4. **Propriedade dos Dados e Responsabilidade pelos Registros**
5. **Funcionalidades de Backup e Nuvem (Google Drive e Appwrite)**
6. **Natureza Não Consultiva (Isenção de Consultoria Financeira Formal)**
7. **Propriedade Intelectual do Aplicativo**
8. **Disponibilidade do Serviço e Limitação de Responsabilidade**
9. **Modificações dos Termos e Rescisão de Conta**
10. **Legislação Aplicável, Foro e Suporte**

---

## 5. Plano de Verificação
- **Validação de Sintaxe HTML5 e Semântica**: Verificação com estrutura W3C válida, acessibilidade para leitores de tela e metatags completas.
- **Responsividade Multiplataforma**: Testes em viewport mobile (375px / 414px) e desktop (1200px+).
- **Links Cruzados e Navegação de Âncoras**: Confirmação do funcionamento dos botões de alternância e links internos.
- **Inspeção Visual**: Confirmação visual da harmonia com o Design System Pastel.
