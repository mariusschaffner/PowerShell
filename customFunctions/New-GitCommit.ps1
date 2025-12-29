function global:New-GitCommit {
    <#
    .SYNOPSIS
    Git commit with pretty output

    .DESCRIPTION
    Basic git commit wrapper including pretty output of Show-GitStatus

    .PARAMETER Args
    Arguments to pass to New-GitCommit (basic arguments of git commit)

    .EXAMPLE
    PS> New-GitCommit

    .EXAMPLE
    PS> gc

    .COMPONENT

    #>

    param(
        [string[]]$Args
    )

    # Check if git exists
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "Git is not installed or not in PATH." -ForegroundColor Red
        return
    }

    # Run git commit with whatever arguments were passed
    git commit @Args

    # Show updated status
    Show-GitStatus
}
