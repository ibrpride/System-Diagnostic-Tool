Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Set PowerShell console background to black
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "System Diagnostic Tool"
$form.Size = New-Object System.Drawing.Size(500, 600)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::Black
$form.ForeColor = [System.Drawing.Color]::White
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false

# Create a function to download files from the web
function Get-FileFromWeb {
    param (
        [Parameter(Mandatory)][string]$URL,
        [Parameter(Mandatory)][string]$File
    )
    function Show-Progress {
        param (
            [Parameter(Mandatory)][Single]$TotalValue,
            [Parameter(Mandatory)][Single]$CurrentValue,
            [Parameter(Mandatory)][string]$ProgressText,
            [Parameter()][int]$BarSize = 10,
            [Parameter()][switch]$Complete
        )
        $percent = $CurrentValue / $TotalValue
        $percentComplete = $percent * 100
        [System.Windows.Forms.Application]::DoEvents()
    }
    try {
        $request = [System.Net.HttpWebRequest]::Create($URL)
        $response = $request.GetResponse()
        if ($response.StatusCode -eq 401 -or $response.StatusCode -eq 403 -or $response.StatusCode -eq 404) {
            throw "Remote file either doesn't exist, is unauthorized, or is forbidden for '$URL'."
        }
        if ($File -match '^\.\\') {
            $File = Join-Path (Get-Location -PSProvider 'FileSystem') ($File -Split '^\.')[1]
        }
        if ($File -and !(Split-Path $File)) {
            $File = Join-Path (Get-Location -PSProvider 'FileSystem') $File
        }
        if ($File) {
            $fileDirectory = $([System.IO.Path]::GetDirectoryName($File))
            if (!(Test-Path($fileDirectory))) {
                [System.IO.Directory]::CreateDirectory($fileDirectory) | Out-Null
            }
        }
        [long]$fullSize = $response.ContentLength
        [byte[]]$buffer = new-object byte[] 1048576
        [long]$total = [long]$count = 0
        $reader = $response.GetResponseStream()
        $writer = new-object System.IO.FileStream $File, 'Create'
        do {
            $count = $reader.Read($buffer, 0, $buffer.Length)
            $writer.Write($buffer, 0, $count)
            $total += $count
            if ($fullSize -gt 0) {
                Show-Progress -TotalValue $fullSize -CurrentValue $total -ProgressText " $($File.Name)"
            }
        } while ($count -gt 0)
    } finally {
        $reader.Close()
        $writer.Close()
    }
}

# Create a function to display a message box
function Show-Message {
    param ($message)
    [System.Windows.Forms.MessageBox]::Show($message)
}

# Asynchronous download function
function Download-FileAsync {
    param (
        [string]$URL,
        [string]$File
    )
    Start-Job -ScriptBlock {
        param ($URL, $File)
        Get-FileFromWeb -URL $URL -File $File
    } -ArgumentList $URL, $File
}

# Create a function to style buttons
function Style-Button {
    param ($button)
    $button.BackColor = [System.Drawing.Color]::Black
    $button.ForeColor = [System.Drawing.Color]::White
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderColor = [System.Drawing.Color]::White
    $button.FlatAppearance.BorderSize = 1
    $button.Font = New-Object System.Drawing.Font("Arial", 10)
    $button.Size = New-Object System.Drawing.Size(350, 40)
    $button
}

# Create a label for the title
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "System Diagnostic Tool"
$titleLabel.AutoSize = $true
$titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleLabel.Location = New-Object System.Drawing.Point(80, 20)

