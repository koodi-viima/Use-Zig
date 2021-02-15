<#
.SYNOPSIS
    Install and switch between different Zig compiler versions.
.EXAMPLE
    Use-Zig.ps1 0.7.1

    This command installs Zig version 0.7.1.
.EXAMPLE
    Use-Zig.ps1 master

    This command installs the current master of Zig.
.EXAMPLE
    Use-Zig.ps1 master -Install

    This command re-installs (updates) master to the latest available build.
#>

# Change to i386 if you want to use the 32-bit versions instead, but note that
# master is only available in 64-bit version.
$ARCH = "x86_64"

# In theory this script could work in Powershell for Linux and macOS as well...
$PLATFORM = "windows"

# Modify if you want the Zigs to be installed somewhere else than the
# Appdata\Local folder of the current user.
$ZIGS_PATH = "$env:USERPROFILE\AppData\Local\Zigs"

# The URL used to fetch the currently available Zig versions.
$ZIG_VERSIONS_URL = "https://ziglang.org/download/index.json"

$UserVersion = $args[0]
$ForceInstall = $args[1] -eq "-Install"

if (-not (Test-Path $ZIGS_PATH)) {
    New-Item -ItemType Directory $ZIGS_PATH | Out-Null
}

$InstallPath = "$ZIGS_PATH\$ARCH"
if (-not (Test-Path $InstallPath)) {
    New-Item -ItemType Directory $InstallPath | Out-Null
}

$VersionExists = Test-Path "$InstallPath\$UserVersion"
$ShouldInstall = (-not $VersionExists) -or ($VersionExists -and $ForceInstall)

if ($ShouldInstall) {

    $Response = Invoke-WebRequest -Uri $ZIG_VERSIONS_URL
    if ($Response.StatusCode -ne 200) {
        Write-Host "Error: failed to get releases from: $ZIG_VERSION_URL"
        break
    }

    $Zigs = $Response.Content | ConvertFrom-Json
    if (-not $Zigs.$UserVersion) {
        Write-Host "Error: Zig version $UserVersion not available"
        break
    }

    $DownloadUrl = $Zigs.$UserVersion."$ARCH-$PLATFORM".tarball
    if (-not $DownloadUrl) {
        "Error: Zig package not found for $ARCH-$PLATFORM and version $userVersion"
        break
    }

    $TempPath = "$ZIGS_PATH\temp"
    if (Test-Path $TempPath) {
        # The temp folder may exist after an unsuccessfull previous run.
        # Let's clean up.
        Remove-Item -Recurse -Force $TempPath
    }
    New-Item -ItemType Directory $TempPath | Out-Null

    Write-Host "Downloading Zig ($UserVersion) from $DownloadUrl..."
    $Response = Invoke-WebRequest -Uri $DownloadUrl -OutFile "$TempPath\zig.zip" -PassThru
    if ($Response.StatusCode -ne 200) {
        Write-Host "Error: failed to download package from $DownloadUrl"
        break
    }

    if ($VersionExists -and $ForceInstall) {
        Write-Host "Removing previous installation of version $UserVersion"
        Remove-Item -Force -Recurse "$InstallPath\$UserVersion"
    }

    Write-Host "Installing Zig ($UserVersion) to $InstallPath"
    Expand-Archive "$TempPath\zig.zip" -DestinationPath $InstallPath

    Remove-Item -Recurse -Force $TempPath

    # We need the absolute version number to determine the name of the
    # extracted folder, containing the Zig exe. This is simple for
    # snapshot versions (like 0.7.1), but the master version is different, bc
    # it actually has a detailed version number, like 0.8.0-dev.1127+6a5a6386c,
    # pointing to the latest nightly build. Therefore we need to parse that
    # version from the downloaded JSON file and use it.
    if ($UserVersion -eq "master") {
        $AbsoluteVersion = $zigs.master.version
    }
    else {
        $AbsoluteVersion = $UserVersion
    }
    $ExtractedFolderName = "zig-$PLATFORM-$ARCH-$AbsoluteVersion"

    Rename-Item $InstallPath\$ExtractedFolderName $InstallPath\$UserVersion

    $Success = $TRUE
}
else {
    $Success = $TRUE
}

if ($Success) {
    $JunctionPath = "$ZIGS_PATH\current"
    if (Test-Path $JunctionPath) {
        Remove-Item $JunctionPath
    }
    New-Item -ItemType Junction -Path $JunctionPath -Target "$InstallPath\$UserVersion" | Out-Null

    if (-not $env:Path.Contains($JunctionPath)) {
        $env:Path += ";$JunctionPath"
    }
}
