param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("plan", "apply", "destroy")]
    [string]$action,
    [Parameter(Mandatory=$true)]
    [string]$workspace
)

# check for required files
# Check for the executability of aws.exe, terraform.exe, git.exe
$requiredCommands = @("aws", "terraform", "git")

foreach ($cmd in $requiredCommands) {
    try {
        Get-Command $cmd -ErrorAction Stop
    }
    catch {
        Write-Error "Required command not found or not executable: $cmd"
        exit 1
    }
}

# Check for the existence of .lacework.toml
$laceworkConfigPath = "$env:USERPROFILE\.lacework.toml"
if (-not (Test-Path $laceworkConfigPath)) {
    Write-Error "Required file not found: $laceworkConfigPath"
    exit 1
}

# Continue with the rest of the script if all checks pass
Write-Output "All required binaries and files are available."

# Continue with the rest of the script if all checks pass
Write-Output "All required files and binaries are available."

# echo the scneario/workspace we'll use for this 
write-output "Executing scenario: $workspace"

# Split the string by hyphen and take the first part
$csp = ($workspace -split '-')[0]


if ($csp -eq "azure"){
    # azure symlink fix
    $targetPath = "azure/env_vars"
    $sourceDir = "env_vars"
    if (Test-Path -Path $targetPath -PathType Leaf) {
        # It's a file, which might be a broken symlink, so replace it with the source directory
        Remove-Item -Path $targetPath -Force
        Copy-Item -Path $sourceDir -Destination $targetPath -Recurse -Force
    } else {
        Write-Host "The target is not a file, no action taken."
    }

    $targetPath = "azure/modules"
    $sourceDir = "modules"
    if (Test-Path -Path $targetPath -PathType Leaf) {
        # It's a file, which might be a broken symlink, so replace it with the source directory
        Remove-Item -Path $targetPath -Force
        Copy-Item -Path $sourceDir -Destination $targetPath -Recurse -Force
    } else {
        Write-Host "The target is not a file, no action taken."
    }

    $targetPath = "azure/scenarios"
    $sourceDir = "scenarios"
    if (Test-Path -Path $targetPath -PathType Leaf) {
        # It's a file, which might be a broken symlink, so replace it with the source directory
        Remove-Item -Path $targetPath -Force
        Copy-Item -Path $sourceDir -Destination $targetPath -Recurse -Force
    } else {
        Write-Host "The target is not a file, no action taken."
    }
} elseif ($csp -eq "gcp") {
    # gcp symlink fix
    $targetPath = "gcp/env_vars"
    $sourceDir = "env_vars"
    if (Test-Path -Path $targetPath -PathType Leaf) {
        # It's a file, which might be a broken symlink, so replace it with the source directory
        Remove-Item -Path $targetPath -Force
        Copy-Item -Path $sourceDir -Destination $targetPath -Recurse -Force
    } else {
        Write-Host "The target is not a file, no action taken."
    }

    $targetPath = "gcp/modules"
    $sourceDir = "modules"
    if (Test-Path -Path $targetPath -PathType Leaf) {
        # It's a file, which might be a broken symlink, so replace it with the source directory
        Remove-Item -Path $targetPath -Force
        Copy-Item -Path $sourceDir -Destination $targetPath -Recurse -Force
    } else {
        Write-Host "The target is not a file, no action taken."
    }

    $targetPath = "gcp/scenarios"
    $sourceDir = "scenarios"
    if (Test-Path -Path $targetPath -PathType Leaf) {
        # It's a file, which might be a broken symlink, so replace it with the source directory
        Remove-Item -Path $targetPath -Force
        Copy-Item -Path $sourceDir -Destination $targetPath -Recurse -Force
    } else {
        Write-Host "The target is not a file, no action taken."
    }
} elseif ($csp -eq "aws") {
    # aws symlink fix
    $targetPath = "aws/env_vars"
    $sourceDir = "env_vars"
    if (Test-Path -Path $targetPath -PathType Leaf) {
        # It's a file, which might be a broken symlink, so replace it with the source directory
        Remove-Item -Path $targetPath -Force
        Copy-Item -Path $sourceDir -Destination $targetPath -Recurse -Force
    } else {
        Write-Host "The target is not a file, no action taken."
    }

    $targetPath = "aws/modules"
    $sourceDir = "modules"
    if (Test-Path -Path $targetPath -PathType Leaf) {
        # It's a file, which might be a broken symlink, so replace it with the source directory
        Remove-Item -Path $targetPath -Force
        Copy-Item -Path $sourceDir -Destination $targetPath -Recurse -Force
    } else {
        Write-Host "The target is not a file, no action taken."
    }

    $targetPath = "aws/scenarios"
    $sourceDir = "scenarios"
    if (Test-Path -Path $targetPath -PathType Leaf) {
        # It's a file, which might be a broken symlink, so replace it with the source directory
        Remove-Item -Path $targetPath -Force
        Copy-Item -Path $sourceDir -Destination $targetPath -Recurse -Force
    } else {
        Write-Host "The target is not a file, no action taken."
    }
}

