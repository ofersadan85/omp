param(
    [string]$RepoRoot = $PSScriptRoot,
    [string]$RawBase = "https://raw.githubusercontent.com/ofersadan85/omp/main"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($PSVersionTable.PSVersion.Major -ge 7) { $PSNativeCommandUseErrorActionPreference = $true }

$repo_root = if ($RepoRoot -and (Test-Path -Path $RepoRoot)) { (Resolve-Path -Path $RepoRoot).Path } else { $PSScriptRoot }
$profile_parent = Split-Path -Path $PROFILE -Parent
$theme_name = "ofersadan.omp.yaml"
$profile_path = Join-Path -Path $repo_root -ChildPath "profile.ps1"
$theme_path = Join-Path -Path $repo_root -ChildPath $theme_name
$winget_path = Join-Path -Path $repo_root -ChildPath "winget.json"

function Write-Step ($message) {
    Write-Host "`n==> $message" -ForegroundColor Cyan
}

function Ensure-Directory ($path) {
    New-Item -ItemType Directory -Force -Path $path | Out-Null
}

function Update-SessionPath {
    $machine_path = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $user_path = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = (@($machine_path, $user_path) | Where-Object { $_ }) -join ';'

    foreach ($extra_path in @(
            (Join-Path -Path $HOME -ChildPath ".cargo\\bin"),
            (Join-Path -Path $HOME -ChildPath ".local\\bin")
        )) {
        if ((Test-Path -Path $extra_path) -and ($env:Path -notlike "*$extra_path*")) {
            $env:Path = "$env:Path;$extra_path"
        }
    }
}

function Resolve-CommandPath ($name, $fallbacks = @()) {
    $command = Get-Command -Name $name -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    foreach ($fallback in $fallbacks) {
        if ($fallback -and (Test-Path -Path $fallback)) {
            return $fallback
        }
    }

    return $null
}

function Install-PowerShellModule ($name) {
    Write-Step "Installing PowerShell module: $name"

    if (-not (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -Force | Out-Null
    }

    $gallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
    if ($gallery -and $gallery.InstallationPolicy -ne 'Trusted') {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    }

    $installed = Get-Module -ListAvailable -Name $name | Sort-Object Version -Descending | Select-Object -First 1
    if ($installed) {
        Write-Host "$name already installed ($($installed.Version))"
        return
    }

    Install-Module -Name $name -Repository PSGallery -Scope CurrentUser -AllowClobber -Force -SkipPublisherCheck -AcceptLicense
}

function Import-WingetPackages ($manifest_path) {
    Write-Step "Importing winget packages"

    $winget = Resolve-CommandPath "winget"
    if (-not $winget) {
        Write-Warning "winget was not found. Skipping package import."
        return
    }

    if (-not (Test-Path -Path $manifest_path)) {
        Write-Warning "winget manifest not found at $manifest_path"
        return
    }

    # Keep the import non-interactive and continue when an optional package is unavailable.
    & $winget import `
        --verbose `
        --accept-package-agreements `
        --accept-source-agreements `
        --disable-interactivity `
        --ignore-unavailable `
        --no-upgrade `
        --import-file $manifest_path
    Update-SessionPath
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

function Install-ProfileFiles {
    Write-Step "Installing profile and theme files"

    Ensure-Directory $profile_parent
    $theme_dest = Join-Path -Path $profile_parent -ChildPath $theme_name

    if ((Test-Path -Path $profile_path) -and (Test-Path -Path $theme_path)) {
        Set-FileLink -Path $PROFILE -Target $profile_path
        Set-FileLink -Path $theme_dest -Target $theme_path
        return
    }

    Invoke-WebRequest -Uri "$RawBase/profile.ps1" -OutFile $PROFILE
    Invoke-WebRequest -Uri "$RawBase/$theme_name" -OutFile $theme_dest
}

function Install-CargoBinstall {
    Write-Step "Installing cargo-binstall"

    $cargo = Resolve-CommandPath "cargo" @(
        (Join-Path -Path $HOME -ChildPath ".cargo\\bin\\cargo.exe"),
        (Join-Path -Path $HOME -ChildPath ".cargo/bin/cargo")
    )

    if (-not $cargo) {
        Write-Warning "cargo was not found. Skipping cargo-binstall."
        return
    }

    $cargo_binstall = Resolve-CommandPath "cargo-binstall" @(
        (Join-Path -Path $HOME -ChildPath ".cargo\\bin\\cargo-binstall.exe"),
        (Join-Path -Path $HOME -ChildPath ".cargo/bin/cargo-binstall")
    )

    if ($cargo_binstall) {
        Write-Host "Updating cargo-binstall"
        & $cargo binstall cargo-binstall --no-confirm
        return
    }

    Write-Host "Installing cargo-binstall"
    & $cargo install cargo-binstall --locked
    Update-SessionPath
}

function Install-UvTool ($uv, $name) {
    $installed = $false

    try {
        $installed = (& $uv tool list) | Select-String -Pattern "^$name\b" -Quiet
    }
    catch {
        Write-Warning "uv tool list failed for ${name}: $($_.Exception.Message)"
    }

    if ($installed) {
        try {
            & $uv tool upgrade $name
            Write-Host "Upgraded uv tool: $name"
            return
        }
        catch {
            Write-Warning "uv tool upgrade failed for ${name}: $($_.Exception.Message)"
        }
    }

    try {
        & $uv tool install $name
        Write-Host "Installed uv tool: $name"
        return
    }
    catch {
        Write-Warning "uv tool install failed for ${name}: $($_.Exception.Message)"
    }

    try {
        & $uv tool uninstall $name
    }
    catch {
        Write-Warning "uv tool uninstall failed for ${name}: $($_.Exception.Message)"
    }

    try {
        & $uv tool install $name
        Write-Host "Reinstalled uv tool: $name"
    }
    catch {
        throw "uv tool install failed for ${name}: $($_.Exception.Message)"
    }
}

function Install-UvTools {
    Write-Step "Installing uv tools"

    $uv = Resolve-CommandPath "uv" @(
        (Join-Path -Path $HOME -ChildPath ".local\\bin\\uv.exe"),
        (Join-Path -Path $HOME -ChildPath ".local/bin/uv")
    )

    if (-not $uv) {
        Write-Warning "uv was not found. Skipping uv tooling."
        return
    }

    $uv_tools = @(
        "ruff",
        "ty" # Astral's type checker
    )

    foreach ($tool in $uv_tools) {
        Install-UvTool -uv $uv -name $tool
    }
}

Install-PowerShellModule posh-git
Install-PowerShellModule DockerCompletion
Install-PowerShellModule DockerComposeCompletion
Import-WingetPackages $winget_path
Install-ProfileFiles
Install-CargoBinstall
Install-UvTools
