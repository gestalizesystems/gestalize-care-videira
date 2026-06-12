# Roadmap: Testando seu App no Celular

Dois métodos cobertos neste roadmap:

| Método | Funciona em | Acesso externo | Complexidade |
|---|---|---|---|
| **Port Forwarding** | Mesmo Wi-Fi | Não | Alta (WSL2 tem muitas camadas) |
| **Túnel Reverso SSH** | Qualquer lugar | Sim | Baixa (um comando) |

Comece pelo Port Forwarding para aprender os conceitos. Use o Túnel quando quiser praticidade.

---

## Conceito 1 — Todo dispositivo tem um endereço (IP)

Quando você conecta ao Wi-Fi, o roteador entrega um **IP local** para cada dispositivo.  
Esse IP só funciona dentro da sua rede. Exemplos típicos:

```
Seu PC:     192.168.1.10
Seu celular: 192.168.1.25
Roteador:   192.168.1.1
```

O celular consegue "falar" com o PC usando esse IP — desde que estejam no mesmo Wi-Fi.

> Analogia: o IP local é como o número do apartamento dentro de um condomínio.  
> De dentro, você encontra qualquer apartamento. De fora, precisa do endereço do prédio.

---

## Conceito 2 — Portas: qual serviço atender a requisição

Um servidor pode rodar vários serviços ao mesmo tempo. As **portas** identificam cada um:

```
:3000  →  seu app Rails
:5432  →  banco PostgreSQL
:80    →  HTTP padrão
:443   →  HTTPS padrão
```

Quando você acessa `http://192.168.1.10:3000`, está dizendo:  
"Vai no IP `192.168.1.10`, bate na porta `3000`."

> Analogia: o IP é o prédio, a porta é o apartamento específico.

---

## Conceito 3 — Por que o app precisa "escutar" no IP certo

Por padrão, `bin/rails server` sobe escutando apenas em `127.0.0.1` (localhost).  
Isso significa: só aceita conexões vindas do próprio PC.

Com `-b 0.0.0.0` você diz: "aceite conexões de qualquer IP".  
Aí o celular consegue chegar.

```
127.0.0.1  →  só o próprio PC (loopback)
0.0.0.0    →  qualquer dispositivo na rede
```

---

## Conceito 4 — WSL2 tem IP separado do Windows

No WSL2, o Linux roda dentro de uma VM leve. Ele tem seu próprio IP interno,  
diferente do IP do Windows. Então há duas camadas:

```
Internet → Windows (IP da placa Wi-Fi) → WSL2 (IP interno) → Rails
```

Para o celular chegar no Rails, você precisa fazer o Windows "redirecionar" o tráfego para o WSL2.  
Isso se chama **port forwarding** (ou port proxy).

---

## Conceito 5 — Firewall

O Windows tem um firewall que bloqueia conexões externas por padrão.  
Mesmo com o port forwarding configurado, o firewall pode barrar o celular antes de chegar.  
Você precisa criar uma **regra** explícita liberando a porta 3000.

---

---

## Método 1 — Port Forwarding (Rede Local)

> Ensina os conceitos de IP, porta, NAT e firewall. Requer celular no mesmo Wi-Fi.

### Passo 1 — Descubra o IP do WSL

No terminal WSL, rode:

```bash
ip addr show eth0 | grep "inet "
```

Você vai ver algo como:
```
inet 172.24.16.1/20 brd ...
```

Anote esse IP. Vamos chamar de `<IP_WSL>`.

> O que aconteceu: você consultou as interfaces de rede do Linux.  
> `eth0` é a interface de rede da VM do WSL2.  
> `inet` é o IPv4 atribuído a ela.

---

### Passo 2 — Suba o Rails escutando em todos os IPs

```bash
bin/rails server -b 0.0.0.0 -p 3000
```

Deixe esse terminal aberto. O servidor vai ficar rodando aqui.

> `-b 0.0.0.0` = bind em todos os endereços (não só localhost)  
> `-p 3000` = porta 3000

---

### Passo 3 — Descubra o IP do Windows

Abra o **PowerShell do Windows** (não o WSL) e rode:

```powershell
ipconfig
```

Procure pela seção **"Adaptador de Rede sem Fio Wi-Fi"** e anote o `Endereço IPv4`.  
Exemplo: `192.168.1.10`. Vamos chamar de `<IP_WINDOWS>`.

> Esse é o IP que o celular vai usar para chegar no seu PC.

---

### Passo 4 — Configure o port forwarding (PowerShell como Administrador)

Clique com botão direito no PowerShell → "Executar como administrador". Depois rode:

```powershell
netsh interface portproxy add v4tov4 `
  listenport=3000 `
  listenaddress=0.0.0.0 `
  connectport=3000 `
  connectaddress=<IP_WSL>
```

Substitua `<IP_WSL>` pelo IP que você anotou no Passo 1.

> O que isso faz: "Windows, quando alguém bater na porta 3000 de qualquer IP,  
> redirecione para o IP `<IP_WSL>` na porta 3000 (que é o WSL2)."

Para confirmar que funcionou:
```powershell
netsh interface portproxy show all
```

---

### Passo 5 — Libere o firewall (PowerShell como Administrador)

