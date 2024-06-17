# Install modules
Install-Module -Confirm -AcceptLicense posh-git
Install-Module -Confirm -AcceptLicense DockerCompletion
Install-Module -Confirm -AcceptLicense DockerComposeCompletion

# Make parent folder
$profile_parent = (get-item $PROFILE).Directory.FullName
New-Item -ItemType Directory -Force -Path $profile_parent

# Download theme
$theme_src = "https://raw.githubusercontent.com/ofersadan85/oh-my-posh-theme/main/ofersadan.omp.yaml"
$theme_dest = Join-Path -Path $profile_parent -ChildPath "ofersadan.omp.yaml"
Invoke-WebRequest $theme_src -OutFile $theme_dest

# Download profile
$profile_src = "https://raw.githubusercontent.com/ofersadan85/oh-my-posh-theme/main/profile.ps1"
Invoke-WebRequest $profile_src -OutFile $PROFILE
