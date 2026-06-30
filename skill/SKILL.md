---
name: QA-FS-Redmine
description: Skill de Q.A para gerenciar issues no Redmine. Use sempre que o usuário digitar /inicia-teste, /plano-teste, ou qualquer comando relacionado a issues, casos, testes, status, plano de teste ou atribuições no Redmine. Também aciona quando o usuário menciona "issue", "caso", "redmine", "coloca em testes", "atribui pra mim", "gera plano de teste" ou qualquer operação de Q.A no Redmine.
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

## Comandos disponíveis

### /inicia-teste
Atribui uma issue ao usuário logado e muda o status para "Em Testes".

**Fluxo:**
1. Se o número da issue não foi informado, peça: *"Qual o número da issue? (#)"*
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

1. Se o número da issue não foi informado, peça: *"Qual o número da issue? (#)"*

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
Tema: <Projeto> – <descrição curta com **destaques** nos termos principais>

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

## Observações gerais

- Sempre exibir o **título** da issue nas respostas
- Sempre confirmar com o usuário antes de aplicar qualquer alteração no Redmine
- Em caso de erro de autenticação, orientar o usuário a verificar o `config.json` em `Documentos\QA-FS-Redmine\`
- Novos comandos serão adicionados aqui conforme a skill crescer
