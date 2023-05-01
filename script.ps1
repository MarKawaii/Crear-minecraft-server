# Cargar las ensamblados de WPF
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# Importar el archivo XAML
[xml]$xaml = Get-Content -Path ".\view\index.xaml"

# Crear un objeto de ventana
$window = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $xaml))

# Obtener elementos de la ventana
$submitButton = $window.FindName("SubmitButton")
$folderInput = $window.FindName("FolderInput")
$versionInput = $window.FindName("VersionInput")
$RAMInput = $window.FindName("RAMInput") # Añade esta línea

# Función para manejar el evento de clic del botón
$submitButton.Add_Click({
    $folderName = $folderInput.Text
    $version = $versionInput.Text
    $RAM = $RAMInput.Text # Añade esta línea

    if (-not ([string]::IsNullOrEmpty($folderName)) -and -not ([string]::IsNullOrEmpty($version)) -and -not ([string]::IsNullOrEmpty($RAM))) { # Modifica esta línea
        & ".\script\crear.ps1" -Folder $folderName -ServerVersion $version -RAM $RAM # Modifica esta línea
        $window.Close()
    } else {
        [System.Windows.MessageBox]::Show("Por favor, complete todos los campos.")
    }
})

# Mostrar la ventana
$window.ShowDialog() | Out-Null
