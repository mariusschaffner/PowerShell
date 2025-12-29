function global:search {
    <#
    .SYNOPSIS
    search in files in current directory

    .DESCRIPTION
    Search through all contents of all file sin the current dir useing nvim snacks.picker

    .EXAMPLE
    PS> search

    .COMPONENT
    scoop:neovim

    #>

    nvim -c "lua Snacks.picker.grep()"
}
