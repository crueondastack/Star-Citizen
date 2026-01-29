# Check for Administrator privileges (Recommended for killing processes)
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script works best when run as Administrator to ensure processes are stopped correctly."
}

# --- CONFIGURATION ---
$procNameGame = "StarCitizen_Launcher" # .exe extension is not used in Stop-Process
$procNameLauncher = "RSI Launcher"
$shaderParentPath = "$env:LOCALAPPDATA\Star Citizen" # Resolves to %localappdata%\Star Citizen

# --- STEP 1: CAPTURE LAUNCHER PATH ---
# We try to find where the launcher is installed before we kill it, so we can restart it later.
$launcherPath = $null
$runningLauncher = Get-Process -Name $procNameLauncher -ErrorAction SilentlyContinue | Select-Object -First 1

if ($runningLauncher) {
    $launcherPath = $runningLauncher.Path
    Write-Host "Found RSI Launcher at: $launcherPath" -ForegroundColor Gray
} else {
    # Fallback: Check standard install location if process isn't currently running
    $defaultPath = "C:\Program Files\Roberts Space Industries\RSI Launcher\RSI Launcher.exe"
    if (Test-Path $defaultPath) {
        $launcherPath = $defaultPath
    }
}

# --- STEP 2: END PROCESSES ---
Write-Host "Stopping Star Citizen and Launcher processes..." -ForegroundColor Cyan

# Stop Star Citizen
Get-Process -Name $procNameGame -ErrorAction SilentlyContinue | Stop-Process -Force
# Stop RSI Launcher
Get-Process -Name $procNameLauncher -ErrorAction SilentlyContinue | Stop-Process -Force

# Give the system a moment to release file locks
Start-Sleep -Seconds 2

# --- STEP 3: DELETE SHADER FOLDERS ---
Write-Host "Clearing folders in: $shaderParentPath" -ForegroundColor Cyan

if (Test-Path -Path $shaderParentPath) {
    # Get all sub-folders (Directory) inside the path and remove them
    $folders = Get-ChildItem -Path $shaderParentPath -Directory
    
    if ($folders) {
        foreach ($folder in $folders) {
            try {
        # ErrorAction Stop ensures that if an error occurs, we jump immediately to the Catch block
                Remove-Item -Path $folder.FullName -Recurse -Force -ErrorAction Stop
        
        # This line will ONLY run if the deletion above was successful
                Write-Host "Deleted: $($folder.Name)" -ForegroundColor DarkGray
            }
            catch {
        # This block runs if the deletion failed (e.g., file in use, permission denied)
                    Write-Warning "Failed to delete: $($folder.Name). Reason: $($_.Exception.Message)"
                }
            }
        Write-Host "Shader cache cleanup complete." -ForegroundColor Green
    } else {
        Write-Host "No subfolders found to delete." -ForegroundColor Yellow
    }
} else {
    Write-Warning "Path not found: $shaderParentPath"
}

# --- STEP 4: RESTART LAUNCHER ---
if ($launcherPath -and (Test-Path $launcherPath)) {
    Write-Host "Restarting RSI Launcher..." -ForegroundColor Cyan
    Start-Process -FilePath $launcherPath
} else {
    Write-Warning "Could not determine RSI Launcher path. Please start it manually."

}
