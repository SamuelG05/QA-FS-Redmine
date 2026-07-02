---
name: QA-FS-Redmine
description: Skill de Q.A para gerenciar issues no Redmine. Use sempre que o usuário digitar /inicia-teste, /plano-teste, ou qualquer comando relacionado a issues, casos, testes, status, plano de teste ou atribuições no Redmine. Também aciona quando o usuário menciona "issue", "caso", "redmine", "coloca em testes", "atribui pra mim", "gera plano de teste" ou qualquer operação de Q.A no Redmine.
---

## Instalação dos comandos no Claude Code

Ao carregar a skill pela primeira vez, verifique se os arquivos de comando do Claude Code existem em `$env:USERPROFILE\.claude\commands\`. Se qualquer um deles estiver faltando, crie-os automaticamente via PowerShell **sem perguntar ao usuário**:

```powershell
$cmdDir = "$env:USERPROFILE\.claude\commands"
New-Item -ItemType Directory -Force -Path $cmdDir | Out-Null

$cmds = @{
    "inicia-teste"       = "Execute o comando /inicia-teste da skill QA-FS-Redmine para o caso: `$ARGUMENTS`\n\nSiga o fluxo definido na skill: busque os dados do caso, exiba o resumo das alteracoes (status atual -> Em Testes, atribuicao para o usuario logado) e peca confirmacao antes de aplicar."
    "plano-teste"        = "Execute o comando /plano-teste da skill QA-FS-Redmine para o caso: `$ARGUMENTS`\n\nSiga o fluxo definido na skill: busque toda a documentacao do caso (descricao + journals), pergunte ao usuario quais testes foram feitos, gere o Plano de Teste completo em formato Textile e pergunte se pode documentar no caso."
    "registrar-situacao" = "Execute o comando /registrar-situacao da skill QA-FS-Redmine para o caso: `$ARGUMENTS`\n\nSiga o fluxo definido na skill: busque o titulo do caso, pergunte a situacao encontrada, formate e exiba para aprovacao, lembre sobre anexo de imagem, e registre no caso apos confirmacao."
    "finalizar-caso"     = "Execute o comando /finalizar-caso da skill QA-FS-Redmine para o caso: `$ARGUMENTS`\n\nSiga o fluxo definido na skill: busque os dados do caso, verifique plano de teste, pergunte quais itens do CheckList Resolvido marcar, confirme o Tamanho SP, identifique o dev pelos journals, mostre resumo completo e finalize como Resolvido apos confirmacao."
    "refinar-caso"       = "Execute o comando /refinar-caso da skill QA-FS-Redmine para o caso: `$ARGUMENTS`\n\nSiga o fluxo definido na skill: busque o titulo do caso, pergunte a pontuacao de refinamento (Dev, Teste, Cenario), gere a tabela Textile e registre no caso apos confirmacao."
}

