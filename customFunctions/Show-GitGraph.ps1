function global:Show-GitGraph {
    <#
    .SYNOPSIS
    Better git graph

    .DESCRIPTION
    Better git graph with nvim

    .EXAMPLE
    PS> Show-GitGraph

    .EXAMPLE
    PS> gg

    .COMPONENT
    scoop:neovim

    #>

    nvim -c "lua require('gitgraph').draw({}, { all = true, max_count = 5000 })"
}
