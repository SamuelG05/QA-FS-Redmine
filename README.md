# 🧪 QA-FS-Redmine

> Skill do Claude para automação de processos de Q.A no Redmine.

Essa skill conecta o Claude diretamente ao Redmine, permitindo gerenciar issues, iniciar testes e gerar planos de teste documentados — tudo sem sair da conversa.

---

## ✨ Funcionalidades

| Comando | Descrição |
|---|---|
| `/inicia-teste` | Atribui a issue ao usuário logado e muda o status para **Em Testes** |
| `/plano-teste` | Lê toda a documentação da issue e gera um **Plano de Teste** completo no padrão da equipe |

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
        [gera plano completo em formato Textile]

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

## 🔒 Segurança

- Nenhuma credencial é armazenada na skill ou no repositório
- O Claude **nunca executa ações no Redmine sem aprovação explícita** do usuário
- O `config.json` é gerado localmente e fica apenas na máquina do usuário

---

## 📁 Estrutura do Repositório

```
QA-FS-Redmine/
├── README.md
└── skill/
    └── SKILL.md       ← instrução da skill para o Claude
```

---

## 🚀 Como instalar a skill

1. Abra o **Claude Desktop**
2. Vá em **Configurações → Skills**
3. Adicione a pasta `skill/` deste repositório
4. Use `/inicia-teste` ou `/plano-teste` em qualquer conversa

---

<div align="center">
  <sub>Desenvolvido por <a href="https://github.com/SamuelG05">Samuel Gonçalves</a></sub>
</div>
