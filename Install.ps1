$PSDefaultParameterValues['Stop-Process:ErrorAction'] = 'SilentlyContinue'

write-host @'
SpotifyBlocker por holasoyender
'@

$SpotifyDirectory = "$env:APPDATA\Spotify"
$SpotifyExecutable = "$SpotifyDirectory\Spotify.exe"
$SpotifyApps = "$SpotifyDirectory\Apps"

Write-Host 'Stopping Spotify...'`n
Stop-Process -Name Spotify
Stop-Process -Name SpotifyWebHelper

if ($PSVersionTable.PSVersion.Major -ge 7)
{
    Import-Module Appx -UseWindowsPowerShell
}

if (Get-AppxPackage -Name SpotifyAB.SpotifyMusic) {
  Write-Host @'
Se ha encontrado la versión de Windows Store de Spotify.
'@`n
  $ch = Read-Host -Prompt "Quieres desinstalar la verión de Spotify de Windows Store (Y/N) "
  if ($ch -eq 'y'){
     Write-Host @'
Desinstalando Spotify...
'@`n
     Get-AppxPackage -Name SpotifyAB.SpotifyMusic | Remove-AppxPackage
  } else{
     Write-Host @'
Saliendo...
'@`n
     Pause 
     exit
    }
}

Push-Location -LiteralPath $env:TEMP
try {
  New-Item -Type Directory -Name "BlockTheSpot-$(Get-Date -UFormat '%Y-%m-%d_%H-%M-%S')" `
  | Convert-Path `
  | Set-Location
} catch {
  Write-Output $_
  Pause
  exit
}

Write-Host 'Descargando el último parche (chrome_elf.zip)...'`n
$webClient = New-Object -TypeName System.Net.WebClient
try {
  $webClient.DownloadFile(
    'https://github.com/holasoyender/SpotifyBlocker/releases/latest/download/chrome_elf.zip',
    "$PWD\chrome_elf.zip"
  )
} catch {
  Write-Output $_
  Sleep
}

Expand-Archive -Force -LiteralPath "$PWD\chrome_elf.zip" -DestinationPath $PWD
Remove-Item -LiteralPath "$PWD\chrome_elf.zip"

$spotifyInstalled = (Test-Path -LiteralPath $SpotifyExecutable)
if (-not $spotifyInstalled) {
  Write-Host @'
No se ha encontrado ninguna versión de Spotify.
Descargando la útila versión...
'@
  try {
    $webClient.DownloadFile(
      'https://download.scdn.co/SpotifyFullSetup.exe',
      "$PWD\SpotifyFullSetup.exe"
    )
  } catch {
    Write-Output $_
    Pause
    exit
  }
  mkdir $SpotifyDirectory >$null 2>&1
  Write-Host 'Iniciando instalación...'
  Start-Process -FilePath "$PWD\SpotifyFullSetup.exe"
  Write-Host 'Cerrando Spotify...'
  while ((Get-Process -name Spotify -ErrorAction SilentlyContinue) -eq $null){ }
  Stop-Process -Name Spotify >$null 2>&1
  Stop-Process -Name SpotifyWebHelper >$null 2>&1
  Stop-Process -Name SpotifyFullSetup >$null 2>&1
}

if (!(test-path $SpotifyDirectory/chrome_elf_bak.dll)){
	move $SpotifyDirectory\chrome_elf.dll $SpotifyDirectory\chrome_elf_bak.dll >$null 2>&1
}

Write-Host 'Parcheando Spotify...'
$patchFiles = "$PWD\chrome_elf.dll", "$PWD\config.ini"
Copy-Item -LiteralPath $patchFiles -Destination "$SpotifyDirectory"

$ch = Read-Host -Prompt "Opcional - Quitar los banners y el botón de pagar. (Y/N) "
if ($ch -eq 'y') {
    $xpuiBundlePath = "$SpotifyApps\xpui.spa"
    $xpuiUnpackedPath = "$SpotifyApps\xpui\xpui.js"
    $fromZip = $false
    if (Test-Path $xpuiBundlePath) {
        Add-Type -Assembly 'System.IO.Compression.FileSystem'
        Copy-Item -Path $xpuiBundlePath -Destination "$xpuiBundlePath.bak"

        $zip = [System.IO.Compression.ZipFile]::Open($xpuiBundlePath, 'update')
        $entry = $zip.GetEntry('xpui.js')
        $reader = New-Object System.IO.StreamReader($entry.Open())
        $xpuiContents = $reader.ReadToEnd()
        $reader.Close()

        $fromZip = $true
    } elseif (Test-Path $xpuiUnpackedPath) {
        Copy-Item -Path $xpuiUnpackedPath -Destination "$xpuiUnpackedPath.bak"
        $xpuiContents = Get-Content -Path $xpuiUnpackedPath -Raw

    } else {
        Write-Host 'No se ha encontrado xpui.js, esto es un error interno, si el error persiste abre una issue en el repositorio.'
    }

    if ($xpuiContents) {
        $xpuiContents = $xpuiContents -replace '(\.ads\.leaderboard\.isEnabled)(}|\))', '$1&&false$2'
        $xpuiContents = $xpuiContents -replace '\.createElement\([^.,{]+,{onClick:[^.,]+,className:[^.]+\.[^.]+\.UpgradeButton}\),[^.(]+\(\)', ''
    
        if ($fromZip) {
            $writer = New-Object System.IO.StreamWriter($entry.Open())
            $writer.BaseStream.SetLength(0)
            $writer.Write($xpuiContents)
            $writer.Close()
            $zip.Dispose()
        } else {
            Set-Content -Path $xpuiUnpackedPath -Value $xpuiContents
        }
    }
} else {
     Write-Host @'
Omitiendo banners y botón de pagar...
'@`n
}

$tempDirectory = $PWD
Pop-Location

Remove-Item -Recurse -LiteralPath $tempDirectory  

Write-Host 'Instalación del crack de spotify acabada, iniciando Spotify...'
Start-Process -WorkingDirectory $SpotifyDirectory -FilePath $SpotifyExecutable
Write-Host 'Hecho!'

exit
