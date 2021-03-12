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
    Use-Zig.ps1 master -Update

    This command updates master to the latest available nightly build.
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
$UserUpdateRequest = $args[1] -eq "-Update"

if (-not (Test-Path $ZIGS_PATH)) {
    New-Item -ItemType Directory $ZIGS_PATH | Out-Null
}

$InstallPath = "$ZIGS_PATH\$ARCH"
if (-not (Test-Path $InstallPath)) {
    New-Item -ItemType Directory $InstallPath | Out-Null
}

$VersionExists = Test-Path "$InstallPath\$UserVersion"
$IsMasterUpdate = $VersionExists -and $UserUpdateRequest -and ($UserVersion -eq "master")
$DoInstall = (-not $VersionExists) -or ($IsMasterUpdate)

if ($DoInstall) {

    $Response = Invoke-WebRequest -Uri $ZIG_VERSIONS_URL
    if ($Response.StatusCode -ne 200) {
        Write-Host "Error: failed to get releases from: $ZIG_VERSION_URL"
        exit
    }

    $Zigs = $Response.Content | ConvertFrom-Json
    if (-not $Zigs.$UserVersion) {
        Write-Host "Error: Zig version $UserVersion not available"
        exit
    }

    # Define absolute version number
    if ($IsMasterUpdate) {
        $AbsoluteVersion = $Zigs.master.version
    }
    else {
        $AbsoluteVersion = $UserVersion
    }

    # If master is already up-to-date we exit here
    if ($IsMasterUpdate) {
        $MasterVersionExists = Test-Path "$InstallPath\$AbsoluteVersion"
        if ($MasterVersionExists) {
            Write-Host "Version 'master' is already up-to-date"
            $SkipDownload = $TRUE
        }
        else {
            $SkipDownload = $FALSE
        }
    }

    if (-not $SkipDownload) {
        $DownloadUrl = $Zigs.$UserVersion."$ARCH-$PLATFORM".tarball
        if (-not $DownloadUrl) {
            "Error: Zig package not found for $ARCH-$PLATFORM and version $userVersion"
            exit
        }

        $TempPath = "$ZIGS_PATH\temp"
        if (Test-Path $TempPath) {
            # The temp folder may exist after an unsuccessfull previous run.
            # Let's clean up.
            Remove-Item -Recurse -Force $TempPath
        }
        New-Item -ItemType Directory $TempPath | Out-Null

        Write-Host "Downloading Zig ($AbsoluteVersion) from $DownloadUrl..."
        $Response = Invoke-WebRequest -Uri $DownloadUrl -OutFile "$TempPath\zig.zip" -PassThru
        if ($Response.StatusCode -ne 200) {
            Write-Host "Error: failed to download package from $DownloadUrl"
            exit
        }

        Write-Host "Installing Zig ($AbsoluteVersion) to $InstallPath"
        Expand-Archive "$TempPath\zig.zip" -DestinationPath $InstallPath

        Remove-Item -Recurse -Force $TempPath

        $ExtractedFolderName = "zig-$PLATFORM-$ARCH-$AbsoluteVersion"
        Rename-Item $InstallPath\$ExtractedFolderName $InstallPath\$AbsoluteVersion

        if (($UserVersion -eq "master") -or $IsMasterUpdate) {
            $MasterJunctionPath = "$InstallPath\master"
            if ($IsMasterUpdate) {
                $CurrentMaster = (Get-Item $MasterJunctionPath).Target
                # This if is required for backwards compatibility with the previous
                # version, where 'master' was a regular folder.
                if ($CurrentMaster) {
                    Write-Host "Removing previous version of master"
                    Remove-Item -Force -Recurse $CurrentMaster
                }
                else {
                    # This is the case of the old plain 'master' folder
                    Remove-Item -Force -Recurse $MasterJunctionPath
                }
            }
            if (Test-Path $MasterJunctionPath) {
                Remove-Item $MasterJunctionPath
            }
            New-Item -ItemType Junction -Path $MasterJunctionPath -Target "$InstallPath\$AbsoluteVersion" | Out-Null
        }
    }
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
