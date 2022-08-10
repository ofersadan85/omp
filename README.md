# oh-my-posh-theme
My personal oh-my-posh theme
![example.png](https://github.com/ofersadan85/oh-my-posh-theme/blob/main/example.png?raw=true)

## Install oh-my-posh
    winget install JanDeDobbeleer.OhMyPosh -s winget
    
## Download this theme with powershell
    Invoke-WebRequest https://raw.githubusercontent.com/ofersadan85/oh-my-posh-theme/main/ofersadan.omp.json -OutFile (Join-Path -Path (get-item $PROFILE).Directory.FullName -ChildPath "ofersadan.omp.json")
    
## Enable this theme in your $PROFILE
    echo 'oh-my-posh init pwsh --config (Join-Path -Path (get-item $PROFILE).Directory.FullName -ChildPath "ofersadan.omp.json") | Invoke-Expression' >> $PROFILE
    
### Note
You probably need to close and reload the terminal
