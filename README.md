# 🧪 QA-FS-Redmine

> Skill do Claude para automação de processos de Q.A no Redmine.

Essa skill conecta o Claude diretamente ao Redmine, permitindo gerenciar casos, iniciar testes, gerar planos de teste, registrar situações e finalizar casos — tudo sem sair da conversa.

---

## ✨ Comandos

| Comando | Descrição |
|---|---|
| `/inicia-teste` | Atribui o caso ao usuário logado e muda o status para **Em Testes** |
| `/plano-teste` | Lê toda a documentação do caso e gera um **Plano de Teste** completo no padrão da equipe |
| `/registrar-situacao` | Formata e registra uma situação encontrada durante os testes, com suporte a anexo de imagem |
| `/finalizar-caso` | Identifica o dev, verifica plano de teste, preenche CheckList Resolvido, Tamanho SP e fecha o caso como **Resolvido** |
| `/refinar-caso` | Registra a pontuação de refinamento (Dev, Teste e Cenário) como tabela no caso |
| `/criterios-aceitacao` | Lista todos os critérios de aceitação documentados no caso |
| `/info-caso` | Exibe todas as informações do caso: descrição, histórico completo, anexos e alterações |

---

## ⚡ Integração com MCP Redmine

A skill utiliza o **MCP Redmine** para todas as operações — sem scripts PowerShell, sem overhead de processo. As chamadas ao Redmine são feitas diretamente pelo Claude via ferramentas nativas do MCP, tornando as consultas e atualizações muito mais rápidas.

**Ferramentas MCP utilizadas:**

| Ferramenta | O que faz |
|---|---|
| `get_issue` | Busca dados do caso com journals, anexos e campos customizados |
| `get_journals` | Retorna histórico de notas e alterações |
| `get_current_user` | Identifica o usuário autenticado |
| `update_issue` | Atualiza status, atribuição e campos customizados |
| `post_note` | Posta nota no caso com suporte a anexos |
| `upload_file` | Faz upload de arquivo e retorna token para anexo |
| `update_journal` | Edita texto de um journal existente |
| `list_statuses` | Lista os status disponíveis |

> O MCP deve estar configurado com as variáveis de ambiente `REDMINE_URL` e `REDMINE_API_KEY`. Nenhuma credencial é armazenada na skill ou no repositório.

---

## ⚙️ Configuração

Na primeira execução, a skill solicita:
- **URL base** do Redmine (ex: `https://redmine.suaempresa.com`)
- **API Key** do usuário

As credenciais são salvas localmente em:
```
C:\Users\<usuario>\Documents\QA-FS-Redmine\config.json
```

> ⚠️ O arquivo `config.json` **nunca deve ser commitado**. Ele fica apenas na sua máquina.

---

## 📋 Fluxo — `/inicia-teste`

```
Usuário: /inicia-teste #18072

Claude:
  Caso #18072: Título do caso...
  Status atual: Liber. Testes → Em Testes
  Atribuído a: (ninguém) → Seu Nome
  Confirma as alterações?

Usuário: Sim

Claude: ✅ Alterações aplicadas com sucesso!
```

---

## 📋 Fluxo — `/plano-teste`

```
Usuário: /plano-teste #18001

Claude: [lê descrição do dev + notas do QA no Redmine]
        Quais testes foram feitos?

Usuário: [descreve telas testadas, situações encontradas e resultado]

Claude: [gera plano completo em formato Textile]
        O plano está aprovado? Deseja documentar no caso?

Usuário: Sim

Claude: Deseja ajustar algo antes de postar?
        (status, atribuição, texto...)

Usuário: Não, pode postar

Claude: ✅ Plano de teste postado no caso #18001!
```

---

## 📄 Padrão do Plano de Teste

O plano gerado segue o formato **Textile** nativo do Redmine com as seções:

1. Objetivo do Teste
2. Escopo do Teste
3. Premissas
4. Riscos
5. Critérios de Aceitação
6. Casos de Teste (CT01, CT02...)
7. Situações Encontradas Durante os Testes
8. Testes Realizados
9. Considerações Finais

---

## 📋 Fluxo — `/registrar-situacao`

```
Usuário: /registrar-situacao #18044

Claude:
  Caso #18044: Título do caso...
  Qual a situação encontrada?

Usuário: na tela de recebimentos nao ta aceitando cnpj com letra

Claude:
  Situação 2:
  Na tela de Recebimentos, não está sendo possível informar um CNPJ alfanumérico.

  A descrição está correta? Posso registrar no caso?

  📎 Lembre-se: se houver imagem, ela deve ser anexada como arquivo
  (arraste até a conversa). Prints com Ctrl+V não funcionam.

  Vai anexar alguma imagem?

Usuário: Sim [arrasta arquivo]

Claude: ✅ Situação registrada com imagem no caso #18044!
```

---

## 📋 Fluxo — `/finalizar-caso`

```
Usuário: /finalizar-caso #18044

Claude:
  Caso #18044: Título do caso...
  Status atual: Em Testes
  Tamanho SP: 7

  ⚠️ Nenhum Plano de Teste encontrado. Deseja gerar antes de finalizar?

Usuário: Não

Claude:
  CheckList Resolvido — marque os itens aplicáveis:
  1. Análise de Risco
  2. Teste exploratório
  3. Criação dos cenários
  4. Automação dos testes
  5. Execução da Automação

  Quais deseja marcar?

Usuário: 1 e 2

Claude:
  O Tamanho SP está como 7. Deseja ajustar?

Usuário: Não

Claude:
  O desenvolvedor identificado foi [Nome do Dev].
  Deseja atribuir o caso a ele ao resolver?

Usuário: Sim

Claude:
  Resumo das alterações:
  - Status: Em Testes → Resolvido
  - Atribuído a: [QA] → [Nome do Dev]
  - CheckList: Análise de Risco, Teste exploratório
  - Tamanho SP: 7 (mantido)
  Confirma?

Usuário: Sim

Claude: ✅ Caso #18044 finalizado com sucesso!
```

