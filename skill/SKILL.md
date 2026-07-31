---
name: QA-FS-Redmine
description: Skill de Q.A para gerenciar issues no Redmine. Use sempre que o usuário digitar /inicia-teste, /plano-teste, ou qualquer comando relacionado a issues, casos, testes, status, plano de teste ou atribuições no Redmine. Também aciona quando o usuário menciona "issue", "caso", "redmine", "coloca em testes", "atribui pra mim", "gera plano de teste" ou qualquer operação de Q.A no Redmine.
---

## Modo de operação

Na **primeira execução da sessão**, pergunte ao usuário:

> "O MCP Redmine está configurado e ativo? (ele aparece como ferramenta disponível no Claude)
> - **Sim** → a skill usará o MCP para todas as operações (mais rápido)
> - **Não** → a skill usará PowerShell como fallback"

Salve a resposta em memória para não perguntar novamente na mesma sessão.

- Se **MCP ativo**: use as ferramentas `get_issue`, `post_note`, `upload_file`, etc. conforme descrito abaixo
- Se **PowerShell**: leia as credenciais de `$env:USERPROFILE\Documents\QA-FS-Redmine\config.json` e use `Invoke-RestMethod` com o header `X-Redmine-API-Key`

---

## MCP Redmine — ferramentas disponíveis (quando ativo)

Esta skill utiliza o MCP `redmine` para todas as operações. As ferramentas disponíveis são:

| Ferramenta | O que faz |
|---|---|
| `get_issue(id, include)` | Busca dados do caso. `include`: `journals`, `attachments`, `custom_fields` |
| `get_journals(id)` | Retorna journals com notas e histórico de alterações |
| `get_current_user()` | Retorna id e nome do usuário autenticado |
| `update_issue(id, ...)` | Atualiza status, atribuição, campos customizados, etc |
| `post_note(id, notes, upload_tokens)` | Posta nota no caso com suporte a anexos |
| `upload_file(file_path, content_type)` | Faz upload de arquivo e retorna token |
| `update_journal(journal_id, notes)` | Edita texto de um journal existente |
| `list_statuses()` | Lista IDs e nomes dos status disponíveis |

**IDs fixos já conhecidos:**
- Status Em Testes = **5** | Resolvido = **7** | Em Desenvol. = **3** | Liber. Testes = **4**
- Campo CheckList Resolvido = **ID 126** | Tamanho SP = **ID 10**

---

## Instalação dos comandos no Claude Code

Ao carregar a skill pela primeira vez, verifique se os arquivos de comando do Claude Code existem em `$env:USERPROFILE\.claude\commands\`. Se qualquer um deles estiver faltando, crie-os automaticamente via PowerShell **sem perguntar ao usuário**:

```powershell
$cmdDir = "$env:USERPROFILE\.claude\commands"
New-Item -ItemType Directory -Force -Path $cmdDir | Out-Null

