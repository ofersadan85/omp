############################################
# Debug / Trace / Timing setup
############################################
$DEBUG_MODE = $false; $SHOW_TIMING = $false; $START_TIME = Get-Date
if ($DEBUG_MODE) { Set-PSDebug -Trace 1 -Strict; $SHOW_TIMING = $true } else { Set-PSDebug -Off }
function WithTiming {
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )
    if ($SHOW_TIMING) {
        Write-Host "$((Measure-Command { & $ScriptBlock }).TotalMilliseconds) ms"
        Write-Host "Execution time: $(((Get-Date) - $START_TIME).TotalMilliseconds) ms"
    }
    else { & $ScriptBlock }
}

############################################
# PSReadLine
############################################
function OnViModeChange {
    if ($args[0] -eq 'Command') { Write-Host -NoNewLine "`e[1 q" } # blinking block
    else { Write-Host -NoNewLine "`e[5 q" } # blinking line
}
Set-PSReadLineOption `
    -EditMode Vi `
    -ViModeIndicator Script -ViModeChangeHandler $Function:OnViModeChange `
    -MaximumHistoryCount 100kb `
    -PredictionSource HistoryAndPlugin

############################################
# Utility Functions
############################################
function which ($command) {
    Get-Command -Name $command -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

function gig {
    # Create .gitignore file using Toptal's API
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$list
    )
    $params = ($list | ForEach-Object { [uri]::EscapeDataString($_) }) -join ","
    Invoke-WebRequest -Uri "https://www.toptal.com/developers/gitignore/api/$params" | Select-Object -ExpandProperty content | Out-File -FilePath $(Join-Path -path $pwd -ChildPath ".gitignore") -Encoding ascii
}

function reload_profile { . $PROFILE }
function mkcd ($path) { New-Item -ItemType Directory -Force -Path $path | Out-Null; z $path }
function touch ($path) { if (Test-Path -Path $path) { (Get-Item -Path $path).LastWriteTime = Get-Date } else { New-Item -ItemType File -Path $path | Out-Null } }
function ff ($name) { Get-ChildItem -Path . -Recurse -File -Filter "*$name*" }
function croot { Set-Location $PSScriptRoot }
function path { $env:Path -split ';' }
function gadd { git add @args }
function gcm { git commit @args }
function gca { git commit --amend @args }
function gco { git checkout @args }
function gd { git diff @args }
function glog { git log --oneline --decorate --graph @args }
function gpull { git pull @args }
function gpush { git push @args }
function gcleanmerged { git branch --merged | ForEach-Object { $_.ToString().Trim() } | Where-Object { $_ -and $_ -notin @('main', 'master') -and $_ -notmatch "^\*" } | ForEach-Object { git branch -d $_ } }
function dps { docker ps @args }
function dcu { docker compose up @args }
function dcd { docker compose down @args }

############################################
# Completions & Initializations
############################################
WithTiming { Import-Module posh-git }
WithTiming { Import-Module DockerCompletion }
WithTiming { Import-Module DockerComposeCompletion }
WithTiming {
    $omp_config = Join-Path -Path $PSScriptRoot -ChildPath "ofersadan.omp.yaml"
    oh-my-posh init pwsh --config $omp_config | Invoke-Expression
}
WithTiming { if (which zoxide) { Invoke-Expression (& { (zoxide init powershell | Out-String) }) } }
WithTiming { if (which rustup) { Invoke-Expression (& { (rustup completions powershell | Out-String) }) } }

function try_alias {
    param (
        [string]$from,
        [string]$to,
        [bool]$override = $false,
        [bool]$silent = $false
    )
    if ((which $from) -and (which $to) -and $override) {
        Write-Host "Both commands exist: $from and $to. Not creating alias."
        return $false
    }
    elseif (which $to) {
        Set-Alias -Name $from -Value $to -Scope Global -Option AllScope -Force
        return $true
    }
    elseif (!$silent) {
        Write-Host "Could not alias: $from -> $to"
        return $false
    }
}

function winget_do_installs {
    $winget_json_path = Join-Path -Path $PSScriptRoot -ChildPath "winget.json"
    if (Test-Path -Path $winget_json_path) {
        winget import --accept-package-agreements --accept-source-agreements --disable-interactivity --ignore-unavailable --no-upgrade --import-file $winget_json_path
    }
    else { Write-Host "winget.json file not found at $winget_json_path" }
}

############################################
# Aliases
############################################
function .. { z .. }
function ... { z ..\.. }
function cpwd { $PWD.Path | Set-Clipboard }
function gs { git status }
function grep { rg @args }

try_alias g git
try_alias c cargo
try_alias code code-insiders -silent $true
try_alias cat bat
try_alias lg lazygit
try_alias lzg lazygit
try_alias vi nvim
try_alias vim nvim
try_alias py python

if (try_alias ls lsd) {
    function l {
        param()
        lsd -lA @args
    }

    function la {
        param()
        lsd -A @args
    }

    function ll {
        param()
        lsd -la @args
    }

    function lt {
        param()
        lsd --tree @args
    }
}