---

## 📋 Fluxo — `/refinar-caso`

```
Usuário: /refinar-caso #18044

Claude:
  Caso #18044: Título do caso...
  Qual a pontuação do refinamento? (Dev, Teste, Cenário)

Usuário: 1, 6, sim

Claude:
  |  | Pontuação |
  | Dev | 1 |
  | Teste | 6 |
  | Cenário | Sim |

  Está correto? Posso registrar no caso?

Usuário: Sim

Claude: ✅ Refinamento registrado no caso #18044!
```

---

## 📋 Fluxo — `/criterios-aceitacao`

```
Usuário: /criterios-aceitacao #17776

Claude:
  Caso #17776: NF-e - Criar Evento Informação de efetivo pagamento...

  Critérios de Aceitação:
  1. Deverá ter uma tela para fazer os eventos da reforma tributária.
  2. Deverá ser possível acessar essa tela pelo menu NF-e e por um atalho na tela principal.
  3. Deverá ter um combo para escolher qual evento será feito.
  4. Deverá ser possível transmitir o evento 112110.
  5. Deverá ser possível cancelar o evento 112110.
  ...
```

---

## 📋 Fluxo — `/info-caso`

```
Usuário: /info-caso #17776

Claude:
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📋 Caso #17776 — NF-e - Criar Evento Informação de efetivo pagamento...
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Status: Em Testes
  Atribuído a: Samuel Gonçalves
  Autor: José Inácio Carvalho
  Criado em: 09/02/2026
  Atualizado em: 07/07/2026

  ─── Campos Customizados ───
  Tamanho SP: 21
  Time: The Wall
  Cliente: todos

  ─── Descrição ───
  <descrição completa do caso>

  ─── Anexos (3) ───
  - situacao1.png — Samuel Gonçalves em 07/07/2026
  - ajustes-performance-modais.md — Samuel Gonçalves em 07/07/2026
  - index.html — Samuel Gonçalves em 07/07/2026

  ─── Histórico (8 entradas) ───
  [07/07/2026] Samuel Gonçalves
    Alterações: status → "Liber. Testes" para "Em Testes"
    Nota: *Situação 1:* Ao tentar abrir o Retaguarda...
  ...
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🔒 Segurança

- Nenhuma credencial é armazenada na skill ou no repositório
- O Claude **nunca executa ações no Redmine sem aprovação explícita** do usuário
- O `config.json` é gerado localmente e fica apenas na máquina do usuário

---

## 📁 Estrutura do Repositório

```
QA-FS-Redmine/
├── README.md
├── QA-FS-Redmine.skill      ← instale direto no Claude Desktop
├── instalar-comandos.bat    ← instala os comandos no Claude Code (Windows)
├── skill/
│   └── SKILL.md             ← instrução da skill para o Claude
└── commands/                ← slash commands para o Claude Code
    ├── inicia-teste.md
    ├── plano-teste.md
    ├── registrar-situacao.md
    ├── finalizar-caso.md
    ├── refinar-caso.md
    └── criterios-aceitacao.md
```

---

## 🚀 Como instalar

### Claude Desktop

#### Opção 1 — Arquivo `.skill` (recomendado)

1. Baixe o arquivo [`QA-FS-Redmine.skill`](./QA-FS-Redmine.skill)
2. Abra o **Claude Desktop**
3. Vá em **Configurações → Skills → Instalar**
4. Selecione o arquivo `.skill` baixado

> Na primeira vez que a skill for carregada, ela instala automaticamente os slash commands no Claude Code (veja abaixo).

#### Opção 2 — Pasta manual

1. Clone este repositório
2. Abra o **Claude Desktop**
3. Vá em **Configurações → Skills → Adicionar pasta**
4. Selecione a pasta `skill/` deste repositório

---

### Claude Code (CLI)

No **Claude Code**, slash commands de skills não são reconhecidos nativamente. Para que `/inicia-teste`, `/plano-teste`, `/registrar-situacao`, `/finalizar-caso`, `/refinar-caso` e `/criterios-aceitacao` funcionem como comandos nativos, copie os arquivos da pasta `commands/` para `~/.claude/commands/`:

**Windows — instalador automático (recomendado):**

Dê dois cliques no arquivo [`instalar-comandos.bat`](./instalar-comandos.bat) na raiz do repositório.

**Windows (PowerShell):**
```powershell
Copy-Item ".\commands\*.md" "$env:USERPROFILE\.claude\commands\" -Force
```

**Mac/Linux:**
```bash
cp commands/*.md ~/.claude/commands/
```

> **Alternativa automática:** se você tiver a skill instalada no Claude Desktop, ela detecta a ausência dos arquivos na primeira execução e os cria automaticamente.

---

<div align="center">
  <sub>Desenvolvido por <a href="https://github.com/SamuelG05">Samuel Gonçalves</a></sub><br>
  <sub>Última atualização: 07/07/2026 às 16:10</sub>
</div>
