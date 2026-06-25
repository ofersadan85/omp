# ofersadan85/omp

My personal oh-my-posh theme
![example.png](https://github.com/ofersadan85/omp/blob/main/example.png?raw=true)

## Install oh-my-posh

```powershell
winget install JanDeDobbeleer.OhMyPosh -s winget
```

## Install profile, theme, packages and tools

```powershell
git clone https://github.com/ofersadan85/omp.git
Set-Location .\omp
.\install.ps1
```

The installer will:
- install the required PowerShell modules
- import packages from `winget.json`
- link `profile.ps1` and `ofersadan.omp.yaml` into your PowerShell profile directory
- install `cargo-binstall`, `uv`, and the `ruff` / `ty` uv tools

### Note

You probably need to close and reload the terminal
