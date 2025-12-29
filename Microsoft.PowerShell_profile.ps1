#--------------------------------------------------------------------------------------#
# GLOBAL VARIABLES

# Path of the Powershell Profile directory
$ProfileDir = Split-Path $PROFILE -Parent

# Path of the custom functions for the Profile
$CustomFunctions = "$($ProfileDir)\customFunctions"

# Path of the oh-my-posh config
$OhMyPoshConfig = "$($ProfileDir)\oh_my_posh\promptconfig.omp.json"

# Required aliases for daily usage of terminal
$GlobalAliases = @{
    ll = "dir"                  # Print directory / files output
    n = "nvim"                  # Neovim
    b = "bat"                   # Bat
    sh = "Search-History"       # Global History searching
    gs = "Show-GitStatus"       # Better git status output
    ga = "New-GitAdd"           # Better git add
    gco = "New-GitCommit"       # Better git commit
    gg = "Show-GitGraph"        # Better git graph view
    gd = "Show-GitDiff"         # Better git diff view
    rm = "Save-Remove"          # Save delete file to trash folder
    rs = "Save-Restore"         # Save restore file from trash folder
}

# Required packages for daily usage of terminal
$GlobalPackages = @(
    "psmodule:PSReadLine",           # Enables command suggestion / intellisense features
    "psmodule:CompletionPredictor",  # Adds Completion to PsReadline
    "psmodule:Terminal-Icons",       # Adds Icons to the terminal output
    "scoop:bat",                     # Cat with color
    "scoop:delta",                   # Prettier git diff output
    "scoop:fd",                      # Find files
    "scoop:fzf",                     # Fuzzy finder with UI
    "scoop:neovim",                  # VIM based console IDE
    "scoop:ripgrep",                 # Search for text in files
    "scoop:win32yank",               # Used for clipboard with neovim
    "winget:thomasschafer.scooter",  # Search and Replace tool for terminal
    "pip:tftui"                      # TUI for terraform state management
)

#--------------------------------------------------------------------------------------#
# PRE-SETUP MODULES & CONFIGS

# Import Modules
Import-Module Terminal-Icons
Import-Module CompletionPredictor

# init custom oh-my-posh-prompt
oh-my-posh init pwsh --config $OhMyPoshConfig | Invoke-Expression

# init psreadline options
try
{
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
    Set-PSReadLineOption -MaximumHistoryCount 50000
} catch
{
}

# Set alias in profile scope
$AliasData = $GlobalAliases.Keys
$AliasKeys = ($AliasData -split "`n")
for ($i = 0; $i -lt $GlobalAliases.Count; $i++)
{
    Set-Alias -Name $AliasKeys[$i] -Value $GlobalAliases[$AliasKeys[$i]]
}

# Disable nvim in within nvim
if ($env:NVIM)
{
    function nvim
    {
        Write-Host "You are already inside Neovim. Use <A-T> to exit ToggleTerm."
        return
    }
}

#--------------------------------------------------------------------------------------#
# IMPORT Profile Manager

. "$($CustomFunctions)\helpers\Profile_Manager.ps1"

# Load Functions
$GlobalFunctions = Profile-Manager -CustomFunctions $CustomFunctions

# Check Package installation
$GlobalPackagesInstalled = Profile-Manager -GlobalPackages $GlobalPackages
