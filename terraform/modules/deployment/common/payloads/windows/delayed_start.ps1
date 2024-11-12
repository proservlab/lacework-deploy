# TEMPLATE INPUTS
# script_name: name of the script, which will be used for the log file (e.g. /tmp/<script_name>.log)
# log_rotation_count: total number of log files to keep
# powershell_pre_tasks: shell commands to execute before install
# choco_packages: a list of apt packages to install
# powershell_post_tasks: powershell commands to execute after install
# script_delay_secs: total number of seconds to wait before starting the next stage
# next_stage_powershell_payload: powershell commands to execute after delay

# Configurable Parameters
$scriptName = "${config["script_name"]}"
$logRotationCount = ${config["log_rotation_count"]}
$scriptDelaySecs = ${config["script_delay_secs"]}  # Set desired delay here
$tempDir = "$env:TEMP"  # Use the TEMP directory
$logFile = "$tempDir\$scriptName.log"
$lockFile = "$tempDir\lacework_deploy_$scriptName.lock"
$gzipFilePath = "$tempDir\$scriptName.ps1.gz"  # Path for gzipped script
$preTasks = @(${config["powershell_pre_tasks"]})  # e.g. "Write-Output 'Running pre-task 1'", "Write-Output 'Running pre-task 2'"
$postTasks = @(${config["post_tasks"]})  # e.g "Write-Output 'Running post-task 1'", "Write-Output 'Running post-task 2'"
$packages = @(${config["choco_packages"]})  # e.g. "git", "curl"

function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    "$timestamp $message" | Out-File -Append -FilePath $logFile
}

# Create Lock File if Not Exists
if (Test-Path $lockFile) {
    Write-Log "Another instance is already running. Exiting..."
    exit 1
} else {
    New-Item -Path $lockFile -ItemType File | Out-Null
}

# Cleanup Lock File on Exit
function Cleanup {
    Remove-Item -Path $lockFile -ErrorAction Ignore
}
trap { Cleanup } EXIT

# Check for Chocolatey Installation
function Install-ChocolateyIfNeeded {
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Log "Chocolatey not found. Installing..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    } else {
        Write-Log "Chocolatey is already installed."
    }
}

# Check if Chocolatey or msiexec.exe is Running
function Check-ChocolateyInUse {
    return (Get-Process | Where-Object { $_.Name -match "choco|msiexec" }) -ne $null
}

# Base64-Encoded and Gzipped Script (Simulated Delivery)
# Example gzip and base64 encoding a script: `gzip script.ps1 | base64`
function Deliver-ScriptToTemp {
    param (
        [string]$encodedGzip
    )
    # Decode base64, then decompress
    [System.IO.File]::WriteAllBytes($gzipFilePath, [System.Convert]::FromBase64String($encodedGzip))
    $decompressedScript = "$tempDir\$scriptName.ps1"
    # Decompress gzip
    $gzipStream = [System.IO.Compression.GzipStream]::new([System.IO.File]::OpenRead($gzipFilePath), [System.IO.Compression.CompressionMode]::Decompress)
    $fileStream = [System.IO.File]::Create($decompressedScript)
    $gzipStream.CopyTo($fileStream)
    $gzipStream.Close()
    $fileStream.Close()
    Write-Log "Script delivered to $decompressedScript"
}

# Execute Pre-Tasks and Post-Tasks
function Run-Tasks {
    param (
        [array]$tasks,
        [string]$taskType
    )
    foreach ($task in $tasks) {
        Write-Log "Executing $taskType task: $task"
        Invoke-Expression $task
    }
}

Install-ChocolateyIfNeeded

# Retry Mechanism if Chocolatey is Busy
$retryAttempts = 5
$attempt = 0
while (Check-ChocolateyInUse -and $attempt -lt $retryAttempts) {
    Write-Log "Chocolatey or an install is in use. Retrying in 30 seconds..."
    Start-Sleep -Seconds 30
    $attempt++
}

if ($attempt -ge $retryAttempts) {
    Write-Log "Installation is still in use after multiple attempts. Exiting..."
    exit 1
}

# Log Rotation
for ($i = $logRotationCount - 1; $i -ge 1; $i--) {
    if (Test-Path "$logFile.$i") {
        Rename-Item "$logFile.$i" "$logFile.($i + 1)" -ErrorAction Ignore
    }
}
if (Test-Path $logFile) {
    Rename-Item $logFile "$logFile.1" -ErrorAction Ignore
}

# Randomized Delay
$randWait = Get-Random -Minimum 30 -Maximum 300
Write-Log "Waiting $randWait seconds before starting..."
Start-Sleep -Seconds $randWait

# Replace with the actual base64-encoded gzipped content of your script
$encodedGzipScript = "<base64-gzipped-script-content-here>"
Deliver-ScriptToTemp -encodedGzip $encodedGzipScript

# Execute Pre-tasks
Write-Log "Starting pre-tasks..."
Run-Tasks -tasks $preTasks -taskType "pre"

# Install Chocolatey Packages
Write-Log "Starting package installation..."
foreach ($package in $packages) {
    $installCommand = "choco install $package -y"
    Write-Log "Installing package: $package"
    Invoke-Expression $installCommand
}
Write-Log "Package installation complete."

# Script Delay
Write-Log "Starting delay of $scriptDelaySecs seconds..."
Start-Sleep -Seconds $scriptDelaySecs
Write-Log "Delay complete."

Write-Log "Starting next stage after $scriptDelaySecs seconds..."
Write-Log "Starting execution of next stage payload..."
${config["next_stage_powershell_payload"]}
log "done next stage payload execution."

# Launch Script in Background
Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File $tempDir\$scriptName.ps1" -NoNewWindow
Write-Log "Script launched in background."

# Execute Post-Tasks
Write-Log "Starting post-tasks..."
Run-Tasks -tasks $postTasks -taskType "post"

Cleanup
Write-Log "Done"