```powershell
netsh advfirewall firewall add rule `
  name="Rails Dev 3000" `
  dir=in `
  action=allow `
  protocol=TCP `
  localport=3000
```

> O que isso faz: cria uma regra no firewall do Windows dizendo  
> "pode entrar tráfego TCP na porta 3000".

---

### Passo 6 — Teste no celular

1. Conecte o celular no **mesmo Wi-Fi** do PC
2. Abra o navegador do celular
3. Acesse: `http://<IP_WINDOWS>:3000`

Se tudo correu bem, você vai ver seu app Rails no celular.

---

### Passo 7 — Limpeza (quando terminar)

Rode no **PowerShell como Administrador**:

**Remover o port forwarding:**
```powershell
netsh interface portproxy delete v4tov4 listenport=3000 listenaddress=0.0.0.0
```

**Remover a regra de firewall:**
```powershell
netsh advfirewall firewall delete rule name="Rails Dev 3000"
```

**Verificar que foi removido (ambos devem retornar vazio):**
```powershell
netsh interface portproxy show all
netsh advfirewall firewall show rule name="Rails Dev 3000"
```

**Desabilitar o firewall do Hyper-V (se tiver desativado durante os testes):**
```powershell
Set-NetFirewallHyperVProfile -Profile Public -Enabled True
```

> Boa prática: sempre limpe depois. Regras acumuladas viram dívida técnica  
> e podem causar conflitos ou brechas de segurança no futuro.

---

## Troubleshooting

**Celular não consegue acessar:**
- Confirme que celular e PC estão no mesmo Wi-Fi
- Verifique se o Rails está rodando: no PC, acesse `http://localhost:3000`
- Verifique o port proxy: `netsh interface portproxy show all`
- Verifique a regra de firewall: `netsh advfirewall firewall show rule name="Rails Dev 3000"`
- O IP do WSL muda a cada reinicialização — refaça o Passo 1 e 4 se reiniciou o PC

**Erro de CSRF / requisições bloqueadas:**
Rails bloqueia hosts não reconhecidos. Adicione em `config/environments/development.rb`:
```ruby
config.hosts << "192.168.1.10"  # seu IP_WINDOWS
```

**Página carrega mas assets (CSS/JS) não:**
Mesmo problema de host. Adicione o IP como acima.

---

## O que você aprendeu

| Conceito | Onde apareceu |
|---|---|
| IP local | Passo 1 e 3 |
| Porta de serviço | `-p 3000` no Rails |
| Bind address | `-b 0.0.0.0` |
| WSL2 tem VM interna | Conceito 4 |
| Port forwarding / NAT | Passo 4 |
| Firewall | Passo 5 |

---

## Método 2 — Túnel Reverso SSH (localhost.run)

> Funciona de qualquer lugar, inclusive dados móveis. Não instala nada. Um comando só.

### Conceito — O que é um túnel reverso

Normalmente SSH é usado para você acessar um servidor remoto.  
No modo reverso (`-R`), é o contrário: o servidor remoto abre um canal de volta para o seu PC.

```
Celular → https://abc123.localhost.run → servidor localhost.run → túnel SSH → seu PC → Rails :3000
```

Seu PC **inicia** a conexão SSH (tráfego de saída), então o firewall não bloqueia.  
O servidor deles fica no meio fazendo a ponte — é exatamente o que ngrok e Cloudflare Tunnel fazem por baixo.

---

### Passo 1 — Suba o Rails normalmente

```bash
bin/rails server -p 3000
```

Não precisa de `-b 0.0.0.0` aqui. O túnel acessa pelo próprio `localhost`.

---

### Passo 2 — Abra um segundo terminal e crie o túnel

```bash
ssh -R 80:localhost:3000 nokey@localhost.run
```

O que cada parte faz:
- `ssh` — abre conexão SSH com o servidor `localhost.run`
- `-R 80:localhost:3000` — "redirecione a porta 80 do servidor remoto para `localhost:3000` aqui"
- `nokey@localhost.run` — conecta sem autenticação (conta anônima gratuita)

Vai aparecer algo como:
```
abc123.localhost.run tunneled with tls termination, https://abc123.localhost.run
```

---

### Passo 3 — Acesse no celular

Abra a URL gerada no celular — funciona de qualquer lugar, qualquer rede.

```
https://abc123.localhost.run
```

---

### Passo 4 — Encerrar

Só pressione `Ctrl+C` no terminal do SSH. O túnel fecha imediatamente.  
Não precisa limpar nada no Windows.

---

### Limitações do localhost.run (plano gratuito)

- URL muda a cada sessão (não é fixa)
- Pode ter limite de banda
- Não recomendado para produção — só para testes

---

## Próximos Passos (quando dominar isso)

1. **Port forwarding no roteador** — expor para a internet com IP público fixo
2. **DNS dinâmico (DynDNS/DuckDNS)** — seu IP público muda; um domínio fixo resolve isso
3. **Cloudflare Tunnel / ngrok** — entender por que esses serviços existem (CGNAT, IPs dinâmicos)
4. **Docker** — empacotar o app para rodar em qualquer máquina igual
5. **VPS** — servidor na nuvem com IP público fixo (DigitalOcean, Fly.io, etc.)
