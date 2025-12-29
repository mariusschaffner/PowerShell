function global:Show-GitStatus {
    <#
    .SYNOPSIS
    Better git status

    .DESCRIPTION
    Better git diff status

    .EXAMPLE
    PS> Show-GitStatus

    .EXAMPLE
    PS> gs

    .COMPONENT

    #>

    # --- Helper: Check if inside a git repo ---
    function Test-InGitRepo {
        $inside = git rev-parse --is-inside-work-tree 2>$null
        return ($inside -eq "true")
    }

    # --- Helper: Parse branch status ---
    function Get-BranchStatus($statusLines) {
        $branch   = ($statusLines | Where-Object { $_ -like '# branch.head*' }) -replace '# branch.head ', ''
        $upstream = ($statusLines | Where-Object { $_ -like '# branch.upstream*' }) -replace '# branch.upstream ', ''
        $aheadInfo= ($statusLines | Where-Object { $_ -like '# branch.ab*' }) -replace '# branch.ab ', ''

        $aheadCount = 0
        $behindCount = 0
        if ($aheadInfo) {
            $split = $aheadInfo.Split(' ')
            $aheadCount = [int]($split[0].Replace('+',''))
            $behindCount = [int]($split[1].Replace('-',''))
        }
        [PSCustomObject]@{
            Branch      = $branch
            Upstream    = $upstream
            AheadCount  = $aheadCount
            BehindCount = $behindCount
        }
    }

    # --- Helper: Get tag info ---
    function Get-TagInfo($upstream) {
        $tagAtHead   = git describe --tags --exact-match 2>$null
        $nearestTag  = git describe --tags 2>$null
        $remoteTags  = @()
        if ($upstream) {
            $remoteTags = (git ls-remote --tags $upstream 2>$null) -replace '.*refs/tags/', ''
        }
        $localTags   = git tag --points-at HEAD
        $unpushedTags = $localTags | Where-Object { $_ -and ($_ -notin $remoteTags) }

        [PSCustomObject]@{
            TagAtHead    = $tagAtHead
            NearestTag   = $nearestTag
            UnpushedTags = $unpushedTags
        }
    }

    # --- Helper: Get commit info for ahead/behind ---
    function Get-CommitInfo($branchStatus) {
        $remoteCommits = @()
        if ($branchStatus.Upstream -and $branchStatus.BehindCount -gt 0) {
            $remoteCommits = git log "HEAD..$($branchStatus.Upstream)" --pretty=format:"%h %s" -n $branchStatus.BehindCount
        }
        $log          = git log --oneline --decorate --graph -n 7
        $unpushed     = @()
        if ($branchStatus.Upstream) {
            $unpushed = git log "$($branchStatus.Upstream)..HEAD" --pretty=format:"%h"
        }
        [PSCustomObject]@{
            RemoteCommits = $remoteCommits
            Log           = $log
            Unpushed      = $unpushed
        }
    }

    # --- Helper: Parse porcelain status into buckets ---
    function Get-FileBuckets($statusLines) {
        $staged   = @()
        $unstaged = @()
        $untracked = @()

        foreach ($line in $statusLines) {
            if ($line -match '^\? (.+)$') {
                $untracked += $matches[1]
            }
            elseif ($line -match '^[12] (\S)(\S) .* (.+)$') {
                $X = $matches[1]
                $Y = $matches[2]
                $file = $matches[3]

                if ($X -ne '.') { $staged += "$X $file" }
                if ($Y -ne '.') { $unstaged += "$Y $file" }
            }
        }
        [PSCustomObject]@{
            Staged     = $staged
            Unstaged   = $unstaged
            Untracked  = $untracked
        }
    }

    # --- Helper: Build a map of file -> {Added, Deleted, IsBinary} from git --numstat output ---
    function Get-NumstatMap {
        param(
            [string]$DiffArgs
        )
        $map = @{}

        # Use tabs as separators; numstat format: added<TAB>deleted<TAB>path
        $lines = & git diff $DiffArgs --numstat 2>$null
        foreach ($l in $lines) {
            if (-not $l) { continue }
            # split into three parts at tabs (handles filenames with spaces)
            $parts = $l -split "`t", 3
            if ($parts.Count -lt 3) { continue }
            $addedRaw = $parts[0]
            $deletedRaw = $parts[1]
            $path = $parts[2]

            $isBinary = $false
            if ($addedRaw -eq '-' -or $deletedRaw -eq '-') {
                $isBinary = $true
                $added = 0
                $deleted = 0
            } else {
                $added = [int]$addedRaw
                $deleted = [int]$deletedRaw
            }

            $map[$path] = [PSCustomObject]@{ Added = $added; Deleted = $deleted; IsBinary = $isBinary }
        }

        return $map
    }

    # Format the +A | -D text for a file given a numstat map
    function Format-ChangeCounts($file, $map) {
        if (-not $map) { return "" }
        if ($map.ContainsKey($file)) {
            $info = $map[$file]
            if ($info.IsBinary) {
                return " (binary)"
            } else {
                return " (+$($info.Added) | -$($info.Deleted))"
            }
        }
        # sometimes the status path and numstat path differ (rename notation). Try a fallback: match by suffix
        foreach ($k in $map.Keys) {
            if ($k -and $file.EndsWith($k)) {
                $info = $map[$k]
                if ($info.IsBinary) { return " (binary)" } else { return " (+$($info.Added) | -$($info.Deleted))" }
            }
        }
        return ""
    }

    if (-not (Test-InGitRepo)) {
        Write-Host " Not a git repository." -ForegroundColor Red
        return
    }

    # 2. Get all status in one go
    $statusRaw = git status --porcelain=v2 --branch
    if (-not $statusRaw) {
        Write-Host " Clean working tree!" -ForegroundColor Green
        return
    }

    # 3. Branch and tag info
    $branchStatus = Get-BranchStatus $statusRaw
    $tagInfo = Get-TagInfo $branchStatus.Upstream

    # 4. Build numstat maps for staged and unstaged changes
    $stagedNumstat = Get-NumstatMap "--cached"
    $unstagedNumstat = Get-NumstatMap ""

    Write-Host ""
    if ($tagInfo.TagAtHead) {
        Write-Host "  On tag:" -NoNewline -ForegroundColor DarkYellow
        Write-Host " $($tagInfo.TagAtHead)" -ForegroundColor Cyan
    } elseif ($tagInfo.NearestTag) {
        Write-Host "  Nearest tag:" -NoNewline -ForegroundColor DarkYellow
        Write-Host " $($tagInfo.NearestTag)" -ForegroundColor DarkCyan
    }
    if ($tagInfo.UnpushedTags) {
        foreach ($t in $tagInfo.UnpushedTags) {
            Write-Host "  Unpushed tag:" -NoNewline -ForegroundColor DarkYellow
            Write-Host " $t" -ForegroundColor Magenta
        }
    }

    # 5. Commits info
    $commitInfo = Get-CommitInfo $branchStatus
    if ($branchStatus.BehindCount -gt 0 -and $branchStatus.Upstream) {
        Write-Host ""
        Write-Host "  Remote: " -NoNewline -ForegroundColor Magenta
        Write-Host "[ $($branchStatus.BehindCount)]" -NoNewline -ForegroundColor DarkMagenta
        Write-Host " | $($branchStatus.Upstream)" -NoNewline -ForegroundColor Green
        Write-Host " | (git pull)" -ForegroundColor DarkGray
        Write-Host " ───────────────────────────────" -ForegroundColor DarkGray
        foreach ($c in $commitInfo.RemoteCommits) {
            Write-Host "   󰇚 $c" -ForegroundColor DarkRed
        }
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "  Remote: " -NoNewline -ForegroundColor Magenta
        Write-Host "[ $($branchStatus.BehindCount)]" -NoNewline -ForegroundColor DarkGray
        Write-Host " | $($branchStatus.Upstream)" -NoNewline -ForegroundColor Green
        Write-Host " | (git fetch)" -ForegroundColor DarkGray
    }

    if ($branchStatus.AheadCount -gt 0) {
        Write-Host "  HEAD:   " -NoNewline -ForegroundColor Magenta
        Write-Host "[ $($branchStatus.AheadCount)]" -NoNewline -ForegroundColor DarkCyan
        Write-Host " | $($branchStatus.Branch)" -NoNewline -ForegroundColor Yellow
        if (($branchStatus.Branch -eq "master") -or ($branchStatus.Branch -eq "main")) { Write-Host " " -NoNewline -ForegroundColor Red}
        Write-Host " | (git push | git reset --soft HEAD~$($branchStatus.AheadCount))" -ForegroundColor DarkGray
        Write-Host " ───────────────────────────────" -ForegroundColor DarkGray
        foreach ($line in $commitInfo.Log) {
            if ($line -match '([0-9a-f]{7,})') {
                $sha = $matches[1]
                if ($commitInfo.Unpushed -contains $sha) {
                    Write-Host "   $($line)" -ForegroundColor Green
                } else {
                    Write-Host "   $($line)" -ForegroundColor DarkGray
                }
            } else {
                Write-Host "   $($line)" -ForegroundColor DarkGray
            }
        }
    } else {
        Write-Host "  HEAD:   " -NoNewline -ForegroundColor Magenta
        Write-Host "[ $($branchStatus.AheadCount)]" -NoNewline -ForegroundColor DarkGray
        Write-Host " | $($branchStatus.Branch)" -NoNewline -ForegroundColor Yellow
        if (($branchStatus.Branch -eq "master") -or ($branchStatus.Branch -eq "main")) { Write-Host " " -ForegroundColor Red}
    }

    Write-Host ""
    Write-Host " ───────────────────────────────"
    Write-Host ""

    # 6. File state buckets
    $buckets = Get-FileBuckets $statusRaw

    if ((-not $buckets.Staged) -and (-not $buckets.Unstaged) -and (-not $buckets.Untracked) -and ($branchStatus.AheadCount -eq 0)) {
        git log --oneline --decorate --graph -n 7
    }

    if ($buckets.Staged) {
        Write-Host "  Staged changes ($($buckets.Staged.Count))" -NoNewline -ForegroundColor Green
        Write-Host " | (gcc | git restore --staged)" -ForegroundColor DarkGray
        foreach ($entry in $buckets.Staged) {
            $parts = $entry.Split(" ",2)
            $code,$file = $parts
            $counts = Format-ChangeCounts $file $stagedNumstat
            switch ($code) {
                'M' { Write-Host "      $file$counts" -ForegroundColor DarkGreen }
                'A' { Write-Host "      $file$counts" -ForegroundColor DarkGreen }
                'D' { Write-Host "      $file$counts" -ForegroundColor DarkGreen }
                'R' { Write-Host "      $file$counts" -ForegroundColor DarkGreen }
                default { Write-Host "     $file$counts" -ForegroundColor DarkGreen }
            }
        }
        Write-Host ""
    }

    if ($buckets.Unstaged) {
        Write-Host "  Unstaged changes ($($buckets.Unstaged.Count))" -NoNewline -ForegroundColor Yellow
        Write-Host " | (ga | git restore)" -ForegroundColor DarkGray
        foreach ($entry in $buckets.Unstaged) {
            $parts = $entry.Split(" ",2)
            $code,$file = $parts
            $counts = Format-ChangeCounts $file $unstagedNumstat
            switch ($code) {
                'M' { Write-Host "      $file$counts" -ForegroundColor DarkYellow }
                'D' { Write-Host "      $file$counts" -ForegroundColor DarkYellow }
                default { Write-Host "     $file$counts" -ForegroundColor DarkYellow }
            }
        }
        Write-Host ""
    }

    if ($buckets.Untracked) {
        Write-Host "  Untracked ($($buckets.Untracked.Count))" -NoNewline -ForegroundColor Magenta
        Write-Host " | (ga)" -ForegroundColor DarkGray
        # For untracked files we can't easily get numstat; mark as (new)
        $buckets.Untracked | ForEach-Object { Write-Host "      $_ (new)" -ForegroundColor DarkMagenta }
        Write-Host ""
    }
}
