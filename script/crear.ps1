param (
    [string]$Folder,
    [string]$ServerVersion,
    [int]$RAM = 1024 # Establece un valor predeterminado de 1024 MB de RAM
)

$IPv4 = (Test-Connection -ComputerName (hostname) -Count 1).IPv4Address.IPAddressToString
$ServerIP = $IPv4


    $BackgroundColor = "DarkBlue" # Cambie este valor para establecer el color de fondo.
    $ForegroundColor = "White" # Cambie este valor para establecer el color del texto.
    $Message = "Informacion"

    $WindowWidth = (Get-Host).UI.RawUI.WindowSize.Width
    $MessageLength = $Message.Length
    $Padding = ($WindowWidth - $MessageLength) / 2
    $PaddedMessage = $Message.PadLeft($Padding + $MessageLength).PadRight($WindowWidth)

    Write-Host $PaddedMessage -BackgroundColor $BackgroundColor -ForegroundColor $ForegroundColor

    Write-Host "Nombre de la carpeta: $Folder"
    Write-Host "Ip: $ServerIP"
    Write-Host "Cantidad de ram asignada: $RAM"
    Write-Host "version del servidor: $ServerVersion"
    

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
        [string]$ruta_carpeta_servidor,
        [string]$IP
    )

    $ruta_archivo_server_properties = Join-Path $ruta_carpeta_servidor "server.properties"

    if (Test-Path $ruta_archivo_server_properties) {
        $contenido_actual = Get-Content -Path $ruta_archivo_server_properties
        $nuevo_contenido = @()

        foreach ($linea in $contenido_actual) {
            if ($linea.StartsWith("server-ip=")) {
                $nuevo_contenido += "server-ip=$IP"
            }
            else {
                $nuevo_contenido += $linea
            }
        }

        Set-Content -Path $ruta_archivo_server_properties -Value $nuevo_contenido
    }
    else {
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
        server-ip=$ServerIP
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
        Set-Content -Path $ruta_archivo_server_properties -Value $contenido_server_properties
    }
}



function GenerarReadme {
    param (
        [string]$ruta_carpeta_servidor
    )

    $nombre_archivo_readme = "README.txt"
    $contenido_archivo_readme = @"
# Servidor de Minecraft

Este servidor de Minecraft ha sido creado utilizando un script de PowerShell. A continuación, se detallan las instrucciones para iniciar, detener y compartir el servidor con otros usuarios.

## Iniciar el servidor

1. Asegúrate de tener instalado Java en tu computadora.
2. Abre la carpeta del servidor.
3. Ejecuta el archivo 'Iniciar.bat' (Este puede aparecer solo como Iniciar).
4. El servidor se iniciará y se mostrará una ventana de línea de comandos.

## Detener el servidor

1. En la ventana de línea de comandos del servidor, escribe 'stop' y presiona Enter.
2. El servidor se detendrá y la ventana de línea de comandos se cerrará.

## Compartir el servidor con otros usuarios

1. Asegúrate de que tu servidor esté en línea siguiendo las instrucciones de "Iniciar el servidor".
2. Abre el archivo 'server.properties' en la carpeta del servidor con un editor de texto.
3. Busca la línea que comienza con "server-ip=" y anota la dirección IP que aparece a continuación. Esta es la dirección IP de tu servidor.
4. Comparte esta dirección IP con los usuarios que quieras que se unan al servidor. Deberán agregar esta dirección IP en la sección "Multijugador" del juego de Minecraft.
5. Si es necesario, asegúrate de que los puertos del servidor estén abiertos en el firewall de tu computadora y en el enrutador para permitir conexiones externas.

## Nota

Este README y el servidor asociado fueron creados utilizando un script de PowerShell en un entorno específico. Si encuentras problemas al ejecutar el servidor o al compartirlo con otros usuarios, verifica que hayas seguido correctamente las instrucciones proporcionadas y que cumplas con los requisitos del sistema. Consulta la documentación oficial de Minecraft o busca soporte en línea si sigues teniendo problemas.

-----------------------------------------------------------------------------------------------------------

Servidor de Minecraft - Lista de comandos
Este archivo README contiene una lista de comandos útiles que puedes utilizar en la consola del servidor de Minecraft. Para usar un comando, simplemente escribe el comando en la ventana de la línea de comandos del servidor y presiona Enter.

Comandos generales
help: Muestra una lista de comandos disponibles y su descripción.
list: Muestra la lista de jugadores conectados al servidor.
stop: Detiene el servidor de Minecraft de forma segura, guardando el mundo antes de cerrarse.

Comandos de administración de jugadores
op <nombre_de_usuario>: Otorga privilegios de operador (administrador) a un jugador.
deop <nombre_de_usuario>: Quita los privilegios de operador de un jugador.
kick <nombre_de_usuario>: Expulsa a un jugador del servidor.
ban <nombre_de_usuario>: Prohíbe el acceso de un jugador al servidor.
pardon <nombre_de_usuario>: Elimina la prohibición de un jugador previamente baneado.
ban-ip <dirección_IP>: Prohíbe el acceso al servidor desde una dirección IP específica.
pardon-ip <dirección_IP>: Elimina la prohibición de una dirección IP previamente baneada.
whitelist add <nombre_de_usuario>: Agrega a un jugador a la lista blanca, permitiéndole conectarse al servidor.
whitelist remove <nombre_de_usuario>: Elimina a un jugador de la lista blanca.
whitelist list: Muestra la lista de jugadores en la lista blanca.
whitelist on: Activa la lista blanca.
whitelist off: Desactiva la lista blanca.

Comandos de gestión del mundo
save-all: Guarda todos los mundos y las configuraciones del servidor.
save-on: Habilita el guardado automático del mundo (activado por defecto).
save-off: Deshabilita el guardado automático del mundo.
time set <tiempo>: Establece la hora del mundo. <tiempo> puede ser day, night, dawn, dusk, o un número que represente el tiempo en ticks.
gamerule <regla> <valor>: Cambia el valor de una regla de juego. Por ejemplo, gamerule doDaylightCycle false detiene el ciclo día-noche.
tp <nombre_de_usuario> <x> <y> <z>: Teletransporta a un jugador a las coordenadas especificadas.
weather <clima>: Cambia el clima del mundo. <clima> puede ser clear, rain, o thunder.

Esta es solo una lista básica de comandos para la consola del servidor de Minecraft. Puedes encontrar más comandos y detalles en la documentación oficial de Minecraft.

"@
    $ruta_archivo_readme = Join-Path $ruta_carpeta_servidor $nombre_archivo_readme
    Set-Content -Path $ruta_archivo_readme -Value $contenido_archivo_readme

    $BackgroundColor = "DarkGreen" # Cambie este valor para establecer el color de fondo.
    $ForegroundColor = "White" # Cambie este valor para establecer el color del texto.
    $Message = "Creacion Completada"

    $WindowWidth = (Get-Host).UI.RawUI.WindowSize.Width
    $MessageLength = $Message.Length
    $Padding = ($WindowWidth - $MessageLength) / 2
    $PaddedMessage = $Message.PadLeft($Padding + $MessageLength).PadRight($WindowWidth)

    Write-Host $PaddedMessage -BackgroundColor $BackgroundColor -ForegroundColor $ForegroundColor


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
GenerarServerProperties -ruta_carpeta_servidor $ruta_carpeta_servidor -IP $IP

# Genera el archivo README.txt
GenerarReadme -ruta_carpeta_servidor $ruta_carpeta_servidor

