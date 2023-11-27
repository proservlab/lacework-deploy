param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("target", "attacker")]
    [string]$environment,
    [Parameter(Mandatory=$true)]
    [string]$workspace
)

# Terraform Workspace Selection and Instance Information Retrieval
function GetTerraformInstanceInfo {
    param (
        [string]$workspace,
        [string]$environment
    )
    
    $csp = ($workspace -split '-')[0]

    # Select Terraform workspace
    terraform -chdir="./${csp}" workspace select $workspace

    # Get instance information
    $jsonInstances = terraform -chdir="./${csp}" output --json "${environment}-aws-instances"
    return $jsonInstances | ConvertFrom-Json
}

# Function to Display Instances and Allow Selection
function SelectInstance {
    param (
        [array]$instances
    )

    $index = 1
    foreach ($instance in $instances) {
        Write-Host "${index}: $($instance.profile):$($instance.id):$($instance.name)"
        $index++
    }

    $selectedNumber = Read-Host "Enter the number of the instance to connect"
    if ($selectedNumber -le 0 -or $selectedNumber -gt $instances.Count) {
        Write-Error "Invalid selection. Try again."
        return $null
    }

    return $instances[$selectedNumber - 1]
}

$instanceInfo = GetTerraformInstanceInfo -workspace $workspace -environment $environment
$selectedInstance = SelectInstance -instances $instanceInfo

if ($null -eq $selectedInstance) {
    exit
}

$instanceName = $selectedInstance.name
$instanceId = $selectedInstance.id
$awsProfile = $selectedInstance.profile

Write-Host "Connecting to $instanceName with id $instanceId in AWS profile $awsProfile..."
# Start AWS SSM Session
aws ssm start-session --target=$instanceId --profile=$awsProfile