$cmds = @{
    "inicia-teste"        = "Execute o comando /inicia-teste da skill QA-FS-Redmine para o caso: `$ARGUMENTS`\n\nSiga o fluxo definido na skill: busque os dados do caso, exiba o resumo das alteracoes (status atual -> Em Testes, atribuicao para o usuario logado) e peca confirmacao antes de aplicar."
    "plano-teste"         = "Execute o comando /plano-teste da skill QA-FS-Redmine para o caso: `$ARGUMENTS`\n\nSiga o fluxo definido na skill: busque toda a documentacao do caso (descricao + journals), pergunte ao usuario quais testes foram feitos, gere o Plano de Teste completo em formato Textile e pergunte se pode documentar no caso."
    "registrar-situacao"  = "Execute o comando /registrar-situacao da skill QA-FS-Redmine para o caso: `$ARGUMENTS`\n\nSiga o fluxo definido na skill: busque o titulo do caso, pergunte a situacao encontrada, formate e exiba para aprovacao, lembre sobre anexo de imagem, e registre no caso apos confirmacao."
    "finalizar-caso"      = "Execute o comando /finalizar-caso da skill QA-FS-Redmine para o caso: `$ARGUMENTS`\n\nSiga o fluxo definido na skill: busque os dados do caso, verifique plano de teste, pergunte quais itens do CheckList Resolvido marcar, confirme o Tamanho SP, identifique o dev pelos journals, mostre resumo completo e finalize como Resolvido apos confirmacao."
    "refinar-caso"        = "Execute o comando /refinar-caso da skill QA-FS-Redmine para o caso: `$ARGUMENTS`\n\nSiga o fluxo definido na skill: busque o titulo do caso, pergunte a pontuacao de refinamento (Dev, Teste, Cenario), gere a tabela Textile e registre no caso apos confirmacao."
    "criterios-aceitacao" = "Execute o comando /criterios-aceitacao da skill QA-FS-Redmine para o caso: `$ARGUMENTS`\n\nSiga o fluxo definido na skill: busque os dados completos do caso, localize a secao de criterios de aceitacao na descricao e nos journals, e liste todos os criterios encontrados numerados e formatados."
    "info-caso"           = "Execute o comando /info-caso da skill QA-FS-Redmine para o caso: `$ARGUMENTS`\n\nSiga o fluxo definido na skill: busque todos os dados do caso (titulo, descricao completa, status, atribuicao, campos customizados, anexos e todos os journals com notas e alteracoes) e exiba de forma organizada e legivel."
    "up-refinados"        = "Execute o comando /up-refinados da skill QA-FS-Redmine para o caso: `$ARGUMENTS`\n\nSiga o fluxo definido na skill: acesse o card no quadro Upstream The Wall do Trello, busque o caso completo no Redmine (descricao + journals + criterios de aceitacao), identifique o caso dependente (@DEPENDE), gere os cenarios Gherkin com @Automatizar e @DEPENDE e os casos de teste no padrao CT, exiba tudo para aprovacao e registre no caso apos confirmacao."
}

foreach ($name in $cmds.Keys) {
    $file = "$cmdDir\$name.md"
    if (-not (Test-Path $file)) {
        $cmds[$name] | Set-Content -Path $file -Encoding utf8
    }
}
```

Após criar os arquivos, informe ao usuário discretamente:
> "✅ Comandos registrados no Claude Code. A partir de agora `/inicia-teste`, `/plano-teste`, `/registrar-situacao`, `/finalizar-caso`, `/refinar-caso` e `/criterios-aceitacao` funcionam como slash commands nativos."

---

## Terminologia

> **Importante:** a equipe utiliza o termo **"caso"** para se referir a uma issue do Redmine. Sempre use "caso" nas perguntas e respostas ao usuário — nunca "issue".

---

## Comandos disponíveis

### /inicia-teste
Atribui o caso ao usuário logado, muda o status para "Em Testes" e cria a pasta local do caso.

**Fluxo:**
1. Se o número do caso não foi informado, peça: *"Qual o número do caso? (#)"*
2. Busque os dados atuais:
   - `get_issue(id)`
3. Busque o usuário logado:
   - `get_current_user()`
4. Exiba resumo das alterações: título, status atual → Em Testes, atribuído → usuário logado
5. Peça confirmação
6. Aplique:
   - `update_issue(id, status_id=5, assigned_to_id=<user_id>)`
7. **Criar pasta local do caso — pergunte uma vez por sessão:**
   - Na primeira execução de `/inicia-teste` na sessão, pergunte:
     > "Qual o caminho base para as pastas de casos? (padrão: `C:\Users\PC\OneDrive\CASOS`)"
   - Se o usuário confirmar ou não responder, use `C:\Users\PC\OneDrive\CASOS`
   - Salve o caminho em memória de sessão para não perguntar novamente
   - Crie a pasta do caso via PowerShell se ainda não existir:
     ```powershell
     $casePath = "<caminho_base>\<numero_do_caso>"
     New-Item -ItemType Directory -Force -Path $casePath | Out-Null
     ```
   - Informe ao usuário: `📁 Pasta criada em: <caminho_base>\<numero_do_caso>`
8. Confirme o sucesso

---

### /plano-teste
Lê toda a documentação do caso e gera um Plano de Teste completo no padrão da equipe, em formato Textile.

**Quando usar:** Após o dev liberar o caso e o QA ter testado. Pressupõe que **todas as situações já foram corrigidas** — o plano sempre marcará as situações como `✅ **Situação corrigida.**`

**Fluxo:**

1. Se o número do caso não foi informado, peça: *"Qual o número do caso? (#)"*

2. Busque os dados completos:
   - `get_issue(id, include="journals,attachments")`

3. Leia e analise:
   - `subject` → título da funcionalidade
   - `description` → documentação do dev
   - `journals` → notas do QA: situações encontradas, critérios validados, telas testadas

4. Pergunte ao usuário:
   > "Quais testes foram feitos? Descreva as telas testadas, situações encontradas e o resultado geral."

5. **Gere o Plano de Teste** seguindo rigorosamente o padrão Textile abaixo:

```
h1. PLANO DE TESTE – Funcionalidade #<id>
Tema: <subject exato do caso — nunca resumir ou inventar>

