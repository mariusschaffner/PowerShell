function global:Show-GitDiff {
    <#
    .SYNOPSIS
    Better git diff

    .DESCRIPTION
    Better git diff with nvim

    .EXAMPLE
    PS> Show-GitDiff

    .EXAMPLE
    PS> gd

    .COMPONENT
    scoop:neovim

    #>

    nvim -c "DiffviewOpen"
}
