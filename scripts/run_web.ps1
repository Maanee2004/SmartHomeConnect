# Lance l'app Flutter Web en mode fiable (web-server + ouverture navigateur).
# Usage : .\scripts\run_web.ps1
#         .\scripts\run_web.ps1 -Port 8081
#
# Pourquoi pas "flutter run -d edge" ?
# Sur certains PC Windows, Flutter n'arrive pas a connecter le debug a Edge
# ("Failed to launch browser after 3 tries"). Le mode web-server contourne ce bug.

param(
    [int]$Port = 8080
)

$ErrorActionPreference = 'Stop'

function Get-PortOwnerPid {
    param([int]$Port)
    $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($conn) { return $conn.OwningProcess }
    return $null
}

function Wait-AndOpenBrowser {
    param(
        [string]$Url,
        [int]$TimeoutSec = 180
    )

    $edge = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
    if (-not (Test-Path $edge)) {
        $edge = "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
    }

    for ($i = 0; $i -lt $TimeoutSec; $i++) {
        try {
            $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 2
            if ($resp.StatusCode -eq 200) {
                if (Test-Path $edge) {
                    Start-Process $edge $Url | Out-Null
                } else {
                    Start-Process $Url | Out-Null
                }
                Write-Host "Navigateur ouvert : $Url" -ForegroundColor Green
                return
            }
        } catch {
            Start-Sleep -Seconds 1
        }
    }

    Write-Warning "Le serveur n'a pas repondu a temps. Ouvrez manuellement : $Url"
}

$portPid = Get-PortOwnerPid -Port $Port
if ($portPid) {
    Write-Host ""
    Write-Warning "Le port $Port est deja utilise (PID $portPid)."
    Write-Host "Arretez l'autre serveur avec 'q' dans son terminal," -ForegroundColor Yellow
    Write-Host "ou relancez avec un autre port :" -ForegroundColor Yellow
    Write-Host "  .\scripts\run_web.ps1 -Port 8081" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

$url = "http://127.0.0.1:${Port}/"
Write-Host ""
Write-Host "=== Smart Home Connect - Web (local) ===" -ForegroundColor Cyan
Write-Host "URL : $url" -ForegroundColor Green
Write-Host "Le navigateur s'ouvrira automatiquement une fois le serveur pret." -ForegroundColor DarkGray
Write-Host ""

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

$browserJob = Start-Job -ScriptBlock ${function:Wait-AndOpenBrowser} -ArgumentList $url, 180

try {
    flutter run -d web-server --web-hostname 127.0.0.1 --web-port $Port
} finally {
    if ($browserJob.State -eq 'Running') {
        Stop-Job $browserJob -ErrorAction SilentlyContinue
        Remove-Job $browserJob -Force -ErrorAction SilentlyContinue
    }
}