---

h3. 1. Objetivo do Teste

<Objetivo baseado na descrição da issue. Usar **negrito** nos termos técnicos principais.>

---

h3. 2. Escopo do Teste

**Este plano contempla:**

* <tela ou módulo 1>;
* <tela ou módulo 2>;
* ...

**Fora de escopo:**

* <o que não será testado>;
* ...

---

h3. 3. Premissas

* <premissa técnica>;
* <dados de teste usados: CNPJs, chaves, versões, configurações>;
* ...

---

h3. 4. Riscos

* <risco 1>;
* <risco 2>;
* ...

---

h3. 5. Critérios de Aceitação

✅ No campo **<campo>** de **<tela>** deve ser possível <comportamento esperado>.
✅ <Critério 2>.
...

---

h3. 6. Casos de Teste

**CT01 – <Descrição curta>**

**Passos:**
**Passo 01:** <ação>.
**Passo 02:** <ação>.
**Passo 03:** <ação>.

**Resultado Esperado:**
<O que o sistema deve fazer.>

---

**CT02 – <Descrição curta>**
<repetir para cada caso identificado>

---

h3. 7. Situações Encontradas Durante os Testes

**Situação 1:**
<Descrever a situação com base nas notas/journals do QA.>

✅ **Situação corrigida.**

---

h3. 8. Testes Realizados

✅ Testes realizados em todas as telas mencionadas no caso.
✅ Automações criadas para as telas em que foi possível automatizar.
✅ Imagens anexadas ao caso demonstrando <funcionalidade principal>.
✅ Todas as situações identificadas durante os testes foram corrigidas.

---

h3. 9. Considerações Finais

<Resumo do que foi validado, tecnologias/rotinas envolvidas e conclusão.>

