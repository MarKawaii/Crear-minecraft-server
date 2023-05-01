Add-Type -AssemblyName PresentationFramework

$xaml = Get-Content -Path 'view\index.xaml' | Out-String
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$form = [Windows.Markup.XamlReader]::Load( $reader )

$form.ShowDialog() | Out-Null

$nombreCarpeta = $form.txtNombreCarpeta.Text
$numeroPuerto = $form.txtNumeroPuerto.Text

if ([string]::IsNullOrWhiteSpace($nombreCarpeta)) {
    Write-Host "El nombre de la carpeta no puede estar vacío."
    return
}

# Crear la carpeta
New-Item -ItemType Directory -Path $nombreCarpeta

# Crear el archivo de configuración
$configuracion = @"
server-port=$numeroPuerto
"@
Set-Content -Path "$nombreCarpeta\server.properties" -Value $configuracion

Write-Host "Servidor creado exitosamente en la carpeta $nombreCarpeta con el puerto $numeroPuerto"
