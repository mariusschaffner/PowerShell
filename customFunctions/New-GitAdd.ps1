function global:New-GitAdd {
    <#
    .SYNOPSIS
    Git add with pretty output

    .DESCRIPTION
    Basic git add wrapper including pretty output of Show-GitStatus

    .PARAMETER Args
    Arguments to pass to New-GitAdd (basic arguments of git add)

    .EXAMPLE
    PS> New-GitAdd

    .EXAMPLE
    PS> ga

    .COMPONENT

    #>

    param(
        [string[]]$Args = @()
    )

    # Check if git exists
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "Git is not installed or not in PATH." -ForegroundColor Red
        return
    }

    # Run git add with the provided arguments
    if ($Args.Count -eq 0) {
        git add .
    } else {
        git add @Args
    }

    # Show updated status
    Show-GitStatus
}