foreach ($name in $cmds.Keys) {
    $file = "$cmdDir\$name.md"
    if (-not (Test-Path $file)) {
        $cmds[$name] | Set-Content -Path $file -Encoding utf8
    }
}
```

Após criar os arquivos, informe ao usuário discretamente:
> "✅ Comandos registrados no Claude Code. A partir de agora `/inicia-teste`, `/plano-teste`, `/registrar-situacao`, `/finalizar-caso` e `/refinar-caso` funcionam como slash commands nativos."

---

## Configuração

As credenciais ficam em:
`C:\Users\<usuario>\Documents\QA-FS-Redmine\config.json`

Para descobrir o caminho correto, use `$env:USERPROFILE` no PowerShell.

**Se o arquivo não existir (primeira vez):**
1. Peça ao usuário a **URL base** e a **API Key** do Redmine
2. Crie a pasta e o arquivo:
```powershell
$configDir = "$env:USERPROFILE\Documents\QA-FS-Redmine"
New-Item -ItemType Directory -Force -Path $configDir | Out-Null
```
3. Busque o usuário atual e salve o config:
```powershell
$headers = @{ "X-Redmine-API-Key" = "<api_key>" }
$u = (Invoke-RestMethod -Uri "<url>/users/current.json" -Headers $headers).user
$config = @{ url = "<url>"; api_key = "<api_key>"; user_id = $u.id; user_name = "$($u.firstname) $($u.lastname)" } | ConvertTo-Json
$config | Set-Content -Path "$configDir\config.json" -Encoding utf8
```
4. Confirme ao usuário que a configuração foi salva.

**Leitura do config (uso normal):**
```powershell
$configPath = "$env:USERPROFILE\Documents\QA-FS-Redmine\config.json"
$config = Get-Content $configPath -Raw | ConvertFrom-Json
# use: $config.url, $config.api_key, $config.user_id, $config.user_name
```

---

## Terminologia

> **Importante:** a equipe utiliza o termo **"caso"** para se referir a uma issue do Redmine. Sempre use "caso" nas perguntas e respostas ao usuário — nunca "issue". Exemplos: "Qual o número do caso?", "O caso foi atualizado com sucesso!", "Não encontrei o caso informado."

---

## Comandos disponíveis

### /inicia-teste
Atribui uma issue ao usuário logado e muda o status para "Em Testes".

**Fluxo:**
1. Se o número da issue não foi informado, peça: *"Qual o número do caso? (#)"*
2. Busque os dados atuais da issue:
```powershell
$headers = @{ "X-Redmine-API-Key" = $config.api_key }
$issue = Invoke-RestMethod -Uri "$($config.url)/issues/<id>.json" -Headers $headers
```
3. Exiba: Título, Status atual, Atribuído a (atual)
4. Busque o ID do status "Em Testes":
```powershell
$statuses = Invoke-RestMethod -Uri "$($config.url)/issue_statuses.json" -Headers $headers
$statusId = ($statuses.issue_statuses | Where-Object { $_.name -eq "Em Testes" }).id
```
5. Mostre o resumo das alterações e peça confirmação
6. Aplique:
```powershell
$headers["Content-Type"] = "application/json"
$body = @{ issue = @{ status_id = $statusId; assigned_to_id = $config.user_id } } | ConvertTo-Json
Invoke-RestMethod -Uri "$($config.url)/issues/<id>.json" -Method Put -Headers $headers -Body $body
```
7. Confirme o sucesso com título da issue e mudanças aplicadas

---

### /plano-teste
Lê toda a documentação de uma issue no Redmine e gera um Plano de Teste completo no padrão da equipe, em formato Textile (markup do Redmine).

**Quando usar:** Após o dev liberar o caso e o QA ter testado e documentado as situações encontradas. Esse comando pressupõe que **todas as situações já foram corrigidas** — o plano sempre marcará as situações como `✅ **Situação corrigida.**`

**Fluxo:**

1. Se o número da issue não foi informado, peça: *"Qual o número do caso? (#)"*

2. Busque os dados completos da issue incluindo journals e anexos:
```powershell
$headers = @{ "X-Redmine-API-Key" = $config.api_key }
$issue = Invoke-RestMethod -Uri "$($config.url)/issues/<id>.json?include=journals,attachments" -Headers $headers
```

3. Leia e analise tudo:
   - `subject` → título da funcionalidade
   - `description` → documentação do dev: o que foi implementado, escopo, premissas técnicas, dados de teste
   - `journals` → notas do QA: situações encontradas, critérios validados, observações, telas testadas

4. Após ler o caso, pergunte ao usuário:
   > "Quais testes foram feitos? Descreva as telas testadas, situações encontradas e o resultado geral."

   Use a resposta do usuário para enriquecer as seções **6. Casos de Teste**, **7. Situações Encontradas**, **8. Testes Realizados** e **9. Considerações Finais** do plano. Combine o que está documentado no Redmine com o que o usuário relatar — o relato do usuário tem prioridade para refletir o que foi testado de fato.

5. **Gere o Plano de Teste** seguindo rigorosamente o padrão abaixo em Textile:

```
h1. PLANO DE TESTE – Funcionalidade #<id>
Tema: <subject exato do caso buscado da API — nunca resumir ou inventar>

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

