#Requires -RunAsAdministrator
# ============================================================
#  NTP Time Synchronization Script for Windows 10
#  Servers: ro.pool.ntp.org & pool.ntp.org
# ============================================================

# --- Configuration ---
$ntpServers = @(
    [PSCustomObject]@{ Id = 1; Name = "ro.pool.ntp.org"; Description = "Romania NTP Pool (recommended for RO users)" }
    [PSCustomObject]@{ Id = 2; Name = "pool.ntp.org";    Description = "Global NTP Pool (worldwide fallback)" }
)

# --- Functions ---
function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ========================================================" -ForegroundColor Cyan
    Write-Host "       NTP Time Synchronization Tool for Windows 10"        -ForegroundColor White
    Write-Host "  ========================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Menu {
    Write-Host "  Available NTP Servers:" -ForegroundColor Yellow
    Write-Host "  --------------------------------------------------------" -ForegroundColor DarkGray
    foreach ($server in $ntpServers) {
        Write-Host "    [$($server.Id)] $($server.Name)" -ForegroundColor Green -NoNewline
        Write-Host "  -  $($server.Description)" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "    [3] Use BOTH servers (primary + fallback)" -ForegroundColor Green -NoNewline
    Write-Host "  -  ro.pool.ntp.org as primary, pool.ntp.org as backup" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    [0] Exit" -ForegroundColor Red
    Write-Host "  --------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
}

