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

# powershell v7 required for -Parallel (currently terraform doesn't _easily_ support v7 provisioning)
#$myAzureVMs | ForEach-Object -Parallel {
$myAzureVMs | ForEach-Object {
    Write-Output "VM Name: " $_.Name
    if ($_.Tags.GetEnumerator() -contains @{Key="${ tag }"; Value="true"}){
        Write-Output "Tag Found: ${ tag }"
        $out = Invoke-AzVMRunCommand `
            -ResourceGroupName $_.ResourceGroupName `
            -VMName $_.Name `
            -CommandId 'RunShellScript' `
            -ScriptString "echo '${ base64_payload }' | tee /tmp/payload_${ module_name } | base64 -d | /bin/bash -"
        $out
    } else {
        Write-Output "Tag Not Found Skipping: ${ tag }"
    }
    
}