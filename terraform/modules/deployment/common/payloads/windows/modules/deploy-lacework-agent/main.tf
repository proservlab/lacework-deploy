locals {
    tool = "lacework"
    
    payload = <<-EOT
    Write-Log "Starting..."
    $service = Get-Service -Name "lwdatacollector" -ErrorAction SilentlyContinue
    if ((Test-Path -Path "C:\ProgramData\Lacework\config.json" -PathType Leaf) -and ($service -and $service.Status -eq 'Running')) {
        Write-Log "lacework already installed - nothing to do"
    } else {
        Write-Log "lacework not installed - installing..."
        $installPath = "$tempDir\Install-LWDataCollector.ps1"  # Adjust path as needed
        Remove-Item "$installPath" -Force -ErrorAction SilentlyContinue
        $installContent = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("${local.setup_lacework_agent}"))
        Set-Content -Path "$${installPath}" -Value $installContent
        $tempDir\Install-LWDataCollector.ps1 -MSIURL "https://updates.lacework.net/windows/latest/LWDataCollector.msi" -AccessToken "${try(length(var.inputs["lacework_agent_access_token"]), "false") != "false" ? var.inputs["lacework_agent_access_token"] : lacework_agent_access_token.agent[0].token}" -ServerURL "${var.inputs["lacework_server_url"]}"
    }
    Write-Log "done."
    EOT
    base64_payload = templatefile("${path.module}/../../delayed_start.ps1", { config = {
        script_name = var.inputs["tag"]
        log_rotation_count = 2
        powershell_pre_tasks = <<-EOT
        $service = Get-Service -Name "lwdatacollector" -ErrorAction SilentlyContinue
        if ((Test-Path -Path "C:\ProgramData\Lacework\config.json" -PathType Leaf) -and ($service -and $service.Status -eq 'Running')) {
            Write-Log "${local.tool} found - no installation required"; 
            exit 0; 
        }
        EOT
        choco_packages = ""
        powershell_post_tasks = ""
        script_delay_secs = 30
        next_stage_powershell_payload = local.payload
    }})

    setup_lacework_agent = base64encode(file("${path.module}/resources/Install-LWDataCollector.ps1"))

    outputs = {
        base64_payload = base64gzip(local.base64_payload)
        base64_uncompressed_powershell_payload = base64encode(local.base64_payload)
        base64_uncompressed_powershell_payload_additional = [
            {
                name = "${basename(abspath(path.module))}_setup_lacework_agent.ps1"
                content = base64encode(local.setup_lacework_agent)
            }
        ]
    }
}

#####################################################
# LACEWORK AGENT
#####################################################

resource "random_string" "this" {
    length            = 4
    special           = false
    upper             = false
    lower             = true
    numeric           = true
}

resource "lacework_agent_access_token" "agent" {
    count = try(length(var.inputs["lacework_agent_access_token"]), "false") != "false" ? 0 : 1
    name = "endpoint-agent-access-token-${random_string.this.id}-${var.inputs["environment"]}-${var.inputs["deployment"]}"
}