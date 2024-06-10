# Combined Script

# Ensure running as administrator
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    Exit
}
$Host.UI.RawUI.WindowTitle = "Combined Script (Administrator)"
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.PrivateData.ProgressBackgroundColor = "Black"
$Host.PrivateData.ProgressForegroundColor = "White"
Clear-Host

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
        if ($psISE) {
            Write-Progress "$ProgressText" -id 0 -percentComplete $percentComplete
        } else {
            Write-Host -NoNewLine "`r$ProgressText $(''.PadRight($BarSize * $percent, [char]9608).PadRight($BarSize, [char]9617)) $($percentComplete.ToString('##0.00').PadLeft(6)) % "
        }
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

function CPUStressTests {
    function Prime95Test {
        Write-Host "Installing: Prime95 . . ."
        Get-FileFromWeb -URL "https://www.mersenne.org/download/software/v30/30.19/p95v3019b13.win64.zip" -File "$env:TEMP\Prime 95.zip"
        Expand-Archive "$env:TEMP\Prime 95.zip" -DestinationPath "$env:TEMP\Prime 95" -ErrorAction SilentlyContinue
        Start-Process "$env:TEMP\Prime 95\prime95.exe"
        Clear-Host
        Write-Host "Run a basic CPU stress test to check for errors."
        Write-Host "Check temps and WHEA errors in Hw Info during this test."
        Write-Host "In Prime95, click 'Window' and select 'Merge All Workers'."
        Write-Host ""
        Write-Host "CPU and RAM errors should not be ignored as they can lead to:"
        Write-Host "-Corrupted Windows"
        Write-Host "-Corrupted files"
        Write-Host "-Stutters and hitches"
        Write-Host "-Poor performance"
        Write-Host "-Input lag"
        Write-Host "-Shutdowns"
        Write-Host "-Blue screens"
        Write-Host ""
        Write-Host "Basic troubleshooting for errors or issues running XMP DOCP EXPO:"
        Write-Host "-BIOS out of date? (update)"
        Write-Host "-BIOS bugged out? (clear CMOS)"
        Write-Host "-Incompatible RAM? (check QVL)"
        Write-Host "-Mismatched RAM? (replace)"
        Write-Host "-RAM in wrong slots? (check manual)"
        Write-Host "-Unlucky CPU memory controller? (lower RAM speed)"
        Write-Host "-Overclock? (turn it off/dial it down)"
        Write-Host "-CPU cooler overtightened? (loosen)"
        Write-Host "-CPU overheating? (repaste/retighten/RMA cooler)"
        Write-Host "-RAM overheating? Typically over 55deg. (fix case flow/ram fan)"
        Write-Host "-Faulty RAM stick? (RMA)"
        Write-Host "-Faulty motherboard? (RMA)"
        Write-Host "-Faulty CPU? (RMA)"
        Write-Host "-Bent CPU pin? (RMA)"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    function Show-CPUMenu {
        Clear-Host
        Write-Host "Select a CPU test to run:"
        Write-Host "1. Prime95 Test"
        Write-Host "2. Back to Main Menu"

        $choice = Read-Host "Enter your choice (1-2)"
        switch ($choice) {
            1 { Prime95Test }
            2 { Show-Menu }
            default {
                Write-Host "Invalid choice, please select a valid option."
                Show-CPUMenu
            }
        }
    }
    Show-CPUMenu
}

function GPUStressTests {
    function GPUMarkTest {
        Write-Host "Installing: FurMark . . ."
        Get-FileFromWeb -URL "https://geeks3d.com/downloads/2024p/furmark2/FurMark_2.3.0.0_win64.zip" -File "$env:TEMP\FurMark.zip"
        Expand-Archive "$env:TEMP\FurMark.zip" -DestinationPath "$env:TEMP\FurMark" -ErrorAction SilentlyContinue
        Start-Process "$env:TEMP\FurMark\FurMark_win64\FurMark_GUI.exe"
        Clear-Host
        Write-Host "Run a basic GPU stress test."
        Write-Host ""
        Write-Host "Basic troubleshooting items to monitor:"
        Write-Host "-Temps"
        Write-Host "-Framerate"
        Write-Host "-Artifacts"
        Write-Host "-Freezing"
        Write-Host "-Driver crashes"
        Write-Host "-Shutdowns"
        Write-Host "-Blue screens"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    function GPUMonitorTest {
        Write-Host "Installing: Gpu Z . . ."
        Get-FileFromWeb -URL "https://ftp.nluug.nl/pub/games/PC/guru3d/generic/GPU-Z-[Guru3D.com].zip" -File "$env:TEMP\Gpu Z.zip"
        Expand-Archive "$env:TEMP\Gpu Z.zip" -DestinationPath "$env:TEMP\Gpu Z" -ErrorAction SilentlyContinue
        Start-Process "$env:TEMP\Gpu Z\GPU-Z.2.59.0.exe"
        Clear-Host
        Write-Host "Check PCIe bus interface is at maximum."
        Write-Host "Verify monitor cable is connected to the GPU."
        Write-Host "Confirm GPU is in the top PCIe motherboard slot."
        Write-Host "Running multiple graphics cards is not recommended."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    function Show-GPUMenu {
        Clear-Host
        Write-Host "Select a GPU test to run:"
        Write-Host "1. FurMark Test"
        Write-Host "2. GPU-Z Test"
        Write-Host "3. Back to Main Menu"

        $choice = Read-Host "Enter your choice (1-3)"
        switch ($choice) {
            1 { GPUMarkTest }
            2 { GPUMonitorTest }
            3 { Show-Menu }
            default {
                Write-Host "Invalid choice, please select a valid option."
                Show-GPUMenu
            }
        }
    }
    Show-GPUMenu
}

function RAMTests {
    function RAMStatus {
        Write-Host "Installing: Cpu Z . . ."
        Get-FileFromWeb -URL "https://download.cpuid.com/cpu-z/cpu-z_2.09-en.zip" -File "$env:TEMP\Cpu Z.zip"
        Expand-Archive "$env:TEMP\Cpu Z.zip" -DestinationPath "$env:TEMP\Cpu Z" -ErrorAction SilentlyContinue
        Start-Process "$env:TEMP\Cpu Z\cpuz_x64.exe"
        Clear-Host
        Write-Host "Check (XMP DOCP EXPO) is enabled."
        Write-Host "Verify RAM is in the correct slots."
        Write-Host "Confirm there is no mismatch in RAM modules."
        Write-Host "At least two RAM sticks (dual channel) is ideal."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    function Show-RAMMenu {
        Clear-Host
        Write-Host "Select a RAM test to run:"
        Write-Host "1. CPU-Z Test"
        Write-Host "2. Back to Main Menu"

        $choice = Read-Host "Enter your choice (1-2)"
        switch ($choice) {
            1 { RAMStatus }
            2 { Show-Menu }
            default {
                Write-Host "Invalid choice, please select a valid option."
                Show-RAMMenu
            }
        }
    }
    Show-RAMMenu
}

function SystemFPSAndLatency {
    function LatencyCheck {
        Write-Host "Installing: LatencyMon. . ."
        Get-FileFromWeb -URL "https://www.resplendence.com/download/LatencyMon.exe" -File "$env:TEMP\LatencyMon.exe"
        Start-Process -FilePath "$env:TEMP\LatencyMon.exe" -WindowStyle Hidden
        Clear-Host
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    function CapFrameX {
        Write-Host "Installing: CapFrameX . . ."
        Get-FileFromWeb -URL "https://www.capframex.com/download/latest" -File "$env:TEMP\CapFrameX.zip"
        Expand-Archive "$env:TEMP\CapFrameX.zip" -DestinationPath "$env:TEMP\CapFrameX" -ErrorAction SilentlyContinue
        Start-Process "$env:TEMP\CapFrameX\CapFrameX.exe"
        Clear-Host
        Write-Host "CapFrameX is installed and running."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    function Show-SystemFPSAndLatencyMenu {
        Clear-Host
        Write-Host "Select a System FPS and Latency test to run:"
        Write-Host "1. LatencyMon"
        Write-Host "2. CapFrameX"
        Write-Host "3. Back to Main Menu"

        $choice = Read-Host "Enter your choice (1-3)"
        switch ($choice) {
            1 { LatencyCheck }
            2 { CapFrameX }
            3 { Show-Menu }
            default {
                Write-Host "Invalid choice, please select a valid option."
                Show-SystemFPSAndLatencyMenu
            }
        }
    }
    Show-SystemFPSAndLatencyMenu
}

function BIOSUpdate {
    Write-Host "Fetching Motherboard ID and opening search page. . ."
    $instanceID = (wmic baseboard get product)
    Start-Process "https://www.google.com/search?q=$instanceID"
}

function BIOSSettings {
    Write-Host "INTEL CPU"
    Write-Host "-ENABLE ram profile (XMP DOCP EXPO)"
    Write-Host "-DISABLE c-state"
    Write-Host "-ENABLE resizable bar (REBAR C.A.M)"
    Write-Host ""
    Write-Host "AMD CPU"
    Write-Host "-ENABLE ram profile (XMP DOCP EXPO)"
    Write-Host "-ENABLE precision boost overdrive (PBO)"
    Write-Host "-ENABLE resizable bar (REBAR C.A.M)"
    Write-Host ""
    Write-Host "MAX pump and set fans to performance"
    Write-Host ""
    Write-Host "DISABLE any driver installer software"
    Write-Host "-Asus armory crate"
    Write-Host "-MSI driver utility"
    Write-Host "-Gigabyte update utility"
    Write-Host "-Asrock motherboard utility"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Clear-Host
    Write-Host "Press 'Y' To Restart To BIOS"
    while ($true) {
        $choice = Read-Host " "
        if ($choice -match '^[yY]$') {
            switch ($choice) {
                y {
                    Clear-Host
                    Write-Host "Restarting To BIOS: Press any key to restart . . ."
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    cmd /c C:\Windows\System32\shutdown.exe /r /fw
                    exit
                }
            }
        } else {
            Write-Host "Invalid input. Please select a valid option (Y)."
        }
    }
}

function Show-Menu {
    Clear-Host
    Write-Host "Select a test to run:"
    Write-Host "1. CPU Stress Tests"
    Write-Host "2. GPU Stress Tests"
    Write-Host "3. RAM Tests"
    Write-Host "4. System FPS and Latency"
    Write-Host "5. BIOS Update"
    Write-Host "6. BIOS Settings"
    Write-Host "7. Exit"

    $choice = Read-Host "Enter your choice (1-7)"
    switch ($choice) {
        1 { CPUStressTests }
        2 { GPUStressTests }
        3 { RAMTests }
        4 { SystemFPSAndLatency }
        5 { BIOSUpdate }
        6 { BIOSSettings }
        7 { Exit }
        default {
            Write-Host "Invalid choice, please select a valid option."
            Show-Menu
        }
    }
}

Show-Menu
