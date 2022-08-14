Import-Module posh-git
Import-Module Terminal-Icons
Import-Module DockerCompletion
Import-Module DockerComposeCompletion

$omp_config = Join-Path -Path (get-item $PROFILE).Directory.FullName -ChildPath "ofersadan.omp.json"
oh-my-posh init pwsh --config $omp_config | Invoke-Expression

# PSReadLine
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -PredictionSource History

# Utilities
function which ($command) {
  Get-Command -Name $command -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}
