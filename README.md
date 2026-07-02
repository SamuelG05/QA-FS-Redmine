# ðŸ§ª QA-FS-Redmine

> Skill do Claude para automaÃ§Ã£o de processos de Q.A no Redmine.

Essa skill conecta o Claude diretamente ao Redmine, permitindo gerenciar casos, iniciar testes, gerar planos de teste, registrar situaÃ§Ãµes e finalizar casos â€” tudo sem sair da conversa.

---

## âœ¨ Comandos

| Comando | DescriÃ§Ã£o |
|---|---|
| `/inicia-teste` | Atribui o caso ao usuÃ¡rio logado e muda o status para **Em Testes** |
| `/plano-teste` | LÃª toda a documentaÃ§Ã£o do caso e gera um **Plano de Teste** completo no padrÃ£o da equipe |
| `/registrar-situacao` | Formata e registra uma situaÃ§Ã£o encontrada durante os testes, com suporte a anexo de imagem |
| `/finalizar-caso` | Identifica o dev, verifica plano de teste, preenche CheckList Resolvido, Tamanho SP e fecha o caso como **Resolvido** |
| `/refinar-caso` | Registra a pontuaÃ§Ã£o de refinamento (Dev, Teste e CenÃ¡rio) como tabela no caso |

---

## âš™ï¸ ConfiguraÃ§Ã£o

Na primeira execuÃ§Ã£o, a skill solicita:
- **URL base** do Redmine (ex: `https://redmine.suaempresa.com`)
- **API Key** do usuÃ¡rio

As credenciais sÃ£o salvas localmente em:
```
C:\Users\<usuario>\Documents\QA-FS-Redmine\config.json
```

> âš ï¸ O arquivo `config.json` **nunca deve ser commitado**. Ele fica apenas na sua mÃ¡quina.

---

## ðŸ“‹ Fluxo â€” `/inicia-teste`

```
UsuÃ¡rio: /inicia-teste #18072

Claude:
  Caso #18072: TÃ­tulo do caso...
  Status atual: Liber. Testes â†’ Em Testes
  AtribuÃ­do a: (ninguÃ©m) â†’ Seu Nome
  Confirma as alteraÃ§Ãµes?

UsuÃ¡rio: Sim

Claude: âœ… AlteraÃ§Ãµes aplicadas com sucesso!
```

---

## ðŸ“‹ Fluxo â€” `/plano-teste`

```
UsuÃ¡rio: /plano-teste #18001

Claude: [lÃª descriÃ§Ã£o do dev + notas do QA no Redmine]
        Quais testes foram feitos?

UsuÃ¡rio: [descreve telas testadas, situaÃ§Ãµes encontradas e resultado]

Claude: [gera plano completo em formato Textile]
        O plano estÃ¡ aprovado? Deseja documentar no caso?

UsuÃ¡rio: Sim

Claude: Deseja ajustar algo antes de postar?
        (status, atribuiÃ§Ã£o, texto...)

UsuÃ¡rio: NÃ£o, pode postar

Claude: âœ… Plano de teste postado no caso #18001!
```

---

## ðŸ“„ PadrÃ£o do Plano de Teste

O plano gerado segue o formato **Textile** nativo do Redmine com as seÃ§Ãµes:

1. Objetivo do Teste
2. Escopo do Teste
3. Premissas
4. Riscos
5. CritÃ©rios de AceitaÃ§Ã£o
6. Casos de Teste (CT01, CT02...)
7. SituaÃ§Ãµes Encontradas Durante os Testes
8. Testes Realizados
9. ConsideraÃ§Ãµes Finais

---

## ðŸ“‹ Fluxo â€” `/registrar-situacao`

```
UsuÃ¡rio: /registrar-situacao #18044

Claude:
  Caso #18044: TÃ­tulo do caso...
  Qual a situaÃ§Ã£o encontrada?

UsuÃ¡rio: na tela de recebimentos nao ta aceitando cnpj com letra

Claude:
  SituaÃ§Ã£o 2:
  Na tela de Recebimentos, nÃ£o estÃ¡ sendo possÃ­vel informar um CNPJ alfanumÃ©rico.

  A descriÃ§Ã£o estÃ¡ correta? Posso registrar no caso?

  ðŸ“Ž Lembre-se: se houver imagem, ela deve ser anexada como arquivo
  (arraste atÃ© a conversa). Prints com Ctrl+V nÃ£o funcionam.

  Vai anexar alguma imagem?

UsuÃ¡rio: Sim [arrasta arquivo]

Claude: âœ… SituaÃ§Ã£o registrada com imagem no caso #18044!
```

---

## ðŸ“‹ Fluxo â€” `/finalizar-caso`