**Situação 2:**
<próxima situação>

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
- Usar `**texto**` para negrito em termos técnicos, campos e funcionalidades
- Usar `---` como separador entre seções
- Usar `✅` em critérios, situações corrigidas e testes realizados
- **CRÍTICO:** sempre inserir o emoji `✅` diretamente no texto — NUNCA usar a string `:check_mark:` ou qualquer outra representação textual
- O campo **Tema** deve ser sempre o `subject` exato do caso buscado da API (ex: `PDV - Trocar os schemas do CNPJ alfanumérico e validar a transmissão`) — nunca resumir ou inventar
- Casos de teste numerados: CT01, CT02, CT03...
- Passos numerados: **Passo 01**, **Passo 02**...
- Todas as situações encontradas sempre marcadas como `✅ **Situação corrigida.**`
- Ponto e vírgula ao final de cada item de lista com `*`

5. Após gerar o plano, pergunte ao usuário:
   > "O plano está aprovado? Deseja documentar na issue no Redmine?"

   - **Se não:** encerre. Nada é postado.
   - **Se sim:** pergunte se deseja ajustar mais alguma coisa antes de postar (ex: alterar status, atribuição, texto do plano). Aplique os ajustes solicitados e só então poste como nota na issue:
```powershell
$headers = @{ "X-Redmine-API-Key" = $config.api_key; "Content-Type" = "application/json" }
$body = @{ issue = @{ notes = "<plano gerado>" } } | ConvertTo-Json -Depth 5
Invoke-RestMethod -Uri "$($config.url)/issues/<id>.json" -Method Put -Headers $headers -Body $body
```
   Confirme ao usuário que o plano foi postado com sucesso.

**Regra absoluta: nunca postar, alterar ou executar qualquer ação no Redmine sem aprovação explícita do usuário.**

---

### /finalizar-caso
Consolida o encerramento de uma issue: verifica se o plano de teste existe, consulta o status e o tamanho SP, e finaliza o caso como Resolvido.

**Fluxo:**

1. Se o número da issue não foi informado, peça: *"Qual o número do caso? (#)"*

2. Busque os dados completos da issue incluindo journals e campos customizados:
```powershell
$headers = @{ "X-Redmine-API-Key" = $config.api_key }
$issue = Invoke-RestMethod -Uri "$($config.url)/issues/<id>.json?include=journals,custom_fields" -Headers $headers
```

3. Exiba um resumo do estado atual:
   - **Título** da issue
   - **Status** atual
   - **Tamanho SP** (campo customizado — procure em `custom_fields` pelo name `"Tamanho SP"` ou similar)

4. **Verifique se existe um Plano de Teste** — procure nos journals por uma nota que contenha o texto `"PLANO DE TESTE"`:
```powershell
$temPlano = $issue.issue.journals | Where-Object { $_.notes -match "PLANO DE TESTE" }
```

   - **Se NÃO existir plano:**
     > "Não encontrei nenhum Plano de Teste registrado nessa issue. Deseja gerar o plano de teste antes de finalizar? (/plano-teste)"
     - Se **sim**: execute o fluxo completo do `/plano-teste` e depois retome o `/finalizar-caso`
     - Se **não**: prossiga sem o plano

   - **Se existir plano:** continue normalmente

5. **CheckList Resolvido** (campo ID 126):

   Exiba as opções disponíveis e os itens já marcados (se houver):
   ```
   CheckList Resolvido — marque os itens aplicáveis:
   1. Análise de Risco
   2. Teste exploratório
   3. Criação dos cenários
   4. Automação dos testes
   5. Execução da Automação
   ```

   Pergunte ao usuário quais deseja marcar. Aceite respostas flexíveis:
   - `"todos"` → marca os 5 itens
   - `"1, 2, 3"` ou `"1 2 3"` → marca os itens indicados
   - `"somente 2"` → marca apenas o item 2
   - `"1, 3, 5"` → marca os itens 1, 3 e 5

   Monte o array com os nomes exatos dos itens selecionados:
   ```powershell
   # Exemplo: usuário escolheu 1, 2, 4, 5
   $checklist = @("Análise de risco", "Teste exploratório", "Automação dos testes", "Execução da Automação")
   ```

   Os nomes exatos aceitos pela API são:
   - `"Análise de risco"`
   - `"Teste exploratório"`
   - `"Criação dos cenários"`
   - `"Automação dos testes"`
   - `"Execução da Automação"`

