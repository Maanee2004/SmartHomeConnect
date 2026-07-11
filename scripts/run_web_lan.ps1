# Lance l'app Flutter Web accessible sur le reseau local (meme Wi-Fi).
# Usage : .\scripts\run_web_lan.ps1
#         .\scripts\run_web_lan.ps1 -Port 8081
# Puis sur le telephone : Parametres > Acces mobile (Wi-Fi) > scanner le QR.

param(
    [int]$Port = 8080
)

$ErrorActionPreference = 'Stop'

function Test-LanCandidate {
    param(
        [string]$IPAddress,
        [string]$InterfaceAlias
    )

    if ($IPAddress -match '^127\.') { return $false }
    if ($IPAddress -match '^169\.254\.') { return $false }
    if ($IPAddress -match '^192\.168\.56\.') { return $false }
    if ($IPAddress -match '^192\.168\.137\.') { return $false }
    if ($IPAddress -match '^192\.168\.(18|187)\.') { return $false }
    if ($InterfaceAlias -match 'VMware|VirtualBox|Hyper-V|TAP|Loopback|vEthernet|Bluetooth') {
        return $false
    }
    if ($InterfaceAlias -match 'Local Area Connection\*') { return $false }

    return $true
}

function Get-LanIPv4 {
    $candidates = @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object {
            Test-LanCandidate -IPAddress $_.IPAddress -InterfaceAlias $_.InterfaceAlias
        })

    if ($candidates.Count -gt 0) {
        $wifi = @($candidates | Where-Object { $_.InterfaceAlias -match 'Wi-Fi|WLAN|Wireless' })
        if ($wifi.Count -gt 0) {
            return ($wifi | Select-Object -First 1).IPAddress
        }

        $eth = @($candidates | Where-Object {
                $_.InterfaceAlias -match 'Ethernet' -and
                $_.InterfaceAlias -notmatch 'VMware|Virtual'
            })
        if ($eth.Count -gt 0) {
            return ($eth | Select-Object -First 1).IPAddress
        }

        return ($candidates | Select-Object -First 1).IPAddress
    }

    $ipconfigText = ipconfig
    $wifiBlock = ($ipconfigText -split '(?=^\S)' | Where-Object { $_ -match 'Wi-Fi|WLAN|Wireless' } | Select-Object -First 1)
    if ($wifiBlock) {
        $wifiIp = [regex]::Match($wifiBlock, 'IPv4[^:]*:\s*(\d+\.\d+\.\d+\.\d+)').Groups[1].Value
        if ($wifiIp -and (Test-LanCandidate -IPAddress $wifiIp -InterfaceAlias 'Wi-Fi')) {
            return $wifiIp
        }
    }

    $line = $ipconfigText | Select-String -Pattern 'IPv4[^:]*:\s*(\d+\.\d+\.\d+\.\d+)' |
        ForEach-Object { $_.Matches[0].Groups[1].Value } |
        Where-Object { Test-LanCandidate -IPAddress $_ -InterfaceAlias 'fallback' } |
        Select-Object -First 1

    return $line
}

function Get-PortOwnerPid {
    param([int]$Port)

    $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($conn) {
        return $conn.OwningProcess
    }
    return $null
}

$ip = Get-LanIPv4
$portPid = Get-PortOwnerPid -Port $Port

if ($portPid) {
    Write-Host ""
    Write-Warning "Le port $Port est deja utilise (processus PID $portPid)."
    Write-Host "Arretez l'autre serveur Flutter avec 'q' dans son terminal," -ForegroundColor Yellow
    Write-Host "ou relancez avec un autre port :" -ForegroundColor Yellow
    Write-Host "  .\scripts\run_web_lan.ps1 -Port 8081" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

if (-not $ip) {
    Write-Warning "Impossible de detecter l'adresse IP Wi-Fi. Utilisez ipconfig et saisissez-la dans l'app."
} else {
    Write-Host ""
    Write-Host "=== Smart Home Connect - acces mobile (LAN) ===" -ForegroundColor Cyan
    Write-Host "URL sur le telephone : http://${ip}:${Port}/" -ForegroundColor Green
    Write-Host "1. Ouvrez cette URL sur le PC si besoin : http://localhost:${Port}/"
    Write-Host "2. Ouvrez http://localhost:${Port}/ puis Parametres > Acces mobile (Wi-Fi)"
    Write-Host "   L'IP $ip est pre-remplie si vous ouvrez l'app via http://${ip}:${Port}/"
    Write-Host "3. Scannez le QR code avec le telephone (meme Wi-Fi)"
    Write-Host ""
    Write-Host "Si plusieurs IP apparaissent dans ipconfig, utilisez celle du Wi-Fi ($ip)." -ForegroundColor DarkGray
    Write-Host ""
}

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

flutter run -d web-server --web-hostname 0.0.0.0 --web-port $Port
