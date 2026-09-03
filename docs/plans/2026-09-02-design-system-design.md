# Design Document: Design System Pastel & Leveza para Seapruma (PPVDigital)

**Data:** 2026-09-02  
**Status:** Aprovado  
**Autor:** Antigravity (Pair Programming com Usuário)

---

## 1. Visão Geral e Objetivos

O objetivo deste Design System é transformar a experiência visual do aplicativo Seapruma (PPVDigital), substituindo cores saturadas/escuras e tipografia pesada por uma identidade visual caracterizada por **ar de leveza, serenidade e tons pastéis elegantes**.

Além dos componentes em código, o Design System estabelece **governança obrigatória contínua**: qualquer alteração futura em telas, widgets ou regras de layout deverá obrigatoriamente consultar a documentação (`docs/design_system.md`) e utilizar os tokens de design.

---

## 2. Princípios de Design

1. **Leveza & Arejamento:**
   - Espaçamento generoso e respirável.
   - Cantos suavemente arredondados (`AppRadius`), eliminando arestas duras.
   - Sombras ultra-leves e difusas (`AppShadows`), simulando luz natural suave sem peso visual.

2. **Cores Pastéis & Conforto Visual:**
   - Cores principais suaves: Menta Suave, Lavanda, Pêssego/Coral, Céu Sereno, Manteiga e Rosa Suave.
   - Fundo neutro acolhedor (`#F9FAFC` no Light) em vez de branco puro ofuscante (`#FFFFFF`), com superfícies de cards em branco puro contornadas por bordas delicadas (`#E8EDF2`).
   - Dark mode adaptado em ardósia/carvão suave (`#1A1D24` / `#242832`), mantendo tons pastéis desaturados para descanso ocular.

3. **Tipografia Geométrica e Moderna:**
   - Adoção de `Plus Jakarta Sans` (com fallback robusto via Google Fonts/Inter), conferindo clareza, modernidade e legibilidade superior em comparação com fontes ornamentais anteriores.

4. **Consistência por Tokens:**
   - Proibição de valores hardcoded (ex: `Colors.red`, `Colors.amber`, `EdgeInsets.all(17)`, `BorderRadius.circular(9)`). Todo elemento deve derivar de `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius` ou `Theme.of(context)`.

---

## 3. Especificação dos Tokens

### 3.1. Cores Pastéis (`AppColors`)
- **Primary (Menta Pastel):**
  - Light: `#7CB9A8` (onPrimary: `#FFFFFF`, Container: `#E4F4EE`, onContainer: `#1F4D41`)
  - Dark: `#9FD3C5` (onPrimary: `#1A372F`, Container: `#2B5347`, onContainer: `#CEEFE6`)
- **Secondary (Lavanda Pastel):**
  - Light: `#9B9CD6` (onSecondary: `#FFFFFF`, Container: `#EAEBFC`, onContainer: `#323368`)
  - Dark: `#C1C2EB` (onSecondary: `#2B2C58`, Container: `#3E4078`, onContainer: `#ECECFD`)
- **Tertiary / Accent (Pêssego/Coral Pastel):**
  - Light: `#F5B1A2` (Container: `#FEECE8`, onContainer: `#6B2A1E`)
  - Dark: `#F9CECE`
- **Semânticas:**
  - **Success:** `#77CFA6` / Container `#E3F8EE` / onContainer `#175638`
  - **Warning:** `#F8D882` / Container `#FDF6DE` / onContainer `#664D00`
  - **Error:** `#F49E9E` / Container `#FDEAEA` / onContainer `#6B1F1F`
  - **Info:** `#8EC7EB` / Container `#E5F4FD` / onContainer `#134B6E`