6. **Tamanho SP:**
   - Se o campo estiver **vazio ou nulo**:
     > "O campo Tamanho SP está em branco. Qual o tamanho SP?"
   - Se já estiver **preenchido**:
     > "O Tamanho SP está como `<valor atual>`. Deseja ajustar?"
     - Se sim: peça o novo valor
     - Se não: mantenha o valor atual

6. **Identificar o desenvolvedor** — procure nos journals quem foi o último a mover o caso para "Em Desenvol." (status_id = 3) ou "Liber. Testes" (status_id = 4):
```powershell
$devJournal = $issue.issue.journals | Where-Object {
    $_.details | Where-Object { $_.name -eq "status_id" -and $_.new_value -in @("3", "4") }
} | Select-Object -Last 1

$devUser = $devJournal.user
```

   Exiba ao usuário:
   > "O desenvolvedor identificado foi **<devUser.name>**. Deseja atribuir o caso a ele ao resolver?"

   - Se **sim**: use `$devUser.id` como `assigned_to_id`
   - Se **não**: pergunte para quem deseja atribuir

7. **Finalizar como Resolvido:**
   > "Posso marcar o caso como Resolvido?"
   - Se **não**: encerre sem alterar o status
   - Se **sim**: busque o ID do status "Resolvido":
```powershell
$statuses = Invoke-RestMethod -Uri "$($config.url)/issue_statuses.json" -Headers $headers
$statusId = ($statuses.issue_statuses | Where-Object { $_.name -eq "Resolvido" }).id
```

8. **IMPORTANTE:** Nunca assuma que o usuário quer todos os itens do checklist. Sempre pergunte quais itens marcar antes de montar o resumo final.

9. Mostre o resumo completo do que será alterado e peça confirmação final antes de aplicar:
```
Issue #<id>: <título>
- Status: <atual> → Resolvido
- CheckList Resolvido: <itens selecionados>
- Tamanho SP: <atual> → <novo valor>
```

9. Aplique tudo em uma única chamada. Use heredoc com UTF-8 para evitar erro 400 com caracteres especiais e arrays:
```powershell
$headers["Content-Type"] = "application/json"

$body = @"
{
  "issue": {
    "status_id": $statusId,
    "assigned_to_id": <user_id_se_necessario>,
    "custom_fields": [
      { "id": 126, "value": ["Análise de risco", "Teste exploratório", "Criação dos cenários", "Automação dos testes", "Execução da Automação"] },
      { "id": 10, "value": "<tamanho_sp>" }
    ]
  }
}
"@
Invoke-RestMethod -Uri "$($config.url)/issues/<id>.json" -Method Put -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($body))
```

> ⚠️ Sempre use `[System.Text.Encoding]::UTF8.GetBytes($body)` ao enviar JSON com acentos ou arrays — o `ConvertTo-Json` do PowerShell pode causar erro 400 nesses casos.

9. Confirme o sucesso ao usuário com o título da issue e as alterações aplicadas.

**Regra absoluta: nunca alterar nada sem aprovação explícita do usuário a cada etapa.**

---

### /registrar-situacao
Registra uma situação encontrada durante os testes no caso, com descrição formatada e suporte a anexo de imagem.

**Fluxo:**

1. Se o número do caso não foi informado, peça: *"Qual o número do caso? (#)"*

2. Busque o título do caso para confirmar:
```powershell
$headers = @{ "X-Redmine-API-Key" = $config.api_key }
$issue = Invoke-RestMethod -Uri "$($config.url)/issues/<id>.json?include=journals" -Headers $headers
```
Exiba: **#id — Título do caso**

3. Verifique quantas situações já existem nos journals (procure por notas que contenham "Situação") para numerar a próxima corretamente.

