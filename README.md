# 🧪 QA-FS-Redmine

> Skill do Claude para automação de processos de Q.A no Redmine.

Essa skill conecta o Claude diretamente ao Redmine, permitindo gerenciar issues, iniciar testes, gerar planos de teste e finalizar casos — tudo sem sair da conversa.

---

## ✨ Comandos

| Comando | Descrição |
|---|---|
| `/inicia-teste` | Atribui a issue ao usuário logado e muda o status para **Em Testes** |
| `/plano-teste` | Lê toda a documentação da issue e gera um **Plano de Teste** completo no padrão da equipe |
| `/finalizar-caso` | Verifica plano de teste, preenche CheckList Resolvido, Tamanho SP e fecha o caso como **Resolvido** |
| `/refinar-caso` | Registra a pontuação de refinamento (Dev, Teste e Cenário) como tabela na issue |

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
  Issue #18072: Título da issue...
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
        O plano está aprovado? Deseja documentar na issue?

Usuário: Sim

Claude: Deseja ajustar algo antes de postar?
        (status, atribuição, texto...)

Usuário: Não, pode postar

Claude: ✅ Plano de teste postado na issue #18001!
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

## 📋 Fluxo — `/finalizar-caso`

```
Usuário: /finalizar-caso #18044

Claude:
  Issue #18044: Título da issue...
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

Usuário: todos

Claude:
  O Tamanho SP está como 7. Deseja ajustar?

Usuário: Não

Claude:
  Posso marcar a issue como Resolvido?

Usuário: Sim

Claude:
  Resumo das alterações:
  - Status: Em Testes → Resolvido
  - CheckList: todos os 5 itens marcados
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
  Issue #18044: Título da issue...
  Qual a pontuação do refinamento? (Dev, Teste, Cenário)

Usuário: 1, 6, sim

Claude:
  |  | Pontuação |
  | Dev | 1 |
  | Teste | 6 |
  | Cenário | Sim |

  Está correto? Posso registrar na issue?

Usuário: Sim

Claude: ✅ Refinamento registrado na issue #18044!
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
├── QA-FS-Redmine.skill   ← instale direto no Claude Desktop
└── skill/
    └── SKILL.md          ← instrução da skill para o Claude
```

---

## 🚀 Como instalar

### Opção 1 — Arquivo `.skill` (recomendado)

1. Baixe o arquivo [`QA-FS-Redmine.skill`](./QA-FS-Redmine.skill)
2. Abra o **Claude Desktop**
3. Vá em **Configurações → Skills → Instalar**
4. Selecione o arquivo `.skill` baixado

### Opção 2 — Pasta manual

1. Clone este repositório
2. Abra o **Claude Desktop**
3. Vá em **Configurações → Skills → Adicionar pasta**
4. Selecione a pasta `skill/` deste repositório

---

<div align="center">
  <sub>Desenvolvido por <a href="https://github.com/SamuelG05">Samuel Gonçalves</a></sub>
</div>
