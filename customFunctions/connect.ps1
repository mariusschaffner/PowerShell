function global:connect {
    <#
    .SYNOPSIS
    ssh connection manager

    .DESCRIPTION
    Connect to servers from the ssh_config with fzf picker

    .EXAMPLE
    PS> connect

    .EXAMPLE
    PS> connect <servername>

    .COMPONENT
    scoop:fzf

    #>

    param(
        [Parameter(Mandatory=$false)]
        [string]$HostAlias
    )

    $randomNumber = Get-Random -Minimum 0 -Maximum 0x1000000
    $TabColor = ('#{0:X6}' -f $randomNumber)

    # If user passed a host → connect immediately
    if ($HostAlias) {
        wt new-tab --tabColor $TabColor -- ssh $HostAlias
        return
    }

    # Otherwise show fzf picker
    $configPath = "$env:USERPROFILE\.ssh\config"
    if (-not (Test-Path $configPath)) {
        Write-Error "SSH config file not found: $configPath"
        return
    }

    # Read config
    $lines = Get-Content $configPath

    # Variables for parsing
    $currentHost = $null
    $currentHostName = $null
    $entries = @()

    foreach ($line in $lines) {

        # Start of a new Host block
        if ($line -match '^\s*Host\s+(.+)$') {

            # Save previous block before starting new one
            if ($currentHost -and $currentHostName) {
                $entries += [PSCustomObject]@{
                    Host     = $currentHost
                    HostName = $currentHostName
                }
            }

            $currentHost = $matches[1].Trim()
            $currentHostName = $null
            continue
        }

        # HostName inside block
        if ($line -match '^\s*HostName\s+(.+)$') {
            $currentHostName = $matches[1].Trim()
            continue
        }
    }

    # Save last block
    if ($currentHost -and $currentHostName) {
        $entries += [PSCustomObject]@{
            Host     = $currentHost
            HostName = $currentHostName
        }
    }

    if ($entries.Count -eq 0) {
        Write-Error "No Host entries found in SSH config."
        return
    }

    $maxHostLength = ($entries | ForEach-Object { $_.Host.Length } | Measure-Object -Maximum).Maximum

    # Build aligned rows
    $rows = $entries | ForEach-Object {
        $hostn = $_.Host.PadRight($maxHostLength + 8)
        "$hostn$($_.HostName)"
    }

    # fzf display
    $selected = $rows |
        fzf --height=70% --layout=reverse --info=inline --border

    if (-not $selected) { return }

    # Extract the host (left side before padding)
    $alias = $selected.Substring(0, $maxHostLength).Trim()

    wt new-tab --tabColor $TabColor -- ssh $alias
}
