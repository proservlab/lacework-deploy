#Resource Group my VMs are in
$resourceGroup = "${ resource_group }"

#Select the right Azure subscription
# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with user-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity -AccountId "${ automation_account }" ).context

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext
Write-Output "Account ID of current context: " $AzureContext.Account.Id

#Get all Azure VMs which are in running state and are running Windows
$myAzureVMs = Get-AzVM -ResourceGroupName $resourceGroup -status | Where-Object {$_.PowerState -eq "VM running" -and $_.StorageProfile.OSDisk.OSType -eq "Linux"}

# powershell v5 hack for parallelism
$jobs = @()
foreach ($myAzureVM in $myAzureVMs) {
    Write-Output "VM Name: " $myAzureVM.Name
    $hasTag = $false
    foreach ($tag in $myAzureVM.Tags.GetEnumerator()) {
        if ($tag.Key -eq "${ tag }" -and $tag.Value -eq "true"){
            $hasTag = $true
            break
        }
    }
    if ($hasTag){
        Write-Output "Tag Found: ${ tag }"
        $scriptblock = {
            param ($subscriptionName, $resourceGroup, $name)
            $rnd = Get-Random -Minimum 60 -Maximum 90
            Write-Output "Sleeping for $rnd seconds..."
            Start-Sleep -Seconds $rnd
            Write-Output "Starting Execution: $resourceGroup"
            Import-Module Az.Accounts
            $AzureContext = (Connect-AzAccount -Identity -AccountId "${ automation_account }" ).context
            $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext
            $out = Invoke-AzVMRunCommand `
                -ResourceGroupName $resourceGroup `
                -VMName $name `
                -CommandId 'RunShellScript' `
                -ScriptString "echo '${ base64_payload }' | tee /tmp/payload_${ module_name } | base64 -d | /bin/bash - &"
            Write-Output $out.Value[0].Message
            Write-Output "Done."
        }
        $jobs += Start-Job -ScriptBlock $scriptblock -ArgumentList $AzureContext.Subscription.Name,$myAzureVM.ResourceGroupName,$myAzureVM.Name
    } else {
        Write-Output "Tag Not Found Skipping: ${ tag }"
    }
}
Write-Output "Started all jobs. Receiving results."
$jobs | % { $_ | Wait-Job }
$jobs | % { $json = $($_ | Select-Object *  | ConvertTo-Json); Write-Output "Result: $json" }

Write-Output "Done."