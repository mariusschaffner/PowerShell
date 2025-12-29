function global:help-me {
    param(
        # for full detailed output
        [switch] $full
    )

    Write-Host ""
    Write-Host "Overview of Profile Config: " -ForegroundColor Blue

    Write-Host ""
    Write-Host "[ALIASES]" -ForegroundColor Cyan

    $AliasData = $GlobalAliases.Keys
    $AliasKeys = ($AliasData -split "`n")

    if ((-not ($full.IsPresent)) -and ($AliasKeys.Count -gt 5)) {
        for ($i = 0; $i -lt 5; $i++) {
            Write-Host "$($AliasKeys[$i]) `t  `t $($GlobalAliases[$AliasKeys[$i]])"
        }

        Write-Host "--- $($AliasKeys.Count - 5) more ---" -ForegroundColor DarkGray
    } else {
        for ($i = 0; $i -lt $AliasKeys.Count; $i++) {
            Write-Host "$($AliasKeys[$i]) `t  `t $($GlobalAliases[$AliasKeys[$i]])"
        }
    }

    Write-Host ""
    Write-Host "[FUNCTIONS]" -ForegroundColor Cyan

    if ((-not ($full.IsPresent)) -and ($GlobalFunctions.Count -gt 5)) {
        for ($i = 0; $i -lt 5; $i++) {
            Write-Host "$($GlobalFunctions[$i].Name)"
        }

        Write-Host "--- $($GlobalFunctions.Count - 5) more ---" -ForegroundColor DarkGray
    } else {
        for ($i = 0; $i -lt $GlobalFunctions.Count; $i++) {
            Write-Host "$($GlobalFunctions[$i].Name)" -ForegroundColor Green
            Write-Host "Description: "
            Write-Host "   $($GlobalFunctions[$i].Description)"
            Write-Host "Syntax: "
            foreach ($SyntaxLine in ($GlobalFunctions[$i].Syntax -split "`n")) {
                Write-Host "   $($SyntaxLine)"
            }
            Write-Host ("-" * $Host.UI.RawUI.WindowSize.Width) -ForegroundColor DarkGray
        }
    }
}
