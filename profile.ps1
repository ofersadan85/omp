Import-Module posh-git
Import-Module DockerCompletion
Import-Module DockerComposeCompletion

$omp_config = Join-Path -Path (get-item $PROFILE).Directory.FullName -ChildPath "ofersadan.omp.yaml"
oh-my-posh init pwsh --config $omp_config | Invoke-Expression
$env:POSH_GIT_ENABLED = $true

# PSReadLine
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -PredictionSource History

# Utilities
function which ($command) {
    Get-Command -Name $command -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

function gig {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$list
    )
    $params = ($list | ForEach-Object { [uri]::EscapeDataString($_) }) -join ","
    Invoke-WebRequest -Uri "https://www.toptal.com/developers/gitignore/api/$params" | Select-Object -ExpandProperty content | Out-File -FilePath $(Join-Path -path $pwd -ChildPath ".gitignore") -Encoding ascii
}

# Zoxide
$HAS_ZOXIDE = (Test-Path -Path (Get-Command zoxide -ErrorAction SilentlyContinue).Source)
if ($HAS_ZOXIDE) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

function codez {
    # Example usage: codez myproject
    param (
        [string]$projectName
    )
    $projectFolder = zoxide query -i $projectName
    if ($null -eq $projectFolder -or (!(Test-Path -Path $projectFolder))) {
        Write-Host "Project folder not found."
        return
    }
    code $projectFolder
    z $projectFolder
}

function lsz {
    param (
        [string]$path = $pwd
    )
    if ($path -eq $pwd) {
        lsd -l
    }
    else {
        $target = (zi $path)
        lsd -l $target 
    }
}

function try_alias {
    param (
        [string]$from,
        [string]$to
    )
    if (Get-Command $to -ErrorAction SilentlyContinue) {
        # Write-Host "Creating alias: $from -> $to"
        Set-Alias -Name $from -Value $to -Scope Global -Option AllScope -Force
    } else {
        Write-Host "Command not found: $to"
        Write-Host "Would you like to try searching it in Winget? (y/n)"
        $answer = Read-Host
        if ($answer -eq "y") {
            winget search --disable-interactivity --command $to
        }
    }
}

# Aliases
try_alias code code-insiders
try_alias ls lsd
try_alias cat bat
