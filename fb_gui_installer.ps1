# FileBrowser Installer GUI Script
# Author: ulyhome
# Description: Interactive GUI-based PowerShell installer for FileBrowser

Add-Type -AssemblyName PresentationFramework
$logPath = "$env:ProgramData\FileBrowserInstaller.log"

function Write-Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "$timestamp - $message"
}

function Show-Menu {
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="FileBrowser Installer" Height="400" Width="400">
    <Grid Margin="10">
        <StackPanel>
            <TextBlock Text="Welcome to FileBrowser Installer" FontSize="16" FontWeight="Bold" Margin="0,0,0,20"/>
            <Button Name="InstallButton" Content="Install FileBrowser" Height="40" Margin="0,0,0,10"/>
            <Button Name="UpdateButton" Content="Update FileBrowser" Height="40" Margin="0,0,0,10"/>
            <Button Name="UninstallButton" Content="Uninstall FileBrowser" Height="40" Margin="0,0,0,10"/>
            <Button Name="StatusButton" Content="Check Status" Height="40" Margin="0,0,0,10"/>
            <Button Name="ExitButton" Content="Exit" Height="40"/>
        </StackPanel>
    </Grid>
</Window>
"@

    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $InstallButton = $window.FindName("InstallButton")
    $UpdateButton = $window.FindName("UpdateButton")
    $UninstallButton = $window.FindName("UninstallButton")
    $StatusButton = $window.FindName("StatusButton")
    $ExitButton = $window.FindName("ExitButton")

    $InstallButton.Add_Click({
        $window.Close()
        Install-FileBrowser
        Show-Menu
    })
    $UpdateButton.Add_Click({
        $window.Close()
        Update-FileBrowser
        Show-Menu
    })
    $UninstallButton.Add_Click({
        $window.Close()
        Uninstall-FileBrowser
        Show-Menu
    })
    $StatusButton.Add_Click({
        $window.Close()
        Check-Status
        Show-Menu
    })
    $ExitButton.Add_Click({
        $window.Close()
    })

    $window.ShowDialog() | Out-Null
}

function Install-FileBrowser {
    Write-Log "Starting installation."
    $installPath = "C:\\IT_folder\\filebrowser"
    $installedPath = "C:\\Program Files\\filebrowser\\filebrowser.exe"

    $port = Read-Host "Enter the port number to run FileBrowser on (e.g., 8080)"

    if ((Get-ExecutionPolicy) -ne 'Bypass') {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Write-Log "Execution policy set to Bypass."
    }

    Stop-Process -Name "filebrowser" -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    Remove-Item -Path $installedPath -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $installPath -Recurse -Force -ErrorAction SilentlyContinue

    if (-not (Test-Path -Path $installPath)) {
        New-Item -Path $installPath -ItemType Directory | Out-Null
        Write-Log "Created install path $installPath."
    }

    Write-Host "Downloading and installing FileBrowser..."
    Write-Log "Downloading FileBrowser script."
    iwr -useb https://raw.githubusercontent.com/filebrowser/get/master/get.ps1 | iex

    if (Test-Path $installedPath) {
        Copy-Item -Path $installedPath -Destination $installPath -Force
        Write-Log "Copied binary to $installPath."
    }

    $firewallEnabled = (Get-NetFirewallProfile | Where-Object { $_.Enabled -eq $true })
    if ($firewallEnabled) {
        if (-not(Get-NetFirewallRule -DisplayName "Allow FileBrowser $port Inbound" -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -DisplayName "Allow FileBrowser $port Inbound" -Direction Inbound -Protocol TCP -LocalPort $port -Action Allow
            Write-Log "Inbound rule added to firewall."
        }
        if (-not(Get-NetFirewallRule -DisplayName "Allow FileBrowser $port Outbound" -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -DisplayName "Allow FileBrowser $port Outbound" -Direction Outbound -Protocol TCP -LocalPort $port -Action Allow
            Write-Log "Outbound rule added to firewall."
        }
    }

    $hostname = $env:COMPUTERNAME
    $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.*' }).IPAddress | Select-Object -First 1

    $exePath = "$installPath\\filebrowser.exe"
    if (Test-Path $exePath) {
        Start-Process -FilePath $exePath -ArgumentList "-a 0.0.0.0 -p $port -r C:\\IT_folder\\filebrowser" -WorkingDirectory $installPath
        $msg = "FileBrowser installed and running at http://$ipAddress:$port`nHost: $hostname`nIP: $ipAddress"
        Write-Log "Installation completed successfully."
        [System.Windows.MessageBox]::Show($msg, "Success", 'OK', 'Information')
    } else {
        Write-Log "Installation failed: filebrowser.exe not found."
        [System.Windows.MessageBox]::Show("Failed to locate filebrowser.exe after installation.", "Error", 'OK', 'Error')
    }
}

function Update-FileBrowser {
    Write-Log "Initiating update."
    Install-FileBrowser
}

function Uninstall-FileBrowser {
    Write-Log "Uninstalling FileBrowser."
    $installPath = "C:\\IT_folder\\filebrowser"
    $installedPath = "C:\\Program Files\\filebrowser\\filebrowser.exe"

    Stop-Process -Name "filebrowser" -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    Remove-Item -Path $installedPath -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $installPath -Recurse -Force -ErrorAction SilentlyContinue

    Get-NetFirewallRule | Where-Object { $_.DisplayName -like "Allow FileBrowser*" } | Remove-NetFirewallRule

    Write-Log "FileBrowser uninstalled."
    [System.Windows.MessageBox]::Show("FileBrowser has been successfully uninstalled.", "Uninstalled", 'OK', 'Information')
}

function Check-Status {
    $proc = Get-Process -Name "filebrowser" -ErrorAction SilentlyContinue
    if ($proc) {
        $uptime = (Get-Date) - $proc.StartTime
        $portInfo = netstat -ano | Select-String $proc.Id | Select-String LISTENING
        $ports = ($portInfo -replace ".*:(\d+).*", '$1') -join ", "
        Write-Log "FileBrowser is running. Uptime: $uptime. Ports: $ports"
        [System.Windows.MessageBox]::Show("FileBrowser is running.`nUptime: $($uptime.ToString())`nPorts: $ports", "Status", 'OK', 'Information')
    } else {
        Write-Log "FileBrowser is not running."
        [System.Windows.MessageBox]::Show("FileBrowser is not currently running.", "Status", 'OK', 'Warning')
    }
}

Show-Menu
