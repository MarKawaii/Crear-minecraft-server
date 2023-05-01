param (
    [string]$Folder,
    [string]$ServerVersion,
    [int]$RAM = 1024 # Establece un valor predeterminado de 1024 MB de RAM
)

function DescargarServidor {
    param (
        [string]$ruta_carpeta_servidor,
        [string]$version
    )

    $url_base = "https://launchermeta.mojang.com/v1/packages/"
    $response = Invoke-WebRequest -Uri "https://launchermeta.mojang.com/mc/game/version_manifest.json" -UseBasicParsing
    $version_manifest = $response | ConvertFrom-Json
    $version_info = $version_manifest.versions | Where-Object { $_.id -eq $version }

    if ($null -eq $version_info) {
        Write-Error "Versión del servidor no soportada."
        exit 1
    }

    $version_manifest_url = $version_info.url
    $version_response = Invoke-WebRequest -Uri $version_manifest_url -UseBasicParsing
    $version_data = $version_response | ConvertFrom-Json
    $server_download_url = $version_data.downloads.server.url
    $archivo_servidor = "minecraft_server.jar"

    Write-Host "Descargando el archivo del servidor de Minecraft..."

    try {
        $client = New-Object System.Net.WebClient
        $ruta_archivo_servidor = Join-Path $ruta_carpeta_servidor $archivo_servidor
        $client.DownloadFile($server_download_url, $ruta_archivo_servidor)
        Write-Host "Archivo del servidor descargado correctamente."
    }
    catch {
        Write-Error "Error al descargar el archivo del servidor: $_"
        exit 1
    }
}

function CrearArchivosEjecucion {
    param (
        [string]$ruta_carpeta_servidor,
        [int]$RAM
    )

    $nombre_archivo_ps1 = "script.ps1"
    $contenido_archivo_ps1 = @"
Set-Location '$ruta_carpeta_servidor'
java -Xmx${RAM}M -Xms${RAM}M -jar minecraft_server.jar nogui
"@
    $ruta_archivo_ps1 = Join-Path $ruta_carpeta_servidor $nombre_archivo_ps1
    Set-Content -Path $ruta_archivo_ps1 -Value $contenido_archivo_ps1

    $nombre_archivo_bat = "Iniciar.bat"
    $contenido_archivo_bat = @"
@echo off
powershell -NoExit -ExecutionPolicy Bypass -File "$nombre_archivo_ps1"
pause
"@
    $ruta_archivo_bat = Join-Path $ruta_carpeta_servidor $nombre_archivo_bat
    Set-Content -Path $ruta_archivo_bat -Value $contenido_archivo_bat
}
function GenerarEula {
    param (
        [string]$ruta_carpeta_servidor
    )

    $ruta_archivo_eula = Join-Path $ruta_carpeta_servidor "eula.txt"

    if (-not (Test-Path $ruta_archivo_eula)) {
        Set-Content -Path $ruta_archivo_eula -Value "eula=true"
    }
}

function GenerarServerProperties {
    param (
        [string]$ruta_carpeta_servidor
    )

    $contenido_server_properties = @"
#Minecraft server properties
#Mon May 01 13:27:49 CLT 2023
allow-flight=false
allow-nether=true
broadcast-console-to-ops=true
broadcast-rcon-to-ops=true
difficulty=easy
enable-command-block=false
enable-jmx-monitoring=false
enable-query=false
enable-rcon=false
enable-status=true
enforce-whitelist=false
entity-broadcast-range-percentage=100
force-gamemode=false
function-permission-level=2
gamemode=survival
generate-structures=true
generator-settings={}
hardcore=false
hide-online-players=false
level-name=world
level-seed=
level-type=default
max-players=20
max-tick-time=60000
max-world-size=29999984
motd=A Minecraft Server
network-compression-threshold=256
online-mode=true
op-permission-level=4
player-idle-timeout=0
prevent-proxy-connections=false
pvp=true
query.port=25565
rate-limit=0
rcon.password=
rcon.port=25575
require-resource-pack=false
resource-pack=
resource-pack-prompt=
resource-pack-sha1=
server-ip=
server-port=25565
simulation-distance=10
spawn-animals=true
spawn-monsters=true
spawn-npcs=true
spawn-protection=16
sync-chunk-writes=true
text-filtering-config=
use-native-transport=true
view-distance=10
white-list=false
"@
    $ruta_archivo_server_properties = Join-Path $ruta_carpeta_servidor "server.properties"
    Set-Content -Path $ruta_archivo_server_properties -Value $contenido_server_properties
}


function GenerarReadme {
    param (
        [string]$ruta_carpeta_servidor
    )

    $nombre_archivo_readme = "README.txt"
    $contenido_archivo_readme = @"
Instrucciones para iniciar el servidor:

1. Abre la carpeta del servidor.
2. Ejecuta el archivo 'Iniciar.bat' (Este puede aparecer solo como Iniciar).
3. El servidor se iniciará y se mostrará una ventana de línea de comandos.
4. Para detener el servidor, escribe 'stop' en la ventana de línea de comandos y presiona Enter.

NOTA: Asegúrate de tener instalado Java en tu computadora para que el servidor funcione correctamente.
"@
    $ruta_archivo_readme = Join-Path $ruta_carpeta_servidor $nombre_archivo_readme
    Set-Content -Path $ruta_archivo_readme -Value $contenido_archivo_readme
}

# Crear la carpeta del servidor en el escritorio
$carpeta_escritorio = [Environment]::GetFolderPath("Desktop")
$ruta_carpeta_servidor = Join-Path $carpeta_escritorio $Folder

if (-not (Test-Path $ruta_carpeta_servidor)) {
    New-Item -ItemType Directory -Path $ruta_carpeta_servidor | Out-Null
}

# Descarga el archivo del servidor
DescargarServidor -ruta_carpeta_servidor $ruta_carpeta_servidor -version $ServerVersion

# Crea los archivos de ejecución
CrearArchivosEjecucion -ruta_carpeta_servidor $ruta_carpeta_servidor -RAM $RAM

# Genera el archivo eula.txt
GenerarEula -ruta_carpeta_servidor $ruta_carpeta_servidor

# Genera el archivo server.properties
GenerarServerProperties -ruta_carpeta_servidor $ruta_carpeta_servidor

# Genera el archivo README.txt
GenerarReadme -ruta_carpeta_servidor $ruta_carpeta_servidor