✅ **Funcionalidade validada e apta para produção.**
```

**Regras de formatação obrigatórias:**
- Usar `h1.` e `h3.` (Textile do Redmine)
- Usar `**texto**` para negrito
- Usar `---` como separador entre seções
- Usar `✅` diretamente — NUNCA `:check_mark:` ou qualquer outra representação textual
- O campo **Tema** deve ser sempre o `subject` exato retornado pela API
- Casos de teste numerados: CT01, CT02, CT03...
- Passos numerados: **Passo 01**, **Passo 02**...
- Todas as situações marcadas como `✅ **Situação corrigida.**`
- Ponto e vírgula ao final de cada item de lista com `*`

6. Pergunte ao usuário:
   > "O plano está aprovado? Deseja documentar no caso?"
   - **Se não:** encerre. Nada é postado.
   - **Se sim:** pergunte se deseja ajustar algo antes de postar
   - Após confirmação, poste:
     - `post_note(id, notes=<plano gerado>)`

**Regra absoluta: nunca postar, alterar ou executar qualquer ação no Redmine sem aprovação explícita do usuário.**

---

### /finalizar-caso
Consolida o encerramento do caso como Resolvido.

**Fluxo:**

1. Se o número do caso não foi informado, peça: *"Qual o número do caso? (#)"*

2. Busque os dados completos:
   - `get_issue(id, include="journals,custom_fields")`

3. Exiba o estado atual: título, status, Tamanho SP

4. **Verifique se existe um Plano de Teste** — procure nos journals por nota que contenha `"PLANO DE TESTE"`:
   - **Se não existir:** pergunte se deseja gerar antes de finalizar. Se sim, execute `/plano-teste` e retome.

5. **CheckList Resolvido (campo ID 126):**

   Exiba as opções e pergunte quais marcar:
   ```
   1. Análise de Risco
   2. Teste exploratório
   3. Criação dos cenários
   4. Automação dos testes
   5. Execução da Automação
   ```
   **Nunca assuma que o usuário quer todos — sempre pergunte.**

   Nomes exatos para a API:
   - `"Análise de risco"` | `"Teste exploratório"` | `"Criação dos cenários"` | `"Automação dos testes"` | `"Execução da Automação"`

6. **Tamanho SP (campo ID 10):**
   - Se vazio: peça o valor
   - Se preenchido: pergunte se deseja ajustar

7. **Identificar o desenvolvedor** — procure nos journals o último a mover para status 3 (Em Desenvol.) ou 4 (Liber. Testes):
   - `get_journals(id)` e filtre `details` onde `name="status_id"` e `new_value` em `["3","4"]`
   - Pergunte se deseja atribuir o caso ao dev identificado

8. Mostre o resumo completo e peça confirmação final

9. Aplique tudo em uma única chamada:
   - `update_issue(id, status_id=7, assigned_to_id=<dev_id>, custom_fields=[{id:126, value:[...]}, {id:10, value:"<sp>"}])`

**Regra absoluta: nunca alterar nada sem aprovação explícita do usuário.**

---

### /registrar-situacao
Registra uma situação encontrada durante os testes, com descrição formatada e suporte a anexo.

**Fluxo:**

1. Se o número do caso não foi informado, peça: *"Qual o número do caso? (#)"*

2. Busque o título e conte as situações já registradas:
   - `get_issue(id, include="journals")`
   - Conte journals que contenham "Situação" para numerar a próxima

4. Pergunte a situação:
   > "Qual a situação encontrada?"

5. Formate a descrição corrigindo ortografia e gramática, mas mantendo a lógica e o conteúdo exato do que o usuário relatou. **Mensagens de erro, logs e códigos técnicos devem ser copiados exatamente como o usuário informou — nunca alterar, remover espaços, pontuação ou formatação do erro.** Monte no padrão:

```
*Situação <N>:*
<descrição formatada e melhorada>