# Create the buttons
$cpuButton = New-Object System.Windows.Forms.Button
$cpuButton.Text = "CPU Stress Tests"
$cpuButton.Location = New-Object System.Drawing.Point(75, 80)
Style-Button $cpuButton
$cpuButton.Add_Click({
    $cpuForm = New-Object System.Windows.Forms.Form
    $cpuForm.Text = "CPU Stress Tests"
    $cpuForm.Size = New-Object System.Drawing.Size(400, 200)
    $cpuForm.StartPosition = "CenterParent"
    $cpuForm.BackColor = [System.Drawing.Color]::Black
    $cpuForm.ForeColor = [System.Drawing.Color]::White
    
    $prime95Button = New-Object System.Windows.Forms.Button
    $prime95Button.Text = "Prime95 Test"
    $prime95Button.Location = New-Object System.Drawing.Point(50, 50)
    Style-Button $prime95Button
    $prime95Button.Add_Click({
        Show-Message "Installing Prime95..."
        Download-FileAsync -URL "https://www.mersenne.org/download/software/v30/30.19/p95v3019b13.win64.zip" -File "$env:TEMP\Prime 95.zip" | Out-Null
        Start-Sleep -Seconds 10
        Expand-Archive "$env:TEMP\Prime 95.zip" -DestinationPath "$env:TEMP\Prime 95" -ErrorAction SilentlyContinue
        Start-Process "$env:TEMP\Prime 95\prime95.exe"
    })
    
    $returnButton = New-Object System.Windows.Forms.Button
    $returnButton.Text = "Return"
    $returnButton.Location = New-Object System.Drawing.Point(50, 100)
    Style-Button $returnButton
    $returnButton.Add_Click({
        $cpuForm.Close()
    })

    $cpuForm.Controls.Add($prime95Button)
    $cpuForm.Controls.Add($returnButton)
    $cpuForm.ShowDialog()
})

$gpuButton = New-Object System.Windows.Forms.Button
$gpuButton.Text = "GPU Stress Tests"
$gpuButton.Location = New-Object System.Drawing.Point(75, 130)
Style-Button $gpuButton
$gpuButton.Add_Click({
    $gpuForm = New-Object System.Windows.Forms.Form
    $gpuForm.Text = "GPU Stress Tests"
    $gpuForm.Size = New-Object System.Drawing.Size(400, 300)
    $gpuForm.StartPosition = "CenterParent"
    $gpuForm.BackColor = [System.Drawing.Color]::Black
    $gpuForm.ForeColor = [System.Drawing.Color]::White
    
    $furMarkButton = New-Object System.Windows.Forms.Button
    $furMarkButton.Text = "FurMark Test"
    $furMarkButton.Location = New-Object System.Drawing.Point(50, 50)
    Style-Button $furMarkButton
    $furMarkButton.Add_Click({
        Show-Message "Installing FurMark..."
        Download-FileAsync -URL "https://geeks3d.com/downloads/2024p/furmark2/FurMark_2.3.0.0_win64.zip" -File "$env:TEMP\FurMark.zip" | Out-Null
        Start-Sleep -Seconds 10
        Expand-Archive "$env:TEMP\FurMark.zip" -DestinationPath "$env:TEMP\FurMark" -ErrorAction SilentlyContinue
        Start-Process "$env:TEMP\FurMark\FurMark_win64\FurMark_GUI.exe"
    })
    
    $gpuZButton = New-Object System.Windows.Forms.Button
    $gpuZButton.Text = "GPU-Z Test"
    $gpuZButton.Location = New-Object System.Drawing.Point(50, 100)
    Style-Button $gpuZButton
    $gpuZButton.Add_Click({
        Show-Message "Installing GPU-Z..."
        Download-FileAsync -URL "https://ftp.nluug.nl/pub/games/PC/guru3d/generic/GPU-Z-[Guru3D.com].zip" -File "$env:TEMP\Gpu Z.zip" | Out-Null
        Start-Sleep -Seconds 10
        Expand-Archive "$env:TEMP\Gpu Z.zip" -DestinationPath "$env:TEMP\Gpu Z" -ErrorAction SilentlyContinue
        Start-Process "$env:TEMP\Gpu Z\GPU-Z.2.59.0.exe"
    })

    $returnButton = New-Object System.Windows.Forms.Button
    $returnButton.Text = "Return"
    $returnButton.Location = New-Object System.Drawing.Point(50, 150)
    Style-Button $returnButton
    $returnButton.Add_Click({
        $gpuForm.Close()
    })
    
    $gpuForm.Controls.Add($furMarkButton)
    $gpuForm.Controls.Add($gpuZButton)
    $gpuForm.Controls.Add($returnButton)
    $gpuForm.ShowDialog()
})

