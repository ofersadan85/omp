# Install modules
Install-Module posh-git
Install-Module Terminal-Icons
Install-Module DockerCompletion
Install-Module DockerComposeCompletion

# Make parent folder
$profile_parent = (get-item $PROFILE).Directory.FullName
New-Item -ItemType Directory -Force -Path $profile_parent

# Download theme
$theme_src = https://raw.githubusercontent.com/ofersadan85/oh-my-posh-theme/main/ofersadan.omp.json
$theme_dest = Join-Path -Path $profile_parent -ChildPath "ofersadan.omp.json"
Invoke-WebRequest $theme_src -OutFile $theme_dest

# Download profile
$profile_src = https://raw.githubusercontent.com/ofersadan85/oh-my-posh-theme/main/profile.ps1
Invoke-WebRequest $theme_src -OutFile $PROFILE