!{width:600px}<nome_do_arquivo>!
```

> A linha `!{width:600px}nome_do_arquivo!` só é incluída se houver imagem — ela faz a imagem aparecer inline no Redmine. Omita se não houver imagem.

6. Exiba para aprovação:
   > "A descrição está correta? Posso registrar no caso?"

7. **Lembrete de imagem — exiba sempre:**
   > "📎 Lembre-se: se houver imagem, ela deve ser anexada como **arquivo** (arraste o arquivo até a conversa ou informe o caminho). Prints com Ctrl+V não funcionam como anexo no Redmine."

8. Se houver arquivo a anexar:
   - `upload_file(file_path=<caminho>, content_type=<mime>)` → obtém token
   - `post_note(id, notes=<situacao formatada>, upload_tokens=[{token, filename, content_type}])`
   
   Se não houver arquivo:
   - `post_note(id, notes=<situacao formatada>)`

9. Confirme o sucesso

---

---

### /refinar-caso
Registra a pontuação de refinamento (Dev, Teste e Cenário) como nota no caso.

**Fluxo:**

1. Se o número do caso não foi informado, peça: *"Qual o número do caso? (#)"*

2. Busque o título: `get_issue(id)`

3. Pergunte a pontuação:
   > "Qual a pontuação do refinamento? (Dev, Teste, Cenário — ex: `1, 6, sim` ou uma por linha)"

4. Monte a tabela Textile:
```
|  | *Pontuação* |
| *Dev* | 1 |
| *Teste* | 6 |
| *Cenário* | Sim |
```

5. Exiba e pergunte:
   > "Está correto? Posso registrar no caso?"

6. Após confirmação:
   - `post_note(id, notes=<tabela gerada>)`

---

### /info-caso
Exibe todas as informações do caso de forma organizada: título, descrição completa, status, campos customizados, anexos e histórico completo de journals com notas e alterações.

**Fluxo:**

1. Se o número do caso não foi informado, peça: *"Qual o número do caso? (#)"*

2. Busque todos os dados:
   - PowerShell: `GET /issues/<id>.json?include=journals,attachments,custom_fields`

3. Exiba no formato abaixo:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Caso #<id> — <subject>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status: <status>
Atribuído a: <nome ou "(ninguém)">
Autor: <nome>
Criado em: <data>
Atualizado em: <data>

─── Campos Customizados ───
Tamanho SP: <valor>
<outros campos com valor preenchido>

─── Descrição ───
<descrição completa>

─── Anexos (<N>) ───
- <filename> — <autor> em <data>
...

─── Histórico (<N> entradas) ───
[<data>] <usuário>
  Alterações: <campo> → "<valor antigo>" para "<valor novo>"
  Nota: <texto da nota se houver>
...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

4. Exiba tudo — não resuma nem omita journals ou alterações.

---

### /criterios-aceitacao
Lista todos os critérios de aceitação disponíveis na documentação do caso.

**Fluxo:**

1. Se o número do caso não foi informado, peça: *"Qual o número do caso? (#)"*

2. Busque os dados completos:
   - `get_issue(id, include="journals,attachments")`

3. Procure na `description` por seção de critérios. Ela pode aparecer como:
   - `Critérios de aceitação`
   - `Criterios de aceitacao`
   - `Critério de aceite`
   - Lista de itens com `-` ou `*` após um título relacionado a critérios

4. Verifique também nos `journals` por critérios adicionais registrados

5. Exiba numerados e formatados:
```
Caso #<id>: <subject>

Critérios de Aceitação:
1. <critério 1>
2. <critério 2>
...
```

6. Se não houver critérios documentados, informe:
   > "Não encontrei critérios de aceitação documentados nesse caso."

---

### /up-refinados
Acessa o card do caso no quadro "Upstream The Wall" do Trello, lê o caso completo no Redmine e gera cenários Gherkin com tags `@Automatizar` e `@DEPENDE: #<caso_pai>` + casos de teste no padrão CT.

**Credenciais Trello** — leia de `$env:USERPROFILE\Documents\QA-FS-Redmine\config.json` (campos `trello_api_key`, `trello_token`, `trello_upstream_board_id`).

Se qualquer um desses campos não existir no config.json, pergunte ao usuário:
> "Para usar o /up-refinados preciso das suas credenciais do Trello:
> - Trello API Key:
> - Trello Token:
> - Board ID do Upstream The Wall:"