function Set-NTPServer {
    param (
        [string]$PrimaryServer,
        [string]$FallbackServer = ""
    )

    # Build the NTP peer list
    if ($FallbackServer -ne "") {
        $ntpPeerList = "$PrimaryServer $FallbackServer"
    } else {
        $ntpPeerList = $PrimaryServer
    }

    Write-Host ""
    Write-Host "  [STEP 1/6] Stopping Windows Time service..." -ForegroundColor Yellow
    try {
        Stop-Service w32time -Force -ErrorAction Stop
        Write-Host "             Service stopped successfully." -ForegroundColor Green
    } catch {
        Write-Host "             Service was not running or could not be stopped. Continuing..." -ForegroundColor DarkYellow
    }

    Write-Host "  [STEP 2/6] Configuring NTP server(s): $ntpPeerList" -ForegroundColor Yellow
    # Set the NTP server in the registry
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" `
        -Name "NtpServer" -Value "$($PrimaryServer),0x9 $($FallbackServer),0x9".Trim() -Type String
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" `
        -Name "Type" -Value "NTP" -Type String

    # Configure the time provider
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient" `
        -Name "Enabled" -Value 1 -Type DWord
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient" `
        -Name "SpecialPollInterval" -Value 3600 -Type DWord

    # Enable NTP client
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config" `
        -Name "AnnounceFlags" -Value 5 -Type DWord
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config" `
        -Name "MaxPosPhaseCorrection" -Value 0xFFFFFFFF -Type DWord
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config" `
        -Name "MaxNegPhaseCorrection" -Value 0xFFFFFFFF -Type DWord

    Write-Host "             Registry configured successfully." -ForegroundColor Green

    Write-Host "  [STEP 3/6] Registering Windows Time service..." -ForegroundColor Yellow
    & w32tm /unregister 2>$null | Out-Null
    Start-Sleep -Seconds 1
    & w32tm /register 2>$null | Out-Null
    Write-Host "             Service registered successfully." -ForegroundColor Green

    Write-Host "  [STEP 4/6] Starting Windows Time service..." -ForegroundColor Yellow
    try {
        Start-Service w32time -ErrorAction Stop
        Set-Service w32time -StartupType Automatic
        Write-Host "             Service started and set to Automatic." -ForegroundColor Green
    } catch {
        Write-Host "             Failed to start service. Retrying..." -ForegroundColor Red
        Start-Sleep -Seconds 2
        Start-Service w32time -ErrorAction SilentlyContinue
    }

    Write-Host "  [STEP 5/6] Configuring NTP peer via w32tm..." -ForegroundColor Yellow
    if ($FallbackServer -ne "") {
        $w32tmPeers = "$PrimaryServer,0x9 $FallbackServer,0xa"
    } else {
        $w32tmPeers = "$PrimaryServer,0x9"
    }
    $configResult = & w32tm /config /manualpeerlist:"$w32tmPeers" /syncfromflags:manual /reliable:YES /update 2>&1
    Write-Host "             $configResult" -ForegroundColor Gray

    Write-Host "  [STEP 6/6] Forcing time synchronization..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    $syncResult = & w32tm /resync /rediscover 2>&1
    Write-Host "             $syncResult" -ForegroundColor Gray

    # --- Display Results ---
    Write-Host ""
    Write-Host "  ========================================================" -ForegroundColor Cyan
    Write-Host "                   SYNCHRONIZATION RESULTS"                  -ForegroundColor White
    Write-Host "  ========================================================" -ForegroundColor Cyan
    Write-Host ""

    # Show current configuration
    Write-Host "  Current NTP Configuration:" -ForegroundColor Yellow
    $queryStatus = & w32tm /query /status 2>&1
    foreach ($line in $queryStatus) {
        Write-Host "    $line" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "  Current NTP Source:" -ForegroundColor Yellow
    $querySource = & w32tm /query /source 2>&1
    Write-Host "    $querySource" -ForegroundColor Green

    Write-Host ""
    Write-Host "  Current System Time:" -ForegroundColor Yellow
    $currentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss (zzz UTC)"
    Write-Host "    $currentTime" -ForegroundColor Green

    Write-Host ""
    Write-Host "  Configured Peers:" -ForegroundColor Yellow
    $queryPeers = & w32tm /query /peers 2>&1
    foreach ($line in $queryPeers) {
        Write-Host "    $line" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "  --------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [OK] Time synchronization completed successfully!" -ForegroundColor Green
    Write-Host "  [OK] NTP Server: $ntpPeerList" -ForegroundColor Green
    Write-Host "  [OK] Sync interval: every 3600 seconds (1 hour)" -ForegroundColor Green
    Write-Host "  [OK] Service startup type: Automatic" -ForegroundColor Green
    Write-Host "  --------------------------------------------------------" -ForegroundColor DarkGray
}

# --- Check Administrator Privileges ---
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $isAdmin) {
    Write-Host ""
    Write-Host "  [ERROR] This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "          Right-click PowerShell -> 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "  Press Enter to exit"
    exit 1
}

# --- Main Loop ---
do {
    Show-Banner
    Show-Menu

    $choice = Read-Host "  Select an option [0-3]"

    switch ($choice) {
        "1" {
            Write-Host ""
            Write-Host "  >> Selected: ro.pool.ntp.org (Romania NTP Pool)" -ForegroundColor Cyan
            Set-NTPServer -PrimaryServer "ro.pool.ntp.org"
        }
        "2" {
            Write-Host ""
            Write-Host "  >> Selected: pool.ntp.org (Global NTP Pool)" -ForegroundColor Cyan
            Set-NTPServer -PrimaryServer "pool.ntp.org"
        }
        "3" {
            Write-Host ""
            Write-Host "  >> Selected: BOTH (ro.pool.ntp.org + pool.ntp.org)" -ForegroundColor Cyan
            Set-NTPServer -PrimaryServer "ro.pool.ntp.org" -FallbackServer "pool.ntp.org"
        }
        "0" {
            Write-Host ""
            Write-Host "  Exiting... Goodbye!" -ForegroundColor Yellow
            Write-Host ""
            exit 0
        }
        default {
            Write-Host ""
            Write-Host "  [ERROR] Invalid option. Please select 0, 1, 2, or 3." -ForegroundColor Red
        }
    }

    Write-Host ""
    $continue = Read-Host "  Do you want to configure another server? (Y/N)"
} while ($continue -eq "Y" -or $continue -eq "y")

Write-Host ""
Write-Host "  Thank you for using NTP Time Sync Tool!" -ForegroundColor Cyan
Write-Host "  Your system clock is now synchronized." -ForegroundColor Green
Write-Host ""
Read-Host "  Press Enter to exit"
