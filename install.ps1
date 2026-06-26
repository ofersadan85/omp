$repo_url = "https://github.com/ofersadan85/omp.git"
$repo_raw_base = "https://raw.githubusercontent.com/ofersadan85/omp/main"

function Ensure-Directory ($path) { New-Item -ItemType Directory -Force -Path $path | Out-Null }

function Update-SessionPath {
    $machine_path = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $user_path = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = (@($machine_path, $user_path) | Where-Object { $_ }) -join ';'

    foreach ($extra_path in @(
            (Join-Path -Path $HOME -ChildPath ".cargo\bin"),
            (Join-Path -Path $HOME -ChildPath ".local\bin")
        )) {
        if ((Test-Path -Path $extra_path) -and ($env:Path -notlike "*$extra_path*")) {
            $env:Path = "$env:Path;$extra_path"
        }
    }
}


function Set-FileLink ($path, $target) {
    $resolved_target = (Resolve-Path -LiteralPath $target).Path
    Ensure-Directory (Split-Path -Path $path -Parent)

    $existing = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    if ($existing) {
        $existing_target = $existing.Target
        if ($existing_target -is [array]) { $existing_target = $existing_target[0] }

        if ($existing_target) {
            try { $existing_target = (Resolve-Path -LiteralPath $existing_target).Path }
            catch { }
        }

        if ($existing_target -eq $resolved_target) {
            Write-Host "$path already points to $resolved_target"
            return
        }

        Remove-Item -LiteralPath $path -Force
    }

    New-Item -ItemType SymbolicLink -Path $path -Target $resolved_target -Force | Out-Null
    Write-Host "$path -> $resolved_target"
}

function Setup-Modules {
    Write-Host "Installing required modules..."
    Install-Module -Confirm -AcceptLicense DockerCompletion
    Install-Module -Confirm -AcceptLicense DockerComposeCompletion
}

function Setup-Winget {
    Write-Host "Setting up winget packages..."
    $winget_src = Join-Path -Path $PSScriptRoot -ChildPath "winget.json"
    if (Test-Path -Path $winget_src) {
        $winget_tmp = $winget_src
    }
    else {
        $winget_tmp = Join-Path -Path $env:TEMP -ChildPath "winget.json"
        Invoke-WebRequest -Uri "$repo_raw_base/winget.json" -OutFile $winget_tmp
    }
    winget import `
        --verbose `
        --accept-package-agreements `
        --accept-source-agreements `
        --disable-interactivity `
        --ignore-unavailable `
        --no-upgrade `
        --import-file $winget_tmp
    Update-SessionPath
}

function Setup-RustBuildTools {
    Write-Host "Setting up native Rust build tools..."
    winget install `
        --id Microsoft.VisualStudio.2022.BuildTools `
        --exact `
        --accept-package-agreements `
        --accept-source-agreements `
        --silent `
        --override "--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --passive --norestart"
}

function Setup-Profile {
    $profile_parent = Split-Path -Path $PROFILE -Parent
    $theme_name = "ofersadan.omp.yaml"
    $profile_path = Join-Path -Path $PSScriptRoot -ChildPath "profile.ps1"
    $theme_path = Join-Path -Path $PSScriptRoot -ChildPath $theme_name

    Ensure-Directory $profile_parent

    if ((Test-Path -Path (Join-Path -Path $profile_parent -ChildPath ".git"))) {
        Write-Host "Profile directory is already a git repository. Pulling latest changes..."
        git -C $profile_parent pull
        return
    }

    $theme_dest = Join-Path -Path $profile_parent -ChildPath $theme_name
    if ((Test-Path -Path $profile_path) -and (Test-Path -Path $theme_path)) {
        Set-FileLink -Path $PROFILE -Target $profile_path
        Set-FileLink -Path $theme_dest -Target $theme_path
        return
    }

    Invoke-WebRequest -Uri "$repo_raw_base/profile.ps1" -OutFile $PROFILE
    Invoke-WebRequest -Uri "$repo_raw_base/$theme_name" -OutFile $theme_dest
}

function Setup-ExtraPackages {
    Write-Host "Setting up cargo packages..."
    # See https://github.com/cargo-bins/cargo-binstall#windows
    $binstall_url = "https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.ps1"
    Set-ExecutionPolicy Unrestricted -Scope Process; Invoke-Expression (Invoke-WebRequest $binstall_url).Content
    cargo binstall --no-confirm `
        bat `
        bottom `
        cargo-binstall `
        cargo-expand `
        cargo-generate `
        cargo-update `
        du-dust `
        fd-find `
        hexyl `
        just `
        lsd `
        prek `
        ripgrep `
        tealdeer `
        tree-sitter-cli `
        uv `
        zoxide
    cargo install-update cargo-binstall --force  # Bug fix: cargo-binstall contains removed executables (cargo-binstall)
    
    ##############################################
    # Extra UV tools
    ##############################################
    Update-SessionPath
    uv tool install --upgrade ruff
    uv tool install --upgrade ty
}

#############################################
# Main
#############################################
Setup-Modules
Setup-Winget  # Must include git for the next step to work
Setup-RustBuildTools
Setup-Profile
Setup-ExtraPackages
