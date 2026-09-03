# Design System Seapruma (PPVDigital) - Pastel & Leveza

## 1. Visão Geral e Filosofia

O **Design System Pastel & Leveza** do Seapruma tem como propósito oferecer uma interface visual serena, acolhedora, moderna e extremamente respirável. O design substitui contrastes duros e cores saturadas agressivas por uma paleta suave em tons pastéis harmônicos, tipografia geométrica humanista ([Plus Jakarta Sans](https://fonts.google.com/specimen/Plus+Jakarta+Sans)), curvaturas arredondadas e sombras ultra-leves e translúcidas.

---

## 2. Princípios Fundamentais

1. **Leveza & Arejamento Visual**:
   - Espaçamentos escalonados e consistentes (`AppSpacing`).
   - Cantos generosamente arredondados (`AppRadius`), eliminando arestas duras.
   - Sombras translúcidas e difusas (`AppShadows`), evitando bordas escuras pesadas.
2. **Harmonia em Tons Pastéis**:
   - Cores primárias, secundárias e semânticas em tons pastéis balanceados (`AppColors`).
   - Fundos acolhedores (`#F9FAFC` no Light e ardósia suave `#16191F` no Dark).
   - Superfícies de cartões brancos com bordas sutis (`#E8EDF2`).
3. **Tipografia Geométrica e Moderna**:
   - `Plus Jakarta Sans` para títulos e textos, garantindo legibilidade e ar contemporâneo.
4. **Governança Estrita por Tokens**:
   - **Proibido** o uso de valores hardcoded (ex.: `Colors.amber`, `Colors.red`, `EdgeInsets.all(17)`, `BorderRadius.circular(9)`).
   - Toda cor, espaçamento, curvatura ou sombra deve vir de `lib/design_system/` ou de `Theme.of(context)`.

---

## 3. Tokens do Sistema (`lib/design_system/`)

### 3.1. Cores (`AppColors`)

#### Cores Principais (Tema Claro / Light)
| Token | Cor Hex | Uso |
|---|---|---|
| `AppColors.primaryLight` | `#7CB9A8` | Menta Pastel (Ações principais, botões primários) |
| `AppColors.primaryLightContainer` | `#E4F4EE` | Superfície suave para seleção e destaque |
| `AppColors.secondaryLight` | `#9B9CD6` | Lavanda Pastel (Ações secundárias, badges) |
| `AppColors.secondaryLightContainer` | `#EAEBFC` | Superfície secundária sutil |
| `AppColors.tertiaryLight` | `#F5B1A2` | Pêssego/Coral Pastel (Destaque, acentos) |
| `AppColors.tertiaryLightContainer` | `#FEECE8` | Superfície de destaque suave |
| `AppColors.backgroundLight` | `#F9FAFC` | Fundo principal da aplicação |
| `AppColors.surfaceLight` | `#FFFFFF` | Fundo de cartões e modais |
| `AppColors.borderLight` | `#E8EDF2` | Bordas delicadas de cartões e divisores |
| `AppColors.textPrimaryLight` | `#2D3748` | Texto principal de alto contraste e leitura |
| `AppColors.textSecondaryLight` | `#718096` | Legendas, datas e textos de apoio |

#### Cores Principais (Tema Escuro / Dark)
| Token | Cor Hex | Uso |
|---|---|---|
| `AppColors.primaryDark` | `#9FD3C5` | Menta suave desaturado |
| `AppColors.secondaryDark` | `#C1C2EB` | Lavanda suave desaturado |
| `AppColors.tertiaryDark` | `#F9CECE` | Pêssego suave desaturado |
| `AppColors.backgroundDark` | `#16191F` | Fundo escuro em tom ardósia suave |
| `AppColors.surfaceDark` | `#20242D` | Superfície de cartões no modo escuro |
| `AppColors.borderDark` | `#2E3543` | Bordas sutis no modo escuro |
| `AppColors.textPrimaryDark` | `#F1F3F7` | Texto principal claro |
| `AppColors.textSecondaryDark` | `#9AA5B6` | Texto secundário no modo escuro |

#### Cores Semânticas
| Estado | Cor Base | Container Suave | Texto / onContainer |
|---|---|---|---|
| **Sucesso** | `AppColors.pastelSuccess` (`#77CFA6`) | `AppColors.pastelSuccessContainer` (`#E3F8EE`) | `AppColors.onPastelSuccessContainer` (`#175638`) |
| **Aviso** | `AppColors.pastelWarning` (`#F8D882`) | `AppColors.pastelWarningContainer` (`#FDF6DE`) | `AppColors.onPastelWarningContainer` (`#664D00`) |
| **Erro / Recaída** | `AppColors.pastelError` (`#F49E9E`) | `AppColors.pastelErrorContainer` (`#FDEAEA`) | `AppColors.onPastelErrorContainer` (`#6B1F1F`) |
| **Informativo** | `AppColors.pastelInfo` (`#8EC7EB`) | `AppColors.pastelInfoContainer` (`#E5F4FD`) | `AppColors.onPastelInfoContainer` (`#134B6E`) |

#### Cartela de Cores Personalizáveis (`AppColors.customizablePastelColors`)
Disponibiliza **24 cores pastéis refinadas** para seleção do usuário ao criar categorias, hábitos, tarefas e contas financeiras:
1. `Menta Pastel` (`#7CB9A8`)
2. `Salvia Pastel` (`#95B8A2`)
3. `Pistache Pastel` (`#A8D5BA`)
4. `Espuma do Mar` (`#94D2BD`)
5. `Turquesa Suave` (`#80CED7`)
6. `Gelo Sereno` (`#A2D2DF`)
7. `Céu Sereno` (`#97C8EB`)
8. `Azul Bebê Pastel` (`#A8D8EA`)
9. `Hortênsia` (`#9FB1D9`)
10. `Lavanda Suave` (`#A5A6D6`)
11. `Lilás Pastel` (`#B8A7EA`)
12. `Ametista Claro` (`#CDB4DB`)
13. `Ameixa Suave` (`#D8A7CA`)
14. `Rosa Pastel` (`#F4ACB7`)
15. `Algodão Doce` (`#FFCAD4`)
16. `Salmão Pastel` (`#F7A399`)
17. `Pêssego Pastel` (`#F5B1A2`)
18. `Coral Suave` (`#F8B195`)
19. `Damasco Suave` (`#FDC5A1`)
20. `Manteiga Pastel` (`#FBE29D`)
21. `Baunilha Suave` (`#F6E7B0`)
22. `Chá de Camomila` (`#E8DAB2`)
23. `Areia Suave` (`#D8D4D0`)
24. `Ardósia Pastel` (`#A0AEC0`)

---

### 3.2. Espaçamento (`AppSpacing`)

| Token | Valor (dp) | Exemplo de Uso |
|---|---|---|
| `AppSpacing.xxs` | `2.0` | Micro-espaçamento interno de ícones e indicadores |
| `AppSpacing.xs` | `4.0` | Espaço entre ícone e rótulo |
| `AppSpacing.sm` | `8.0` | Padding vertical compacto, margens de chips |
| `AppSpacing.mdSm` | `12.0` | Padding interno de botões e cartões compactos |
| `AppSpacing.md` | `16.0` | Espaçamento padrão de tela e formulários |
| `AppSpacing.lg` | `24.0` | Margens de seções e modais |
| `AppSpacing.xl` | `32.0` | Divisão de grandes blocos de conteúdo |
| `AppSpacing.xxl` | `48.0` | Top margins e hero sections |

---

### 3.3. Curvaturas (`AppRadius`)

| Token | Valor (dp) | BorderRadius | Aplicação |
|---|---|---|---|
| `AppRadius.xs` | `4.0` | `AppRadius.roundedXs` | Indicadores minúsculos, micro tags |
| `AppRadius.sm` | `8.0` | `AppRadius.roundedSm` | Badges, campos de texto compactos |
| `AppRadius.md` | `12.0` | `AppRadius.roundedMd` | Botões, inputs de formulário |
| `AppRadius.lg` | `16.0` | `AppRadius.roundedLg` | Cartões de lista e itens do dashboard |
| `AppRadius.xl` | `24.0` | `AppRadius.roundedXl` | Diálogos modais, bottom sheets |
| `AppRadius.full`| `999.0`| `AppRadius.roundedFull`| Pílulas, chips, botões redondos |

---

### 3.4. Sombras (`AppShadows`)

- **`AppShadows.soft`**: `BoxShadow(color: Color(0x0A1A202C), blurRadius: 10, offset: Offset(0, 4))` - para cartões em repouso.
- **`AppShadows.card`**: `BoxShadow(color: Color(0x0D1A202C), blurRadius: 16, offset: Offset(0, 6))` - para cartões destacados e foco.
- **`AppShadows.floating`**: `BoxShadow(color: Color(0x141A202C), blurRadius: 24, offset: Offset(0, 10))` - para Floating Action Buttons (FAB), menus suspensos e modais.
- **`AppShadows.none`**: Lista vazia para componentes com visual flat limpo e contorno sutil.

---

### 3.5. Decorações Visuais (`AppDecorations`)

Utilitários práticos para estilizar containers com consistência visual imediata:

```dart
// Cartão com leveza visual, borda delicada e sombra difusa
Container(
  decoration: AppDecorations.card(
    isDark: Theme.of(context).brightness == Brightness.dark,
  ),
  child: ...
);

// Badge / Tag translúcida em formato de pílula com cores pastéis
Container(
  decoration: AppDecorations.badge(
    backgroundColor: AppColors.pastelSuccessContainer,
    borderColor: AppColors.pastelSuccess,
  ),
  child: Text(
    'Concluído',
    style: TextStyle(color: AppColors.onPastelSuccessContainer),
  ),
);

// Input container padronizado
Container(
  decoration: AppDecorations.input(
    isDark: isDark,
    isFocused: hasFocus,
  ),
  child: ...
);
```

---

## 4. Regras de Governança para Desenvolvedores e Agentes

> [!IMPORTANT]
> **REQUISITO MANDATÓRIO DE GOVERNANÇA**:
> Qualquer desenvolvedor ou agente de inteligência artificial que criar ou alterar telas, widgets ou elementos de UI **DEVE OBRIGATORIAMENTE**:
> 1. Consultar este documento (`docs/design_system.md`).
> 2. Utilizar exclusivamente os tokens de `lib/design_system/design_system.dart` (`AppColors`, `AppSpacing`, `AppRadius`, `AppShadows`, `AppDecorations`, `AppTypography`) ou estilos derivados de `Theme.of(context)`.
> 3. **Nunca** utilizar cores duras avulsas como `Colors.red`, `Colors.amber`, `Colors.deepPurple`, `Colors.blue` ou hexadecimais arbitrários inline.
> 4. Quando uma tela permitir ao usuário escolher cores (ex.: categorias, tarefas, hábitos, contas), utilizar a paleta oficial `AppColors.customizablePastelColors`.
> 5. Para botões, inputs, diálogos e cartões, priorizar os temas globais já integrados ao `MaterialTheme` em `lib/theme.dart`.
