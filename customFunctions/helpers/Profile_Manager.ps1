function global:Profile-Manager {
    <#
    .SYNOPSIS
    Global Profile Manager

    .DESCRIPTION
    dfsadf

    .PARAMETER ScriptName
    aaa

    .EXAMPLE
    aaa

    .COMPONENT

    #>
    param (
        $CustomFunctions,
        $GlobalPackages
    )

    if ($CustomFunctions) {

        # Load all files in customFunctions dir
        $ScriptFolder = Get-ChildItem $CustomFunctions -File

        # Set list for function holders
        $AvailableFunctions = [System.Collections.Generic.List[psobject]]::new()
        $RegisterdFunctions = [System.Collections.Generic.List[psobject]]::new()

        # dot-source all scripts in ScriptFolder
        foreach ($Script in $ScriptFolder) {
            . $Script.FullName
            $AvailableFunctions.Add($Script)
        }

        # extract help info from script file synopsis
        foreach ($Function in $AvailableFunctions) {
            $FunctionName = $Function.Name -replace ".ps1", ""
            $ScriptHelp = Get-help $FunctionName -Full

            # Bild Obj with help data for help-me output
            $HelpObj = [PSCustomObject]@{
                Name            = $ScriptHelp.Name
                Description     = $ScriptHelp.Description.Text
                Category        = $ScriptHelp.Category
                Syntax          = ($ScriptHelp.Syntax | Out-String).Trim()
                RequiredModules = $ScriptHelp.COMPONENT -split "`n"
            }

            # Add HelpObj to holder list
            $RegisterdFunctions.Add($HelpObj)
        }

        return $RegisterdFunctions
    }

    if ($GlobalPackages) {
        $ProfileDir = Split-Path $PROFILE -Parent
        $CachePath = "$($ProfileDir)\customFunctions\helpers\GlobalPackages.hash"

        # Create hash of the current package list (for change detection)
        $currentHash = [System.BitConverter]::ToString(
            (New-Object System.Security.Cryptography.SHA256Managed).ComputeHash(
                [System.Text.Encoding]::UTF8.GetBytes(($GlobalPackages -join "`n"))
            )
        ) -replace '-', ''

        # If cache exists and hash matches, skip scan
        if (Test-Path $CachePath) {
            $cachedHash = (Get-Content $CachePath -Raw).Trim()
            if ($cachedHash -eq $currentHash) {
                return
            }
        }

        Write-Host "🔍 Checking for missing global packages..." -ForegroundColor Cyan
        $MissingPackages = @()

        foreach ($pkg in $GlobalPackages) {
            $type = ($pkg -split ":")[0]
            $name = ($pkg -split ":")[1]

            switch ($type) {
                'psmodule' {
                    if (-not (Get-Module -ListAvailable -Name $name)) {
                        $MissingPackages += "Install-Module $name -Force"
                    }
                }
                'scoop' {
                    # More reliable check using scoop export (if available)
                    $isInstalled = $false
                    try {
                        $scoopList = scoop export | ConvertFrom-Json
                        if ($scoopList.apps.name -contains $name) { $isInstalled = $true }
                    } catch {
                        # Fallback if export not supported
                        $isInstalled = scoop list | Select-String -SimpleMatch $name
                    }

                    if (-not $isInstalled) {
                        $MissingPackages += "scoop install $name"
                    }
                }
                'pip' {
                    if (-not (pip show $name)) {
                        $MissingPackages += "pip install $name"
                    }
                }
                'winget' {
                    $Installed = winget list $name
                    if ($LASTEXITCODE -ne 0) {
                        $MissingPackages += "winget install $name"
                    }
                }
                default {
                    Write-Warning "Unknown package type '$type' in entry '$pkg'"
                }
            }
        }

        if ($MissingPackages.Count -gt 0) {
            Write-Host "`n📦 The following packages are missing:" -ForegroundColor Yellow
            $MissingPackages | ForEach-Object { Write-Host "  $_" -ForegroundColor White }

            Write-Host "`n💡 Run the above commands manually to install missing packages." -ForegroundColor Cyan
        } else {
            Write-Host "✅ All global packages are already installed." -ForegroundColor Green
        }

        # Update hash file after check
        Set-Content -Path $CachePath -Value $currentHash
    }
}