$ramButton = New-Object System.Windows.Forms.Button
$ramButton.Text = "RAM Tests"
$ramButton.Location = New-Object System.Drawing.Point(75, 180)
Style-Button $ramButton
$ramButton.Add_Click({
    Show-Message "Installing CPU-Z..."
    Download-FileAsync -URL "https://download.cpuid.com/cpu-z/cpu-z_2.09-en.zip" -File "$env:TEMP\Cpu Z.zip" | Out-Null
    Start-Sleep -Seconds 10
    Expand-Archive "$env:TEMP\Cpu Z.zip" -DestinationPath "$env:TEMP\Cpu Z" -ErrorAction SilentlyContinue
    Start-Process "$env:TEMP\Cpu Z\cpuz_x64.exe"
})

$hwinfoButton = New-Object System.Windows.Forms.Button
$hwinfoButton.Text = "HWInfo"
$hwinfoButton.Location = New-Object System.Drawing.Point(75, 230)
Style-Button $hwinfoButton
$hwinfoButton.Add_Click({
    Show-Message "Installing: HW Info..."
    Download-FileAsync -URL "https://ixpeering.dl.sourceforge.net/project/hwinfo/Windows_Portable/hwi_772.zip" -File "$env:TEMP\Hw Info.zip" | Out-Null
    Start-Sleep -Seconds 10
    Expand-Archive "$env:TEMP\Hw Info.zip" -DestinationPath "$env:TEMP\Hw Info" -ErrorAction SilentlyContinue
    Start-Process "$env:TEMP\Hw Info\HWiNFO64.exe"
})

$systemButton = New-Object System.Windows.Forms.Button
$systemButton.Text = "System FPS and Latency"
$systemButton.Location = New-Object System.Drawing.Point(75, 280)
Style-Button $systemButton
$systemButton.Add_Click({
    $systemForm = New-Object System.Windows.Forms.Form
    $systemForm.Text = "System FPS and Latency"
    $systemForm.Size = New-Object System.Drawing.Size(400, 300)
    $systemForm.StartPosition = "CenterParent"
    $systemForm.BackColor = [System.Drawing.Color]::Black
    $systemForm.ForeColor = [System.Drawing.Color]::White
    
    $latencyMonButton = New-Object System.Windows.Forms.Button
    $latencyMonButton.Text = "LatencyMon"
    $latencyMonButton.Location = New-Object System.Drawing.Point(50, 50)
    Style-Button $latencyMonButton
    $latencyMonButton.Add_Click({
        Show-Message "Installing LatencyMon..."
        Download-FileAsync -URL "https://www.resplendence.com/download/LatencyMon.exe" -File "$env:TEMP\LatencyMon.exe" | Out-Null
        Start-Sleep -Seconds 10
        Start-Process -FilePath "$env:TEMP\LatencyMon.exe" -WindowStyle Hidden
    })
    
    $capFrameXButton = New-Object System.Windows.Forms.Button
    $capFrameXButton.Text = "CapFrameX"
    $capFrameXButton.Location = New-Object System.Drawing.Point(50, 100)
    Style-Button $capFrameXButton
    $capFrameXButton.Add_Click({
        Show-Message "Installing CapFrameX..."
        Download-FileAsync -URL "https://www.capframex.com/download/latest" -File "$env:TEMP\CapFrameX.zip" | Out-Null
        Start-Sleep -Seconds 10
        Expand-Archive "$env:TEMP\CapFrameX.zip" -DestinationPath "$env:TEMP\CapFrameX" -ErrorAction SilentlyContinue
        Start-Process "$env:TEMP\CapFrameX\CapFrameX.exe"
    })

    $returnButton = New-Object System.Windows.Forms.Button
    $returnButton.Text = "Return"
    $returnButton.Location = New-Object System.Drawing.Point(50, 150)
    Style-Button $returnButton
    $returnButton.Add_Click({
        $systemForm.Close()
    })

    $systemForm.Controls.Add($latencyMonButton)
    $systemForm.Controls.Add($capFrameXButton)
    $systemForm.Controls.Add($returnButton)
    $systemForm.ShowDialog()
})