Após receber os valores, adicione-os ao config.json existente via PowerShell:
```powershell
$configPath = "$env:USERPROFILE\Documents\QA-FS-Redmine\config.json"
$config = Get-Content $configPath -Raw | ConvertFrom-Json
$config | Add-Member -NotePropertyName "trello_api_key" -NotePropertyValue "<valor>" -Force
$config | Add-Member -NotePropertyName "trello_token" -NotePropertyValue "<valor>" -Force
$config | Add-Member -NotePropertyName "trello_upstream_board_id" -NotePropertyValue "<valor>" -Force
$config | ConvertTo-Json | Set-Content -Path $configPath -Encoding utf8
```
Salve em memória de sessão para não perguntar novamente.

**Fluxo:**

1. Se o número do caso não foi informado, peça: *"Qual o número do caso? (#)"*

2. **Buscar o card no Trello** via PowerShell:
```powershell
$config = Get-Content "$env:USERPROFILE\Documents\QA-FS-Redmine\config.json" -Raw | ConvertFrom-Json
$apiKey = $config.trello_api_key
$token = $config.trello_token
$boardId = $config.trello_upstream_board_id
$cards = Invoke-RestMethod -Uri "https://api.trello.com/1/boards/$boardId/cards?key=$apiKey&token=$token&fields=name,desc,idList" -Method Get
$card = $cards | Where-Object { $_.name -match "<numero_do_caso>" } | Select-Object -First 1
Write-Output $card.name
Write-Output $card.desc
```
   - Se o card não for encontrado, informe ao usuário e encerre.

3. **Buscar o caso completo no Redmine** (descrição + journals):
   - `get_issue(id, include="journals,attachments,custom_fields")`
   - Ou via PowerShell: `GET /issues/<id>.json?include=journals,attachments,custom_fields`

4. **Identificar o caso dependente (`@DEPENDE`):**
   - Procure na descrição do card Trello ou na descrição do caso Redmine por referências a outros casos (`#XXXXX`)
   - Use o caso referenciado como valor do `@DEPENDE`
   - Se não houver referência explícita, use o próprio número do caso

5. **Gerar os cenários Gherkin** com base nos critérios de aceitação e no comportamento descrito:

```
Funcionalidade: <subject exato do caso Redmine>

  @Automatizar @DEPENDE: #<caso_dependente>
  Cenário: <descrição curta do comportamento>
    Dado que <contexto inicial>
    E <pré-condição adicional se necessária>
    Quando <ação executada>
    Então <resultado esperado>
    E <validação adicional se necessária>

  @Automatizar @DEPENDE: #<caso_dependente>
  Cenário: <próximo cenário>
    ...
```

   **Regras dos cenários:**
   - Cada critério de aceitação deve virar pelo menos um cenário
   - Tag `@Automatizar` em todos os cenários
   - Tag `@DEPENDE: #<numero>` com o caso pai/dependente identificado
   - Usar verbos no infinitivo nas etapas: "Dado que", "E", "Quando", "Então"
   - Cenários independentes — cada um deve ser executável isoladamente
   - Nomear de forma descritiva e técnica

6. **Gerar os casos de teste** no padrão CT:

```
CT01 – <Descrição curta>

Passos:
Passo 01: <ação>.
Passo 02: <ação>.

Resultado Esperado:
<O que o sistema deve fazer.>

---

CT02 – <próximo caso>
...
```

   **Regras dos CT:**
   - Sequência numérica: CT01, CT02, CT03...
   - Passos objetivos e executáveis por qualquer testador
   - Resultado esperado claro e verificável
   - Cobrir todos os critérios de aceitação do caso

7. **Exibir tudo para o usuário** e perguntar:
   > "Os cenários e casos de teste estão corretos? Posso registrar no Redmine e mover o card no Trello?"

