#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Configura os layouts de teclado permitidos no sistema.

.DESCRIPTION
    Este script redefine completamente a lista de idiomas e layouts de teclado,
    mantendo apenas os idiomas e layouts especificados:
    - Português (Brasil) — ABNT2 (0416:00010416)
    - Inglês (Estados Unidos) — US (0409:00000409)

    Além de aplicar a lista oficial de idiomas do usuário, também descarrega
    layouts "fantasmas" carregados na sessão ativa do Windows para que o menu
    Win + Espaço exiba imediatamente apenas os layouts desejados.
#>

$desiredLayouts = [ordered]@{
    "pt-BR" = @(
        "0416:00010416"  # Português (Brasil) — ABNT2
    )
    "en-US" = @(
        "0409:00000409"  # Inglês (Estados Unidos) — US
    )
}

function Get-ExpectedHkl {
    param([string]$InputMethodTip)

    $parts = $InputMethodTip -split ":"
    if ($parts.Count -ne 2) {
        return $null
    }

    $langId = [Convert]::ToUInt32($parts[0], 16) -band 0xFFFF
    $klid = $parts[1].ToUpperInvariant()
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\$klid"
    $layoutIdProp = (Get-ItemProperty -Path $regPath -Name "Layout Id" -ErrorAction SilentlyContinue).'Layout Id'

    if ($layoutIdProp) {
        $deviceId = [uint64](0xF000 -bor ([Convert]::ToUInt32($layoutIdProp, 16) -band 0x0FFF))
    } else {
        $deviceId = [uint64]([Convert]::ToUInt32($klid, 16) -band 0xFFFF)
    }

    return [uint32](($deviceId -shl 16) -bor [uint64]$langId)
}

Write-Host "Starting keyboard layout configuration..." -ForegroundColor Cyan

# Criar lista nova contendo apenas os idiomas e layouts desejados
$newLanguageList = $null
$expectedHkls = @()

foreach ($langTag in $desiredLayouts.Keys) {
    if ($null -eq $newLanguageList) {
        $newLanguageList = New-WinUserLanguageList -Language $langTag
    } else {
        $newLanguageList.Add($langTag)
    }

    $lang = $newLanguageList | Where-Object { $_.LanguageTag -eq $langTag }
    $lang.InputMethodTips.Clear()

    foreach ($tip in $desiredLayouts[$langTag]) {
        Write-Host "Adding layout: $langTag -> $tip" -ForegroundColor Green
        $lang.InputMethodTips.Add($tip)

        $hkl = Get-ExpectedHkl -InputMethodTip $tip
        if ($null -ne $hkl) {
            $expectedHkls += $hkl
        }
    }
}

# Aplicar configuração
try {
    Write-Host "`nApplying new keyboard configuration..." -ForegroundColor Cyan
    Set-WinUserLanguageList -LanguageList $newLanguageList -Force

    # Descarregar layouts "fantasmas" que permaneçam carregados na sessão ativa
    if ($expectedHkls.Count -gt 0) {
        if (-not ("Win32.KeyboardLayoutHelper" -as [type])) {
            Add-Type -Namespace Win32 -Name KeyboardLayoutHelper -MemberDefinition @"
[DllImport("user32.dll")]
public static extern int GetKeyboardLayoutList(int nBuff, [Out] IntPtr[] lpList);

[DllImport("user32.dll")]
public static extern bool UnloadKeyboardLayout(IntPtr hkl);
"@
        }

        $count = [Win32.KeyboardLayoutHelper]::GetKeyboardLayoutList(0, $null)
        if ($count -gt 0) {
            $loadedLayouts = New-Object IntPtr[] $count
            [Win32.KeyboardLayoutHelper]::GetKeyboardLayoutList($count, $loadedLayouts) | Out-Null

            foreach ($hklPtr in $loadedLayouts) {
                $hkl32 = [uint32]($hklPtr.ToInt64() -band [int64]4294967295)
                if ($expectedHkls -notcontains $hkl32) {
                    $unloaded = [Win32.KeyboardLayoutHelper]::UnloadKeyboardLayout($hklPtr)
                    Write-Host ("Unloading unwanted active layout 0x{0:X8}: {1}" -f $hkl32, $unloaded) -ForegroundColor Yellow
                }
            }
        }
    }

    Write-Host "✅ Keyboard layouts configured successfully!" -ForegroundColor Green
    Write-Host "`nFinal configuration:" -ForegroundColor Yellow
    Get-WinUserLanguageList | Select-Object LanguageTag, InputMethodTips
} catch {
    Write-Host "❌ Error applying keyboard configuration: $_" -ForegroundColor Red
    exit 1
}
