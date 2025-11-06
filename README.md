# Windows Keyboard Layout Configuration Scripts

## The Problem

Windows has a frustrating habit of automatically adding or changing keyboard
layouts without user intervention. This commonly happens when:

- Installing Windows updates
- Connecting to remote desktop sessions
- Installing language packs
- Switching between different input sources

These unwanted keyboard changes can disrupt workflow, especially for users who
work with multiple languages but need specific keyboard layouts for each.
Windows often adds standard keyboards that don't match your preferences, leading
to constant manual reconfiguration.

## The Solution

This repository contains PowerShell scripts to automatically enforce specific
keyboard layouts for en-US and pt-BR languages. The scripts:

- Remove any unwanted keyboard layouts
- Configure only the keyboards you specify
- Run automatically at logon and hourly to prevent Windows from reverting
  changes

## Scripts Overview

### `Set-KeyboardLayouts.ps1`

The main script that configures keyboard layouts. It:

- Checks current keyboard configurations for all languages
- Removes keyboards that don't match the desired configuration
- Sets the following keyboards:
  - **en-US (0409)**: US QWERTY keyboard (`00000409`)
  - **pt-BR (0416)**: US-International keyboard (`00020409`)
- Includes commented option for ABNT2 keyboard (`00010416`) for both languages

**Note**: Requires Administrator privileges to modify system keyboard settings.

### `Register-KeyboardTask.ps1`

Creates a Windows scheduled task to run the keyboard configuration script
automatically. The task:

- Runs at user logon
- Runs every hour (recurring)
- Executes with highest privileges
- Runs hidden in the background

## Usage

### Initial Setup

1. **Clone or download this repository** to your local machine

2. **Configure your preferred keyboards** (if needed):

   - Open `Set-KeyboardLayouts.ps1` in a text editor
   - By default, it uses US QWERTY for en-US and US-International for pt-BR
   - To use ABNT2 keyboards instead, comment out the current keyboard lines and
     uncomment the ABNT2 lines:
     ```powershell
     $desiredLayouts = @{
         # "0409" = "00000409"  # en-US with US QWERTY
         # "0416" = "00020409"  # pt-BR with US-International
         "0409" = "00010416"  # en-US with ABNT2
         "0416" = "00010416"  # pt-BR with ABNT2
     }
     ```

3. **Run the keyboard configuration script** (as Administrator):

   ```powershell
   .\Set-KeyboardLayouts.ps1
   ```

4. **Set up automatic execution** (as Administrator):
   ```powershell
   .\Register-KeyboardTask.ps1
   ```

### Managing the Scheduled Task

**View the task:**

```powershell
Get-ScheduledTask -TaskName 'ConfigureKeyboardLayouts'
```

**Run the task immediately:**

```powershell
Start-ScheduledTask -TaskName 'ConfigureKeyboardLayouts'
```

**Remove the scheduled task:**

```powershell
Unregister-ScheduledTask -TaskName 'ConfigureKeyboardLayouts' -Confirm:$false
```

### Manual Execution

If you prefer not to use the scheduled task, you can run
`Set-KeyboardLayouts.ps1` manually whenever Windows changes your keyboard
settings.

## Requirements

- Windows 10 or later
- PowerShell 7+ (pwsh) or Windows PowerShell 5.1+
- Administrator privileges

## Notes

- After running the keyboard configuration script, you may need to sign out and
  sign back in for changes to take full effect
- The scheduled task runs with highest privileges to ensure it can modify
  keyboard settings
- The task is configured to run even on battery power (useful for laptops)
- If you modify `Set-KeyboardLayouts.ps1` after creating the scheduled task, the
  changes will be applied automatically on the next trigger

## Customization

To add or modify keyboard layouts, edit the `$desiredLayouts` hashtable in
`Set-KeyboardLayouts.ps1`. The format is:

```powershell
$desiredLayouts = @{
    "LanguageCode" = "KeyboardCode"
}
```

Common keyboard codes:

- `00000409` - US QWERTY
- `00020409` - US-International
- `00010416` - Brazilian ABNT2

See
[Microsoft's documentation](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/default-input-locales-and-keyboard-layouts)
for a full list of language and keyboard codes.

## License

Feel free to use and modify these scripts as needed.
