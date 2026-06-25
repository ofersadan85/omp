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
        # Write-Host "Creating alias: $from -> $to"
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
        winget import --verbose --no-upgrade --accept-package-agreements --disable-interactivity --import-file $winget_json_path
    }
    else { Write-Host "winget.json file not found at $winget_json_path" }
}

############################################
# Aliases
############################################
function .. { z .. }
function ... { z ..\.. }
function cpwd { $PWD.Path | Set-Clipboard }  # Copy current path to clipboard
function gs { git status }

try_alias g git
try_alias c cargo
try_alias code code-insiders -silent $true
try_alias cat bat
try_alias lzg lazygit

if (try_alias ls lsd) {
    function l {
        param()
        lsd -lA @args
    }
}
