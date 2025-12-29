function global:Import-EnvVars {
    <#
    .SYNOPSIS
    Imports variables from a .env file

    .DESCRIPTION
    Checks if an .env file exists and import variables into current process scope.

    .EXAMPLE
    Import-EnvVars

    .COMPONENT

    #>

    param(
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Path = ".env"
    )

    # Check if env file exists
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host ".env file not found at: $Path" -ForegroundColor DarkYellow
        return
    }

    # Load env vars into context
    Get-Content .env | ForEach-Object {
        if ($_ -match "^\s*([^#][^=]+)=(.+)$") {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
}
