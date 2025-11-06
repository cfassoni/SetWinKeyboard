#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Configures keyboard layouts for en-US and pt-BR languages.

.DESCRIPTION
    This script ensures only the following keyboard layouts are configured:
    - en-US (0409): US QWERTY keyboard
    - pt-BR (0416): US-International keyboard (00020409)
    
    It removes any other keyboard layouts and sets the correct ones.
#>

# Define the desired language and keyboard layout mappings
# Uncomment the ABNT2 lines below and comment the current ones when you need ABNT2 keyboards
$desiredLayouts = @{
    "0409" = "00000409"  # en-US with US QWERTY
    "0416" = "00020409"  # pt-BR with US-International
    # "0409" = "00010416"  # en-US with ABNT2
    # "0416" = "00010416"  # pt-BR with ABNT2
}

Write-Host "Starting keyboard layout configuration..." -ForegroundColor Cyan

# Get current language list
$languageList = Get-WinUserLanguageList

Write-Host "`nCurrent languages configured:" -ForegroundColor Yellow
foreach ($lang in $languageList) {
    Write-Host "  - $($lang.LanguageTag) with keyboard(s): $($lang.InputMethodTips -join ', ')"
}

# Create new language list with correct keyboards
$newLanguageList = New-WinUserLanguageList -Language "en-US"

foreach ($langTag in @("en-US", "pt-BR")) {
    $langCode = switch ($langTag) {
        "en-US" { "0409" }
        "pt-BR" { "0416" }
    }
    
    $keyboardCode = $desiredLayouts[$langCode]
    $inputMethodTip = "${langCode}:${keyboardCode}"
    
    Write-Host "`nProcessing $langTag..." -ForegroundColor Green
    
    # Check if language already exists in new list
    $existingLang = $newLanguageList | Where-Object { $_.LanguageTag -eq $langTag }
    
    if ($null -eq $existingLang) {
        # Add language if it doesn't exist
        Write-Host "  Adding $langTag to language list" -ForegroundColor Yellow
        $newLang = New-WinUserLanguageList -Language $langTag
        $newLanguageList += $newLang[0]
        $existingLang = $newLanguageList | Where-Object { $_.LanguageTag -eq $langTag }
    }
    
    # Clear existing keyboards
    Write-Host "  Clearing existing keyboards for $langTag"
    $existingLang.InputMethodTips.Clear()
    
    # Add the correct keyboard
    Write-Host "  Adding keyboard: $inputMethodTip"
    $existingLang.InputMethodTips.Add($inputMethodTip)
}

# Apply the new language list
Write-Host "`nApplying new keyboard configuration..." -ForegroundColor Cyan
try {
    Set-WinUserLanguageList -LanguageList $newLanguageList -Force
    Write-Host "✓ Keyboard layouts configured successfully!" -ForegroundColor Green
    
    Write-Host "`nNew configuration:" -ForegroundColor Yellow
    foreach ($lang in $newLanguageList) {
        Write-Host "  - $($lang.LanguageTag) with keyboard(s): $($lang.InputMethodTips -join ', ')"
    }
    
    Write-Host "`nNote: You may need to sign out and sign back in for changes to take full effect." -ForegroundColor Magenta
}
catch {
    Write-Host "✗ Error applying keyboard configuration: $_" -ForegroundColor Red
    exit 1
}