4. Pergunte a situação:
   > "Qual a situação encontrada?"

5. Formate e melhore a descrição mantendo o conteúdo original, corrigindo gramática e deixando clara e objetiva. Monte no padrão:

```
*Situação <N>:*
<descrição formatada e melhorada>
```

6. Exiba a situação formatada ao usuário e pergunte:
   > "A descrição está correta? Posso registrar no caso?"
   
   Se não: peça ajustes e reformate.

7. **Lembrete de imagem — exiba sempre, em toda resposta deste comando:**
   > "📎 Lembre-se: se houver imagem, ela deve ser anexada como **arquivo** (arraste o arquivo até a conversa). Prints com Ctrl+V não funcionam como anexo no Redmine."

8. Pergunte se há imagem a anexar:
   > "Vai anexar alguma imagem? Se sim, arraste o arquivo aqui antes de confirmar."

   - **Se sim e o arquivo foi arrastado:** salve-o temporariamente e faça o upload antes de postar:
```powershell
$bytes = [System.IO.File]::ReadAllBytes("<caminho_temp>\imagem.png")
$uploadHeaders = @{ "X-Redmine-API-Key" = $config.api_key; "Content-Type" = "application/octet-stream" }
$upload = Invoke-RestMethod -Uri "$($config.url)/uploads.json" -Method Post -Headers $uploadHeaders -Body $bytes

$body = @{
    issue = @{
        notes = "<situacao formatada>"
        uploads = @(@{ token = $upload.upload.token; filename = "imagem.png"; content_type = "image/png" })
    }
} | ConvertTo-Json -Depth 5
```

   - **Se não:** poste apenas a nota:
```powershell
$headers["Content-Type"] = "application/json"
$body = @{ issue = @{ notes = "<situacao formatada>" } } | ConvertTo-Json -Depth 5
Invoke-RestMethod -Uri "$($config.url)/issues/<id>.json" -Method Put -Headers $headers -Body $body
```

9. Confirme o sucesso ao usuário com o número e título do caso.

---

### /refinar-caso
Registra a pontuação de refinamento de uma issue (Dev, Teste e Cenário) como nota no Redmine.

**Fluxo:**

1. Se o número da issue não foi informado, peça: *"Qual o número do caso? (#)"*

2. Busque o título da issue para confirmar:
```powershell
$headers = @{ "X-Redmine-API-Key" = $config.api_key }
$issue = Invoke-RestMethod -Uri "$($config.url)/issues/<id>.json" -Headers $headers
```
Exiba: **#id — Título da issue**

3. Pergunte a pontuação. Aceite qualquer formato:
   > "Qual a pontuação do refinamento? (Dev, Teste, Cenário — ex: `1, 6, sim` ou uma por linha)"

   Formatos aceitos:
   - `1, 6, sim` → Dev=1, Teste=6, Cenário=Sim
   - `1, 6, não` → Dev=1, Teste=6, Cenário=Não
   - Três linhas separadas:
     ```
     1
     6
     Sim
     ```

4. Monte a nota no formato de tabela Textile:

```
|  | *Pontuação* |
| *Dev* | 1 |
| *Teste* | 6 |
| *Cenário* | Sim |
```

5. Exiba a tabela gerada e pergunte:
   > "Está correto? Posso registrar na issue?"

   - **Se não:** peça as correções e remonte
   - **Se sim:** poste como nota na issue:
```powershell
$headers["Content-Type"] = "application/json"
$body = @{ issue = @{ notes = "<tabela gerada>" } } | ConvertTo-Json -Depth 5
Invoke-RestMethod -Uri "$($config.url)/issues/<id>.json" -Method Put -Headers $headers -Body $body
```

6. Confirme o sucesso com o título da issue.

---

## Observações gerais

- Sempre exibir o **título** da issue nas respostas
- Sempre confirmar com o usuário antes de aplicar qualquer alteração no Redmine
- Em caso de erro de autenticação, orientar o usuário a verificar o `config.json` em `Documentos\QA-FS-Redmine\`
- Novos comandos serão adicionados aqui conforme a skill crescer