### 3.1.1. Cores Personalizáveis pelo Usuário (`AppColors.customizablePastelColors`)
Para preservar a liberdade do usuário de customizar cores de hábitos, tarefas e categorias, disponibilizamos uma ampla cartela (24 opções ricas e equilibradas) estritamente aderentes à estética pastel de leveza:
1. Menta Pastel (`#7CB9A8`)
2. Salvia Pastel (`#95B8A2`)
3. Pistache Pastel (`#A8D5BA`)
4. Espuma do Mar / Seafoam (`#94D2BD`)
5. Turquesa Suave (`#80CED7`)
6. Gelo / Ice Blue (`#A2D2DF`)
7. Céu Sereno (`#97C8EB`)
8. Azul Bebê Pastel (`#A8D8EA`)
9. Hortênsia / Periwinkle (`#9FB1D9`)
10. Lavanda Suave (`#A5A6D6`)
11. Lilás Pastel (`#B8A7EA`)
12. Ametista Claro (`#CDB4DB`)
13. Ameixa Suave / Plum (`#D8A7CA`)
14. Rosa Pastel / Blush (`#F4ACB7`)
15. Algodão Doce (`#FFCAD4`)
16. Salmão Pastel (`#F7A399`)
17. Pêssego Pastel (`#F5B1A2`)
18. Coral Suave (`#F8B195`)
19. Damasco Suave (`#FDC5A1`)
20. Manteiga Pastel (`#FBE29D`)
21. Baunilha / Creme Quente (`#F6E7B0`)
22. Chá de Camomila (`#E8DAB2`)
23. Areia Suave (`#D8D4D0`)
24. Ardósia Pastel (`#A0AEC0`)

Todas as telas com seletor de cores (`tarefas_habitos_layout.dart`, `criar_editar_categoria_page.dart`, `criar_editar_categoria_transacao_page.dart`) passam a consumir diretamente `AppColors.customizablePastelColors`.
  - `backgroundLight`: `#F9FAFC`
  - `surfaceLight`: `#FFFFFF`
  - `borderLight`: `#E8EDF2`
  - `textPrimaryLight`: `#2D3748`
  - `textSecondaryLight`: `#718096`
  - `backgroundDark`: `#16191F`
  - `surfaceDark`: `#20242D`
  - `borderDark`: `#2E3543`
  - `textPrimaryDark`: `#F1F3F7`
  - `textSecondaryDark`: `#9AA5B6`

### 3.2. Espaçamentos (`AppSpacing`)
- `xxs`: 2.0
- `xs`: 4.0
- `sm`: 8.0
- `md`: 16.0
- `lg`: 24.0
- `xl`: 32.0
- `xxl`: 48.0

### 3.3. Curvaturas (`AppRadius`)
- `xs`: 4.0
- `sm`: 8.0
- `md`: 12.0
- `lg`: 16.0
- `xl`: 24.0
- `full`: 999.0

### 3.4. Sombras (`AppShadows`)
- `soft`: `BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))`
- `card`: `BoxShadow(color: Color(0x0D1A202C), blurRadius: 16, offset: Offset(0, 6))`
- `floating`: `BoxShadow(color: Color(0x121A202C), blurRadius: 24, offset: Offset(0, 10))`

---

## 4. Governança e Diretrizes para Agentes

1. **Documento Vivo:**
   - Criação de `docs/design_system.md` contendo a referência completa visual e de código.
2. **Regra Inviolável no `AGENTS.md`:**
   - Uma nova regra no `.agents/AGENTS.md` e `.agent/AGENTS.md` proibindo cores e dimensões avulsas sem consulta prévia a `docs/design_system.md`.
3. **Atualização do `README.md`:**
   - Seção dedicada ao Design System com instruções para desenvolvedores e novos módulos.

---

## 5. Adequação de Componentes

Componentes centrais que serão atualizados para refletir o novo padrão:
- `lib/theme.dart`: Esquemas de cores Material 3 e temas globais de widgets atualizados com os tokens pastéis.
- `lib/util.dart`: Tipografia atualizada para `Plus Jakarta Sans`.
- `tarefa_habito_card_widget.dart`: Cards de hábitos/tarefas com badges pastéis, bordas suaves e sombras leves.
- `seletor_mes_widget.dart`: Pílulas e seletores mensais com bordas arredondadas e cores calmas.
- `home_page.dart`: Cartões de módulos e categorias harmonizados para a paleta pastel leve.
