# SetWinKeyboard

Scripts em PowerShell para manter apenas os layouts de teclado desejados no Windows e impedir que layouts extras continuem aparecendo no menu `Win + Espaço`.

## O problema

O Windows costuma adicionar ou manter layouts de teclado indesejados (como **ABNT** padrão ou **Estados Unidos Internacional**) após atualizações do sistema, sessões de Área de Trabalho Remota (RDP), abertura de determinados aplicativos ou reinicializações.

Mesmo quando a lista de idiomas é ajustada nas configurações, o Windows ainda pode manter layouts "fantasmas" carregados na sessão ativa, fazendo com que eles continuem aparecendo ao alternar o teclado com `Win + Espaço`.

## Como funciona

O repositório é composto por dois scripts que atuam em conjunto:

### 1. `Set-KeyboardLayouts.ps1` — Limpeza e configuração
Responsável por aplicar a configuração desejada no sistema em duas etapas:
1. **Redefine a lista de idiomas do usuário** para manter apenas:
   - **Português (Brasil) — ABNT2** (`pt-BR` / `0416:00010416`)
   - **Inglês (Estados Unidos) — US** (`en-US` / `0409:00000409`)
2. **Descarrega layouts "fantasmas" da sessão ativa** usando a API do Windows (`UnloadKeyboardLayout`), removendo imediatamente do `Win + Espaço` qualquer layout extra que ainda esteja carregado em memória.

### 2. `Register-KeyboardTask.ps1` — Automação
Cria a tarefa agendada **`ConfigureKeyboardLayouts`** no Agendador de Tarefas do Windows para executar o script de limpeza automaticamente:
- **Quando executa:** no logon do usuário atual e a cada **3 horas**.
- **Como executa:** em segundo plano (janela oculta), com privilégios elevados e mesmo quando o computador está na bateria.
- **Compatibilidade automática:** detecta se o PowerShell 7 (`pwsh`) está instalado e, caso não esteja, utiliza automaticamente o Windows PowerShell 5.1 nativo do sistema.
- **Recriação segura:** se a tarefa já existir, ela é removida e registrada novamente com as configurações atuais.

> Como a tarefa aponta diretamente para o arquivo `Set-KeyboardLayouts.ps1` na pasta do repositório, qualquer ajuste futuro nos layouts passa a valer automaticamente na próxima execução.

## Como usar

1. Abra o PowerShell **como Administrador** na pasta do projeto.
2. Execute `.\Set-KeyboardLayouts.ps1` para aplicar a limpeza imediatamente.
3. Execute `.\Register-KeyboardTask.ps1` para registrar a execução automática.

## Personalização

Os layouts mantidos são definidos na variável `$desiredLayouts` no início de `Set-KeyboardLayouts.ps1`, agrupados por idioma (`pt-BR`, `en-US`, etc.) com seus respectivos códigos de entrada.

A lista oficial de códigos de idioma e layout do Windows está disponível na [documentação da Microsoft](https://learn.microsoft.com/pt-pt/windows-hardware/manufacture/desktop/windows-language-pack-default-values?view=windows-11).

## Gerenciamento

A tarefa agendada pode ser consultada, executada manualmente ou removida pelo **Agendador de Tarefas** do Windows (nome: `ConfigureKeyboardLayouts`) ou via PowerShell usando os cmdlets nativos `Get-ScheduledTask`, `Start-ScheduledTask` e `Unregister-ScheduledTask`.

## Requisitos

- Windows 10 ou 11
- Windows PowerShell 5.1 (nativo) ou PowerShell 7+ (`pwsh`)
- Privilégios de Administrador

## Licença

Distribuído sob a licença MIT. Baseado originalmente no projeto de [Celso Fassoni](https://github.com/cfassoni). Consulte o arquivo [LICENSE](LICENSE) para mais detalhes.