$biosUpdateButton = New-Object System.Windows.Forms.Button
$biosUpdateButton.Text = "BIOS Update"
$biosUpdateButton.Location = New-Object System.Drawing.Point(75, 330)
Style-Button $biosUpdateButton
$biosUpdateButton.Add_Click({
    Show-Message "Fetching Motherboard ID and opening search page..."
    $instanceID = (wmic baseboard get product)
    Start-Process "https://www.google.com/search?q=$instanceID"
})

$biosSettingsButton = New-Object System.Windows.Forms.Button
$biosSettingsButton.Text = "BIOS Settings"
$biosSettingsButton.Location = New-Object System.Drawing.Point(75, 380)
Style-Button $biosSettingsButton
$biosSettingsButton.Add_Click({
    Show-Message "BIOS Settings"
    $biosForm = New-Object System.Windows.Forms.Form
    $biosForm.Text = "BIOS Settings"
    $biosForm.Size = New-Object System.Drawing.Size(600, 400)
    $biosForm.StartPosition = "CenterParent"
    $biosForm.BackColor = [System.Drawing.Color]::Black
    $biosForm.ForeColor = [System.Drawing.Color]::White

    $biosTextBox = New-Object System.Windows.Forms.TextBox
    $biosTextBox.Multiline = $true
    $biosTextBox.Dock = 'Fill'
    $biosTextBox.ReadOnly = $true
    $biosTextBox.BackColor = [System.Drawing.Color]::Black
    $biosTextBox.ForeColor = [System.Drawing.Color]::White
    $biosTextBox.Font = New-Object System.Drawing.Font("Arial", 10)
    $biosTextBox.Text = @"
INTEL CPU
- ENABLE ram profile (XMP DOCP EXPO)
- DISABLE c-state
- ENABLE resizable bar (REBAR C.A.M)

AMD CPU
- ENABLE ram profile (XMP DOCP EXPO)
- ENABLE precision boost overdrive (PBO)
- ENABLE resizable bar (REBAR C.A.M)

MAX pump and set fans to performance

DISABLE any driver installer software
- Asus armory crate
- MSI driver utility
- Gigabyte update utility
- Asrock motherboard utility

Press 'Y' To Restart To BIOS
"@

    $restartButton = New-Object System.Windows.Forms.Button
    $restartButton.Text = "Restart to BIOS"
    $restartButton.Location = New-Object System.Drawing.Point(50, 250)
    Style-Button $restartButton
    $restartButton.Add_Click({
        Show-Message "Restarting to BIOS..."
        Start-Job -ScriptBlock {
            Start-Sleep -Seconds 1
            cmd /c C:\Windows\System32\shutdown.exe /r /fw
        } | Out-Null
    })

    $returnButton = New-Object System.Windows.Forms.Button
    $returnButton.Text = "Return"
    $returnButton.Location = New-Object System.Drawing.Point(50, 300)
    Style-Button $returnButton
    $returnButton.Add_Click({
        $biosForm.Close()
    })

    $biosForm.Controls.Add($biosTextBox)
    $biosForm.Controls.Add($restartButton)
    $biosForm.Controls.Add($returnButton)
    $biosForm.ShowDialog()
})

$creditButton = New-Object System.Windows.Forms.Button
$creditButton.Text = "Developed by Ibrahim from IBRPRIDE.COM"
$creditButton.Location = New-Object System.Drawing.Point(75, 430)
Style-Button $creditButton
$creditButton.Add_Click({
    Show-Message "This tool was developed by Ibrahim from IBRPRIDE.COM"
})

# Add the title and buttons to the form
$form.Controls.Add($titleLabel)
$form.Controls.Add($cpuButton)
$form.Controls.Add($gpuButton)
$form.Controls.Add($ramButton)
$form.Controls.Add($hwinfoButton)
$form.Controls.Add($systemButton)
$form.Controls.Add($biosUpdateButton)
$form.Controls.Add($biosSettingsButton)
$form.Controls.Add($creditButton)

# Show the form
$form.ShowDialog()
