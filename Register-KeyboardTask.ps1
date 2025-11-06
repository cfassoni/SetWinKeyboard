#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Creates a scheduled task to run the keyboard layout configuration script.

.DESCRIPTION
    This script creates a scheduled task that:
    - Runs at user logon
    - Runs every hour recurrently
    - Executes the Set-KeyboardLayouts.ps1 script
#>

$taskName = "ConfigureKeyboardLayouts"
$scriptPath = Join-Path $PSScriptRoot "Set-KeyboardLayouts.ps1"
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

Write-Host "Creating scheduled task: $taskName" -ForegroundColor Cyan
Write-Host "Script to run: $scriptPath" -ForegroundColor Yellow
Write-Host "User: $currentUser" -ForegroundColor Yellow

# Check if script exists
if (-not (Test-Path $scriptPath)) {
    Write-Host "✗ Error: Set-KeyboardLayouts.ps1 not found at $scriptPath" -ForegroundColor Red
    exit 1
}

# Remove existing task if it exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "`nRemoving existing task..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Define the action - run PowerShell with the script
$action = New-ScheduledTaskAction `
    -Execute "pwsh.exe" `
    -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""

# Define triggers
# Trigger 1: At logon
$triggerLogon = New-ScheduledTaskTrigger -AtLogOn -User $currentUser

# Trigger 2: Every hour (repeating)
$triggerHourly = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1)

# Combine triggers
$triggers = @($triggerLogon, $triggerHourly)

# Define principal (run with highest privileges)
$principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive -RunLevel Highest

# Define settings
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

# Register the scheduled task
try {
    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $triggers `
        -Principal $principal `
        -Settings $settings `
        -Description "Configures keyboard layouts for en-US and pt-BR at logon and every hour" `
        -Force | Out-Null
    
    Write-Host "`n✓ Scheduled task created successfully!" -ForegroundColor Green
    Write-Host "`nTask details:" -ForegroundColor Yellow
    Write-Host "  Name: $taskName"
    Write-Host "  Triggers:"
    Write-Host "    - At user logon"
    Write-Host "    - Every hour (recurring)"
    Write-Host "  Action: Run Set-KeyboardLayouts.ps1"
    Write-Host "  User: $currentUser"
    Write-Host "  Run Level: Highest privileges"
    
    # Show the task
    Write-Host "`nVerifying task..." -ForegroundColor Cyan
    Get-ScheduledTask -TaskName $taskName | Format-Table -Property TaskName, State, TaskPath -AutoSize
    
    Write-Host "`nTo manage this task:" -ForegroundColor Magenta
    Write-Host "  View: Get-ScheduledTask -TaskName '$taskName'"
    Write-Host "  Run now: Start-ScheduledTask -TaskName '$taskName'"
    Write-Host "  Remove: Unregister-ScheduledTask -TaskName '$taskName' -Confirm:`$false"
}
catch {
    Write-Host "✗ Error creating scheduled task: $_" -ForegroundColor Red
    exit 1
}
