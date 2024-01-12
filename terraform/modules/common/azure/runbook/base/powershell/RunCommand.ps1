
#Resource Group my VMs are in
$resourceGroup = "${ resource_group }"

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with user-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity -AccountId "${ automation_account }" ).context

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext
Write-Output "Account ID of current context: " $AzureContext.Account.Id

#Get all Azure VMs which are in running state and are running Windows
$retryLimit = 3

Get-AzVM -ResourceGroupName $resourceGroup -status | Where-Object { `
    $_.PowerState -eq "VM running" `
    -and $_.StorageProfile.OSDisk.OSType -eq "Linux" `
    -and $_.Tags.Keys -contains "${ tag }" `
    -and $_.Tags["${ tag }"] -eq "true" `
} | ForEach-Object {
    $success = $false
    $machine = $_.name
    Write-Output "Running task on: $machine"
    for ($i=1; $i -le $retryLimit; $i++){
        $rnd = Get-Random -Minimum 1 -Maximum 120
        Write-Output ("Waiting {0} seconds before attempt {1}..." -f $rnd, $i)
        Start-Sleep -Seconds $rnd
        $job = Invoke-AzVMRunCommand `
                -AsJob `
                -ResourceGroupName $resourceGroup `
                -VMName $machine `
                -CommandId 'RunShellScript' `
                -ScriptString "nohup /bin/sh -c `"echo '${ base64_payload }' | tee /tmp/payload_${ module_name } | base64 -d | gunzip | /bin/bash -`" >/dev/null 2>&1 &" `
                -ErrorAction Continue
        $job | Wait-Job
        Write-Output ("Job Result on Machine: {0} [{1}]" -f $machine, $job.State)
        if ($job.State -eq 'Failed') {
            Write-Output ("Job failed to start. Retry {0} starting...." -f $i)
            $success = $false
        }else{
            Write-Output ("Job completed successfully.")
            $success = $true
            break
        }
    }
    if ($success -eq $false) {
        Write-Error "Unable to execute task on machine $machine after $retryLimit retries."
    }
}