# Read the content of the file into a variable
$content = Get-Content "aws/env_vars/variables-$workspace.tfvars"

# Find the line containing 'key2'
$deploymentKey = $content | Where-Object { $_ -match '^deployment\s*=\s*".*"$' }

# Extract the value
if ($deploymentKey -ne $null) {
    $deployment = $deploymentKey -replace '^deployment\s*=\s*"(.*)"$', '$1'
    Write-Output "Deployment unique id: $deployment"
} else {
    Write-Error "Deployment unique id not found in the file"
}

# target profile
$targetAwsProfileKey = $content | Where-Object { $_ -match '^target_aws_profile\s*=\s*".*"$' }
$targetAWSProfile = $targetAwsProfileKey -replace '^target_aws_profile\s*=\s*"(.*)"$', '$1'
$targetAWSRegionKey = $content | Where-Object { $_ -match '^target_aws_region\s*=\s*".*"$' }
$targetAWSRegion = $targetAWSRegionKey -replace '^target_aws_region\s*=\s*"(.*)"$', '$1'

# Get the count of active VPCs using AWS CLI
$activeVpcCountCommand = "aws ec2 describe-vpcs --region $targetAWSRegion --query 'length(Vpcs[])' --profile $targetAWSProfile --output json"
$activeVpcCount = Invoke-Expression $activeVpcCountCommand | ConvertFrom-Json

# Get the VPC quota using AWS CLI
$vpcQuotaCommand = "aws service-quotas get-service-quota --service-code 'vpc' --quota-code 'L-F678F1CE' --region $targetAWSRegion --profile $targetAWSProfile --query 'Quota.Value' --output json --color off --no-cli-pager"
$vpcQuota = Invoke-Expression $vpcQuotaCommand | ConvertFrom-Json

# Check if there are at least 2 VPCs available
$availableVpcCount = $vpcQuota - $activeVpcCount
if ($availableVpcCount -lt 2) {
    Write-Host "Not enough available VPCs. Active: $activeVpcCount, Quota: $vpcQuota"
    # Handle the scenario when there are not enough VPCs available
    # For example, you can exit the script or log a message
    exit
} else {
    Write-Host "Found $availableVpcCount available vpcs. Active: $activeVpcCount, Quota: $vpcQuota"
}

# stage kubeconfig
# List of filenames to stage
$fileNames = @('config', "$csp-attacker-$deployment-kubeconfig", "$csp-target-$deployment-kubeconfig")

# Destination directory
$destinationDir = [System.Environment]::GetFolderPath('UserProfile') + "\.kube"

# Ensure the destination directory exists
if (-not (Test-Path -Path $destinationDir)) {
    New-Item -ItemType Directory -Path $destinationDir | Out-Null
}

# Touch each file in the destination directory
foreach ($fileName in $fileNames) {
    $filePath = Join-Path $destinationDir $fileName

    if (-not (Test-Path -Path $filePath)) {
        # Create a new file if it does not exist
        New-Item -ItemType File -Path $filePath | Out-Null
    } else {
        # Update the last write time if the file exists
        (Get-Item $filePath).LastWriteTime = Get-Date
    }

    Write-Output "Touched $filePath"
}

# start terraform plan/apply/destroy
write-output "Changing directory to: $csp"
cd $csp

# stage default vars if they don't exist
$env_vars = "env_vars/variables.tfvars"
if (-not (Test-Path -Path $env_vars)) {
    # Create a new file if it does not exist
    New-Item -ItemType File -Path $env_vars | Out-Null
} else {
    # Update the last write time if the file exists
    (Get-Item $env_vars).LastWriteTime = Get-Date
}

# terraform init every time
$init = "terraform init -upgrade"
write-output "Running: $init"
Invoke-Expression $init

# if we are asked to destroy add the -destroy parameter
if ($action -eq "destroy"){
    $destroyParam = "-destroy"
}else{
    $destroyParam = ""
}
$plan = "terraform plan $destroyParam --var-file env_vars/variables.tfvars --var-file env_vars/variables-$workspace.tfvars -detailed-exitcode -out build.tfplan"
write-output "Running: $plan"

Invoke-Expression $plan

if ($action -eq "apply" -or $action -eq "destroy") {
    $apply = "terraform apply build.tfplan"
    write-output "Running: $apply"
    Invoke-Expression $apply
}

cd ..

write-output "Done."