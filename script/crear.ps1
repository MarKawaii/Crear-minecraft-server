param (
    [string]$Folder
)

function DescargarServidor {
    param (
        [string]$ruta_carpeta_servidor
    )

    $url = "https://launcher.mojang.com/v1/objects/1b557e7b033b583cd9f66746b7a9ab1ec1673ced/server.jar"
    $archivo_servidor = "minecraft_server.jar"

    Write-Host "Descargando el archivo del servidor de Minecraft..."

    try {
        $client = New-Object System.Net.WebClient
        $ruta_archivo_servidor = Join-Path $ruta_carpeta_servidor $archivo_servidor
        $client.DownloadFile($url, $ruta_archivo_servidor)
        Write-Host "Archivo del servidor descargado correctamente."
    } catch {
        Write-Error "Error al descargar el archivo del servidor: $_"
        exit 1
    }
}

function CrearArchivosEjecucion {
    param (
        [string]$ruta_carpeta_servidor
    )

    $nombre_archivo_ps1 = "script.ps1"
    $contenido_archivo_ps1 = @"
Set-Location '$ruta_carpeta_servidor'
java -Xmx1024M -Xms1024M -jar minecraft_server.jar nogui
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
DescargarServidor -ruta_carpeta_servidor $ruta_carpeta_servidor

# Crea los archivos de ejecución
CrearArchivosEjecucion -ruta_carpeta_servidor $ruta_carpeta_servidor

# Genera el archivo eula.txt
GenerarEula -ruta_carpeta_servidor $ruta_carpeta_servidor

# Genera el archivo README.txt
GenerarReadme -ruta_carpeta_servidor $ruta_carpeta_servidor

