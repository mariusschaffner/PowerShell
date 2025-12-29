function global:Search-History {
    <#
    .SYNOPSIS
    Search through the command history

    .DESCRIPTION
    Search through the history of command in the session with fzf

    .EXAMPLE
    PS> Search-History

    .EXAMPLE
    PS> sh

    .COMPONENT
    scoop:fzf
    psmodule:psreadline

    #>

    begin
    {
        $History = Get-Content (Get-PSReadLineOption).HistorySavePath | Select-Object -Unique
    }

    process
    {
        $Output = $History | fzf --height=70% --layout=reverse --info=inline --border
    }

    end
    {
        & $Output
    }
}