```
UsuÃ¡rio: /finalizar-caso #18044

Claude:
  Caso #18044: TÃ­tulo do caso...
  Status atual: Em Testes
  Tamanho SP: 7

  âš ï¸ Nenhum Plano de Teste encontrado. Deseja gerar antes de finalizar?

UsuÃ¡rio: NÃ£o

Claude:
  CheckList Resolvido â€” marque os itens aplicÃ¡veis:
  1. AnÃ¡lise de Risco
  2. Teste exploratÃ³rio
  3. CriaÃ§Ã£o dos cenÃ¡rios
  4. AutomaÃ§Ã£o dos testes
  5. ExecuÃ§Ã£o da AutomaÃ§Ã£o

  Quais deseja marcar?

UsuÃ¡rio: Todos

Claude:
  O Tamanho SP estÃ¡ como 7. Deseja ajustar?

UsuÃ¡rio: NÃ£o

Claude:
  O desenvolvedor identificado foi [Nome do Dev].
  Deseja atribuir o caso a ele ao resolver?

UsuÃ¡rio: Sim

Claude:
  Posso marcar o caso como Resolvido?

UsuÃ¡rio: Sim

Claude:
  Resumo das alteraÃ§Ãµes:
  - Status: Em Testes â†’ Resolvido
  - AtribuÃ­do a: [QA] â†’ [Nome do Dev]
  - CheckList: todos os 5 itens marcados
  - Tamanho SP: 7 (mantido)
  Confirma?

UsuÃ¡rio: Sim

Claude: âœ… Caso #18044 finalizado com sucesso!
```

---

## ðŸ“‹ Fluxo â€” `/refinar-caso`

```
UsuÃ¡rio: /refinar-caso #18044

Claude:
  Caso #18044: TÃ­tulo do caso...
  Qual a pontuaÃ§Ã£o do refinamento? (Dev, Teste, CenÃ¡rio)

UsuÃ¡rio: 1, 6, sim

Claude:
  |  | PontuaÃ§Ã£o |
  | Dev | 1 |
  | Teste | 6 |
  | CenÃ¡rio | Sim |

  EstÃ¡ correto? Posso registrar no caso?

UsuÃ¡rio: Sim

Claude: âœ… Refinamento registrado no caso #18044!
```

---

## ðŸ”’ SeguranÃ§a

- Nenhuma credencial Ã© armazenada na skill ou no repositÃ³rio
- O Claude **nunca executa aÃ§Ãµes no Redmine sem aprovaÃ§Ã£o explÃ­cita** do usuÃ¡rio
- O `config.json` Ã© gerado localmente e fica apenas na mÃ¡quina do usuÃ¡rio

---

## ðŸ“ Estrutura do RepositÃ³rio

```
QA-FS-Redmine/
â”œâ”€â”€ README.md
â”œâ”€â”€ QA-FS-Redmine.skill   â† instale direto no Claude Desktop
â””â”€â”€ skill/
    â””â”€â”€ SKILL.md          â† instruÃ§Ã£o da skill para o Claude
```

---

## ðŸš€ Como instalar

### Claude Desktop

#### OpÃ§Ã£o 1 â€” Arquivo `.skill` (recomendado)

1. Baixe o arquivo [`QA-FS-Redmine.skill`](./QA-FS-Redmine.skill)
2. Abra o **Claude Desktop**
3. VÃ¡ em **ConfiguraÃ§Ãµes â†’ Skills â†’ Instalar**
4. Selecione o arquivo `.skill` baixado

> Na primeira vez que a skill for carregada, ela instala automaticamente os slash commands no Claude Code (veja abaixo).

#### OpÃ§Ã£o 2 â€” Pasta manual

1. Clone este repositÃ³rio
2. Abra o **Claude Desktop**
3. VÃ¡ em **ConfiguraÃ§Ãµes â†’ Skills â†’ Adicionar pasta**
4. Selecione a pasta `skill/` deste repositÃ³rio

---

### Claude Code (CLI)

No **Claude Code**, slash commands de skills nÃ£o sÃ£o reconhecidos nativamente. Para que `/inicia-teste`, `/plano-teste`, `/registrar-situacao`, `/finalizar-caso` e `/refinar-caso` funcionem como comandos nativos, copie os arquivos da pasta `commands/` para `~/.claude/commands/`:

**Windows (PowerShell):**
```powershell
Copy-Item ".\commands\*.md" "$env:USERPROFILE\.claude\commands\" -Force
```

**Mac/Linux:**
```bash
cp commands/*.md ~/.claude/commands/
```

> **Alternativa automÃ¡tica:** se vocÃª tiver a skill instalada no Claude Desktop, ela detecta a ausÃªncia dos arquivos na primeira execuÃ§Ã£o e os cria automaticamente.

---

<div align="center">
  <sub>Desenvolvido por <a href="https://github.com/SamuelG05">Samuel GonÃ§alves</a></sub><br>
  <sub>Ãšltima atualizaÃ§Ã£o: 02/07/2026 Ã s 11:00</sub>
</div>