8. **Se o usuário confirmar — executar as duas ações:**

   **8a. Postar no Redmine** (independente do status atual do caso):
   - Monte o conteúdo e poste via `post_note`:
   ```
   <pre><code>
   <cenários Gherkin gerados>
   </code></pre>

   <casos de teste CT em texto simples>
   ```
   - `post_note(id, notes=<conteudo>)`

   **8b. Mover o card no Trello para a coluna "Cenários BDD" no topo:**
   - Primeiro, busque o ID da lista "Cenários BDD" no board:
   ```powershell
   $lists = Invoke-RestMethod -Uri "https://api.trello.com/1/boards/$boardId/lists?key=$apiKey&token=$token&fields=name,id" -Method Get
   $listBDD = $lists | Where-Object { $_.name -match "Cen.rios BDD" } | Select-Object -First 1
   $listId = $listBDD.id
   ```
   - Mova o card para essa lista e posicione no topo:
   ```powershell
   $body = @{ idList = $listId; pos = "top" }
   Invoke-RestMethod -Uri "https://api.trello.com/1/cards/$($card.id)?key=$apiKey&token=$token" -Method Put -Body $body
   ```

9. Confirme o sucesso:
   > "✅ Cenários registrados no caso #<id> do Redmine e card movido para o topo de Cenários BDD no Trello!"

**Regra absoluta: nunca postar no Redmine ou mover o card sem aprovação explícita do usuário.**

---

## Fallback PowerShell (quando MCP não está ativo)

Quando o MCP não estiver disponível, use PowerShell para todas as operações. Leia o config:

```powershell
$configPath = "$env:USERPROFILE\Documents\QA-FS-Redmine\config.json"
$config = Get-Content $configPath -Raw | ConvertFrom-Json
# $config.url | $config.api_key | $config.user_id | $config.user_name
$headers = @{ "X-Redmine-API-Key" = $config.api_key }
```

**Se o config.json não existir (primeira vez):** peça a URL base e a API Key, busque o usuário atual e salve:
```powershell
$configDir = "$env:USERPROFILE\Documents\QA-FS-Redmine"
New-Item -ItemType Directory -Force -Path $configDir | Out-Null
$headers = @{ "X-Redmine-API-Key" = "<api_key>" }
$u = (Invoke-RestMethod -Uri "<url>/users/current.json" -Headers $headers).user
$config = @{ url = "<url>"; api_key = "<api_key>"; user_id = $u.id; user_name = "$($u.firstname) $($u.lastname)" } | ConvertTo-Json
$config | Set-Content -Path "$configDir\config.json" -Encoding utf8
```

**Equivalências PowerShell por operação:**

| Operação MCP | Equivalente PowerShell |
|---|---|
| `get_issue(id, include)` | `Invoke-RestMethod "$($config.url)/issues/$id.json?include=journals,attachments,custom_fields" -Headers $headers` |
| `get_current_user()` | `Invoke-RestMethod "$($config.url)/users/current.json" -Headers $headers` |
| `list_statuses()` | `Invoke-RestMethod "$($config.url)/issue_statuses.json" -Headers $headers` |
| `post_note(id, notes)` | `Invoke-RestMethod "$($config.url)/issues/$id.json" -Method Put -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($body))` |
| `upload_file(path)` | `POST /uploads.json` com `Content-Type: application/octet-stream` e `[System.IO.File]::ReadAllBytes(path)` |
| `update_journal(id, notes)` | `PUT /journals/$id.json` com `{"journal":{"notes":"..."}}` |
| `update_issue(id, custom_fields)` | `PUT /issues/$id.json` com heredoc UTF-8 para evitar erro 400 com arrays e acentos |

> ⚠️ Sempre use `[System.Text.Encoding]::UTF8.GetBytes($body)` ao enviar JSON com acentos ou arrays no PowerShell.

---

## Observações gerais

- Sempre exibir o **título** do caso nas respostas
- Sempre confirmar com o usuário antes de aplicar qualquer alteração no Redmine
- Sempre usar o termo **"caso"** (nunca "issue") ao falar com o usuário
- Sempre usar `✅` literal — nunca `:check_mark:`
- O campo Tema do plano de teste deve ser o `subject` exato retornado pela API
- Nunca assumir quais itens do checklist marcar — sempre perguntar
