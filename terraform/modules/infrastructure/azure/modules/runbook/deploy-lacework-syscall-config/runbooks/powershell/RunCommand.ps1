
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
$jobs = @{}
$retryLimit = 3

Get-AzVM -ResourceGroupName $resourceGroup -status | Where-Object { `
    $_.PowerState -eq "VM running" `
    -and $_.StorageProfile.OSDisk.OSType -eq "Linux" `
    -and $_.Tags.Keys -contains "${ tag }" `
    -and $_.Tags["${ tag }"] -eq "true" `
} | ForEach-Object {
    $success = $false
    for ($i=1; $i -le $retryLimit; $i++){
        try {
            Invoke-AzVMRunCommand `
                    -ResourceGroupName $resourceGroup `
                    -VMName $_.name `
                    -CommandId 'RunShellScript' `
                    -ScriptString "echo '${ base64_payload }' | tee /tmp/payload_${ module_name } | base64 -d | /bin/bash - &"
            Write-Output "Job started successfully."
            $success = $true
            break
        }
        catch {
            $ErrorMessage = "Error connecting to Azure: " + $_.Exception.message
            Write-Error $ErrorMessage
            $rnd = Get-Random -Minimum 30 -Maximum 120
            Write-Output "Will retry again in $rnd seconds..."
            Start-Sleep -Seconds $rnd
        }
    }
    if ($success -eq $false) {
        Write-Error "Unable to execute task on machine $_.name after $retryLimit retries."
    }
}

