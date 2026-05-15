# +---------+------------------------------------------------------------------+
# | CONFIG  |                                                                  |
# +---------+------------------------------------------------------------------+

	# Espacio inicial requerido
    $FREESPACE_NO_CACHE = 10
    $FREESPACE_WITH_CACHE = 2

    # Disco de instalacion
    $DRIVE_TO_INSTALL = "C:"
	
	# vscode
    $VSCODE_HOME = "$DRIVE_TO_INSTALL\vscode"
	$VSCODE_WORKSPACE = "$VSCODE_HOME\Workspace"

    # Carpetas del usuario
    $DOWNLOAD_FOLDER = "$env:USERPROFILE\Downloads"
    $DESKTOP_FOLDER = "$env:USERPROFILE\Desktop"
    $USER_FOLDER = $env:USERPROFILE
    $CURRENT_FOLDER = "."

    # Donde voy a buscar el archivo
    $SEARCH_FOLDERS = @($DOWNLOAD_FOLDER, $DESKTOP_FOLDER, $CURRENT_FOLDER)
    
    # Raiz de los cache 
    $CACHE_ROOT = "$env:USERPROFILE\temp\.cache"
	$TOOLS_ROOT = "$env:USERPROFILE\temp\tools"


    # Url para descargar el archivo (apunta a manifest.json de desarrolo)
    $MANIFEST_URL = "https://drive.google.com/uc?export=download&id=1OdcuIkuy6Sd9km4GRwyKk8CTAqlooJt1"

# +---------+------------------------------------------------------------------+
# | CORE    | Console output                                                   |
# +---------+------------------------------------------------------------------+

function cMenu($options, $defaultIndex = 0,$timeoutSeconds = -1)
{
    if($NULL -eq $options -or $options.Count -eq 0)
    {
        return -1
    }

    $oldCursorVisible = [Console]::CursorVisible
    [Console]::CursorVisible = $false

    try
    {
        $index = $defaultIndex
        $maxLen = ($options | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum

        # reservar espacio para menu + timer
        for($i = 0; $i -lt ($options.Count + 1); $i++)
        {
            Write-Host ""
        }

        $top = [Console]::CursorTop - ($options.Count + 1)
        $startTime = Get-Date

        while($true)
        {
            for($i = 0; $i -lt $options.Count; $i++)
            {
                [Console]::SetCursorPosition(0, $top + $i)

                $text = $options[$i].PadRight($maxLen)

                if($i -eq $index)
                {
                    $line = " >[$text]"
                }
                else
                {
                    $line = "   $text "
                }

                Write-Host ($line.PadRight([Console]::WindowWidth - 1)) -NoNewline
            }

            [Console]::SetCursorPosition(0, $top + $options.Count)

            if($timeoutSeconds -ge 0)
            {
                $elapsed = ((Get-Date) - $startTime).TotalSeconds
                $remaining = [Math]::Ceiling($timeoutSeconds - $elapsed)

                if($remaining -lt 0)
                {
                    $remaining = 0
                }

                $timerLine = "Seleccion automatica en $remaining segundos..."
                Write-Host ($timerLine.PadRight([Console]::WindowWidth - 1)) -NoNewline

                if($elapsed -ge $timeoutSeconds)
                {
                    [Console]::SetCursorPosition(0, $top + $options.Count + 1)
                    Write-Host ""
                    return $index
                }
            }

            Start-Sleep -Milliseconds 100

            if([Console]::KeyAvailable)
            {
                $key = [Console]::ReadKey($true)

                switch($key.Key)
                {
                    "UpArrow"
                    {
                        if($index -gt 0)
                        {
                            $index--
                        }
                    }

                    "DownArrow"
                    {
                        if($index -lt ($options.Count - 1))
                        {
                            $index++
                        }
                    }

                    #"Enter"
                    #{
                    #    [Console]::SetCursorPosition(0, $top + $options.Count + 1)
                    #    #Write-Host " PEPINO"
                    #    return $index
                    #}
                    "Enter"
                    {
                        # Calculamos la posición donde termina el menú
                        $finalPos = $top + $options.Count
                        
                        # Subimos el cursor un lugar antes de salir
                        [Console]::SetCursorPosition(0, $finalPos)
                        
                        return $index
                    }
                }
            }
        }
    }
    finally
    {
        [Console]::CursorVisible = $oldCursorVisible
    }
}

function cBlink($message, $durationInMillis, $color = "white", $attr = "regular")
{
    $end = (Get-Date).AddMilliseconds($durationInMillis)

    while ((Get-Date) -lt $end)
    {
        Write-Host "`r$message" -ForegroundColor $color -NoNewline
        Start-Sleep -Milliseconds 400

        Write-Host "`r$(' ' * $message.Length)`r" -NoNewline
        Start-Sleep -Milliseconds 300
    }

#    Write-Host "`r$(' ' * $message.Length)`r" -NoNewline

    Write-Host "`r$message" -ForegroundColor $color
}

function cPause($millis=500)
{
    Start-Sleep -Milliseconds $millis    
}

function cStep($mssg,$delay=1000)
{
    Write-Host $mssg -ForegroundColor Cyan
    cPause $delay
}

function cAsk($mssg,$delay=500)
{
    Write-Host $mssg -ForegroundColor Magenta
    cPause $delay
}

function cError($mssg,$delay=1000)
{
    Write-Host $mssg -ForegroundColor Red
    cPause $delay
}

function cWarn($mssg,$delay=500)
{
    Write-Host $mssg -ForegroundColor Yellow
    cPause $delay
}

function cStep($mssg,$delay=1000)
{
    Write-Host $mssg -ForegroundColor Cyan
    cPause $delay
}

function cInfo($mssg,$delay=500)
{
    Write-Host $mssg -ForegroundColor Green
    cPause $delay
}

function cOut($mssg,$delay=500)
{
    Write-Host $mssg 
    cPause $delay
}

function pressAnyKey()
{
    cOut "Presione una tecla para continuar..." 
    [void][System.Console]::ReadKey($true)
}

# +---------+------------------------------------------------------------------+
# | CORE    | Folder                                                           |
# +---------+------------------------------------------------------------------+

function folderCreateStats($path)
{
    if(-not (folderExists $path))
    {
        return $false
    }

    $folderName = Split-Path $path -Leaf
    $statsFileName = "${folderName}_stats.json"
    $statsPath = Join-Path $path $statsFileName

    $files = Get-ChildItem -LiteralPath $path -Recurse -File | Where-Object { $_.FullName -ne $statsPath }

    $folders = Get-ChildItem -LiteralPath $path -Recurse -Directory

    $stats = @{
        fileCount   = $files.Count
        folderCount = $folders.Count
        totalSize   = ($files | Measure-Object -Property Length -Sum).Sum
    }

    $stats | ConvertTo-Json | Set-Content -LiteralPath $statsPath
    fileSetAttributes $statsPath "+h"
    return $true
}

function folderVerifyStats($path)
{
    if(-not (folderExists $path))
    {
        return $false
    }

    $folderName = Split-Path $path -Leaf
    $statsPath = Join-Path $path "${folderName}_stats.json"

    if(-not (fileExists $statsPath))
    {
        return $false
    }

    try
    {
        $savedStats = Get-Content -LiteralPath $statsPath -Raw | ConvertFrom-Json

        $files = Get-ChildItem -LiteralPath $path -Recurse -File |
                 Where-Object { $_.FullName -ne $statsPath }

        $folders = Get-ChildItem -LiteralPath $path -Recurse -Directory

        $currentFileCount   = $files.Count
        $currentFolderCount = $folders.Count
        $currentTotalSize   = ($files | Measure-Object -Property Length -Sum).Sum

        return (
            $savedStats.fileCount   -eq $currentFileCount   -and
            $savedStats.folderCount -eq $currentFolderCount -and
            $savedStats.totalSize   -eq $currentTotalSize
        )
    }
    catch
    {
        return $false
    }
}

function folderBackup($folderToZip, $zipFolder, $zipPrefix)
{
    if (folderExists $folderToZip)
    {
        $backupName = "${zipPrefix}_$(dateAsYYYYMMDD_HHMM).zip"
        $backupPath = "$zipFolder\$backupName"

        fileZip $folderToZip $backupPath | Out-Null

        return $backupName
    }

    return $null
}

function folderDelete($path)
{
    if (folderExists $path)
    {
        Remove-Item -LiteralPath $path -Recurse -Force
    }
}

function folderIsLocked($targetPath)
{
    if( -not (folderExists $targetPath) )
    {
        return $false
    }

    try 
    {
        # Genero un nombre temporal para probar el rename
        $tempPath = $targetPath + "_test_" + [guid]::NewGuid().ToString()

        # Intento renombrar la carpeta
        Rename-Item -Path $targetPath -NewName (Split-Path $tempPath -Leaf) -ErrorAction Stop

        # Si se pudo renombrar, la vuelvo a dejar con su nombre original
        Rename-Item -Path $tempPath -NewName (Split-Path $targetPath -Leaf) -ErrorAction Stop

        return $false
    }
    catch 
    {
        return $true
    }

}

function folderExists($path)
{
    return Test-Path -LiteralPath $path -PathType Container
}

function folderGetSubfolders($path)
{
    # -Force permite ver carpetas ocultas y de sistema
    return Get-ChildItem -LiteralPath $path -Directory -Force
}

# +---------+------------------------------------------------------------------+
# | CORE    | File                                                             |
# +---------+------------------------------------------------------------------+

function gdriveReadFileHeader($url)
{
    $response = Invoke-WebRequest `
        -Uri $url `
        -Method Head `
        -UseBasicParsing

    $cd = $response.Headers["Content-Disposition"]

    $name = $null
    if ($cd -match 'filename="(.+)"')
    {
        $name = $matches[1]
    }

    $dt = [datetime]::Parse($response.Headers["Last-Modified"])

    return @{
        name = $name
        date  = $dt.ToString("yyyy-MM-dd")
        hour   = $dt.ToString("HH:mm:ss")
        size   = [long]$response.Headers["Content-Length"]
    } | ConvertTo-Json
}

function fileCopy($filenameSource, $target)
{
    # Verifico que el origen exista
    if (-not (fileExists $filenameSource))
    {
        return $false
    }

    try 
    {
        # Si el target es una carpeta que ya existe
        if (folderExists $target)
        {
            # El destino final será la carpeta + el nombre del archivo original
            Copy-Item -LiteralPath $filenameSource -Destination $target -Force -ErrorAction Stop
        }
        else
        {
            # Si el target NO existe, verificamos si el directorio padre existe
            $parentDir = Split-Path $target -Parent
            
            # Si el target es solo un nombre de archivo en la ruta actual, parentDir será vacío
            if ($parentDir -and -not (folderExists $parentDir))
            {
                New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
            }

            # Copiamos asumiendo que target es la ruta completa del archivo nuevo
            Copy-Item -LiteralPath $filenameSource -Destination $target -Force -ErrorAction Stop
        }
        return $true
    }
    catch 
    {
        cError " --> Error al copiar: $($_.Exception.Message)"
        return $false
    }
}

function fileGetHash($file)
{
    if (Test-Path $file) 
    {
        # Algorithm MD5 
        return (Get-FileHash -LiteralPath $file -Algorithm MD5).Hash
    }

    return $null
}

function fileExists($path)
{
    return Test-Path -LiteralPath $path -PathType Leaf
}

function fileExists($path)
{
    return Test-Path -LiteralPath $path -PathType Leaf
}

function fileSearchOnFolders($fileName, $searchFolders)
{
    foreach ($folder in $searchFolders)
    {
        $path = "$folder\$fileName"

        if (fileExists $path)
        {
            return $folder
        }
    }

    return $null
}

function fileUnzip($zipPath, $dest, $cleanDestFolderIfExists=$true)
{
    if ($cleanDestFolderIfExists -and (folderExists $dest))
    {
        folderDelete $dest
    }

    # El parámetro -Force evita el error si el directorio ya existe
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    cmd /c attrib +h "$dest"

    try
    {
        Expand-Archive -LiteralPath $zipPath -DestinationPath $dest -Force
        return $true
    }
    catch
    {
        return $false
    }
}

function file7Unzip($zipPath, $dest, $szExe)
{
    if (folderExists $dest)
    {
        folderDelete $dest
    }

    New-Item -ItemType Directory -Path $dest | Out-Null
    cmd /c attrib +h "$dest"

    try
    {
        # x: eXtract con rutas completas
        # -o: Carpeta de destino (sin espacio entre -o y la ruta)
        # -y: Assume Yes a todo (overwrite) 
        & $szExe x "$zipPath" "-o$dest" -y -bsp1 | Where-Object { $_.trim() -ne "" } | Write-Host

        if ($LASTEXITCODE -eq 0) 
        {
            return $true
        }
        return $false
    }
    catch
    {
        return $false
    }
}

function fileZip($sourcePath, $zipPath)
{
    if (-not (Test-Path -LiteralPath $sourcePath))
    {
        return $false
    }

    $zipFolder = Split-Path $zipPath -Parent

    if ($zipFolder -and (-not (folderExists $zipFolder)))
    {
        New-Item -ItemType Directory -Path $zipFolder | Out-Null
    }

    try
    {
        if (fileExists $zipPath)
        {
            Remove-Item -LiteralPath $zipPath -Force
        }

        Compress-Archive -LiteralPath $sourcePath -DestinationPath $zipPath -Force
        return $true
    }
    catch
    {
        return $false
    }
}

function fileSetAttributes($path, $attributes)
{
    if (Test-Path -LiteralPath $path)
    {
        cmd /c attrib $attributes "$path"
    }
}

# +---------+------------------------------------------------------------------+
# | CORE    | Drive                                                            |
# +---------+------------------------------------------------------------------+

function driveGetFreeSpace($drive)
{
    $driveName = $drive.Replace(":", "")
    $d = Get-PSDrive -Name $driveName
    return [math]::Floor($d.Free / 1GB)
}

# +---------+------------------------------------------------------------------+
# | CORE | Date & Time                                                            |
# +---------+------------------------------------------------------------------+

function dateAsYYYYMMDD_HHMM()
{
    return Get-Date -Format "yyyy-MM-dd_HHmm"
}

# +---------+------------------------------------------------------------------+
# | NO CORE | Cache                                                            |
# +---------+------------------------------------------------------------------+

function cacheCrear($zipPath, $cacheRoot, $cacheExpanded, $cacheFolder, $exe7z)
{
    $okUnzip = $false
    
    if ($null -ne $exe7z -and (Test-Path $exe7z))
    {
        cInfo " --> Iniciando extraccion con 7-Zip..."
        $okUnzip = file7Unzip $zipPath $cacheExpanded $exe7z
    }
    else
    {
        cInfo " --> Iniciando extraccion con el motor del sistema."
        $okUnzip = fileUnzip $zipPath $cacheExpanded
    }

    if (-not $okUnzip)
    {
        cError " --> No se pudo extraer el contenido de $zipPath."
        pressAnyKey
        exit
    }

    # 2. SE OCULTA LA RAÍZ DEL CACHÉ
    fileSetAttributes $cacheRoot "+h"

    folderCreateStats $cacheExpanded | Out-Null
    fileSetAttributes $cacheExpanded "+h"
    cInfo " --> Cache generado correctamente."
}

function cacheRestaurar($source, $dest)
{
    cInfo " --> Sincronizando archivos."
    cBlink " --> Esta accion podria demorar unos minutos." 2000
    $source = (Resolve-Path $source).Path

    if (!(Test-Path -LiteralPath $dest))
    {
        New-Item -ItemType Directory -Path $dest | Out-Null
    }

    # --- CREAR DIRECTORIOS FALTANTES ---
    $dirs = Get-ChildItem -LiteralPath $source -Recurse -Directory
    foreach ($dir in $dirs)
    {
        $relative  = $dir.FullName.Replace($source, "").TrimStart('\')
        $targetDir = Join-Path $dest $relative

        if (!(Test-Path -LiteralPath $targetDir))
        {
            New-Item -ItemType Directory -Path $targetDir | Out-Null
        }
    }

    # --- AGREGAR / RECUPERAR ARCHIVOS ---
    $files = Get-ChildItem -LiteralPath $source -Recurse -File

    foreach ($file in $files)
    {
        $relative = $file.FullName.Replace($source, "").TrimStart('\')
        $target   = Join-Path $dest $relative

        $targetDir = Split-Path $target
        if (!(Test-Path -LiteralPath $targetDir))
        {
            New-Item -ItemType Directory -Path $targetDir | Out-Null
        }

        $copiar = $true
        $accion = "agregado"

        if (Test-Path -LiteralPath $target)
        {
            $destFile = Get-Item -LiteralPath $target
            $accion = "recuperado"

            if ($destFile.Length -eq $file.Length)
            {
                if ($destFile.LastWriteTime -eq $file.LastWriteTime)
                {
                    $copiar = $false
                }
                else
                {
                    $h1 = (Get-FileHash -LiteralPath $file.FullName).Hash
                    $h2 = (Get-FileHash -LiteralPath $target).Hash

                    if ($h1 -eq $h2)
                    {
                        $copiar = $false
                    }
                }
            }
        }

        if ($copiar)
        {
            Copy-Item -LiteralPath $file.FullName -Destination $target -Force
            Write-Host "  -> $relative $accion." -ForegroundColor Yellow
        }
    }

    # --- ELIMINAR ARCHIVOS SOBRANTES ---
    $destFiles = Get-ChildItem -LiteralPath $dest -Recurse -File

    foreach ($d in $destFiles)
    {
        $relative = $d.FullName.Replace($dest, "").TrimStart('\')
        $srcFile  = Join-Path $source $relative

        if (!(Test-Path -LiteralPath $srcFile))
        {
            Remove-Item -LiteralPath $d.FullName -Force
            Write-Host "  -> $relative eliminado." -ForegroundColor Yellow
        }
    }

    # --- ELIMINAR DIRECTORIOS SOBRANTES ---
    $destDirs = Get-ChildItem -LiteralPath $dest -Recurse -Directory | Sort-Object FullName -Descending

    foreach ($d in $destDirs)
    {
        $relative = $d.FullName.Replace($dest, "").TrimStart('\')
        $srcDir   = Join-Path $source $relative

        if (!(Test-Path -LiteralPath $srcDir))
        {
            Remove-Item -LiteralPath $d.FullName -Recurse -Force
            Write-Host "  -> $relative eliminado." -ForegroundColor Yellow
        }
    }

    cInfo " --> Sincronizacion finalizada."
}

# +---------+------------------------------------------------------------------+
# | NO CORE | VSCode                                                           |
# +---------+------------------------------------------------------------------+

#function vscodeObtenerManifest($manifestUrl)
#{
#    try {
#        $response = Invoke-WebRequest -Uri $manifestUrl -UseBasicParsing
#        $json = $response.Content | ConvertFrom-Json
#        
#        if($NULL -eq $($json.active_env)) 
#        { 
#            return $NULL 
#        }
#        return $json
#    }
#    catch 
#    {
#        return $NULL
#    }
#}

function vscodeObtenerManifest($manifestUrl)
{
    try 
    {
        $response = Invoke-WebRequest -Uri $manifestUrl -UseBasicParsing
        $content = $response.Content

        # Manejo de encoding para evitar caracteres rotos
        if($content -is [byte[]]) 
        {
            $content = [System.Text.Encoding]::UTF8.GetString($content)
        }

        $json = $content | ConvertFrom-Json
        
        # Validación directa sin subexpresiones
        if($null -eq $json.active_env) 
        { 
            return $null 
        }

        return $json
    }
    catch 
    {
        return $null
    }
}

function vscodeObtenerVersionLocal($cacheRoot)
{
    cStep "Verificando existencia de cache local."
    
    # si no existe el root retorno null
    if(-not (folderExists $cacheRoot))
    {
        cWarn " --> No se encontro cache local."
        return $NULL
    }

    # pido las carpetas hijas directas
    $folders = folderGetSubfolders "$cacheRoot\"

    # debe existir exactamente una carpeta
    if($folders.Count -ne 1)
    {
        cWarn " --> Cache local invalido."
        return $NULL
    }

    # LA carpeta que tiene el cache
    $folder = $folders[0]

    # verifico integridad del cache
    $cacheOk = folderVerifyStats $folder.FullName

    if(-not $cacheOk)
    {
        cWarn " --> El cache local esta corrupto."
        return $NULL
    }

    cInfo " --> Cache encontrado: $($folder.Name)."
    return $folder.Name
}

function vscodeActualizarORestaurarVersion($localVer,$remoteVer)
{
    cAsk "Desea restaurar $localVer o actualizar a $($remoteVer)?"
    $options = @("Restaurar","Actualizar")
    $op = cMenu $options 0
    return $op
}

function vscodeDescargar($url,$downloadFolder,$fileName,$md5)
{
    downloadAbrirNavegador $url
    downloadEsperarDescarga "$downloadFolder\$fileName"

    # verifico que exista en downloads
    if (-not (fileExists "$downloadFolder\$fileName"))
    {
        cError " --> No se encontro $fileName en: $downloadFolder." 500
        cError " --> Verifique la descarga y vuelva a ejecutar el script."
        pressAnyKey
        exit
    }

    # verifico el hash
    $hash = fileGetHash "$downloadFolder\$fileName"
    if( $hash.ToUpper() -ne $md5.ToUpper() )    
    {
        cError " --> $fileName no se descargo correctamente." 500      
        cError " --> Vuelva a ejecutar el script."
        pressAnyKey
        exit
    }
}

# +---------+------------------------------------------------------------------+
# | NO CORE | Download                                                            |
# +---------+------------------------------------------------------------------+

function downloadFromGoogleDrive($url, $OutFile)
{
    $dir = Split-Path -Parent $OutFile
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    
    curl.exe -s -L $url -o $OutFile
}

function downloadEsperarDescarga($zipPath)
{
    cOut " --> Esperando descarga del archivo..."

    while (-not (fileExists $zipPath))
    {
        Start-Sleep -Seconds 1
    }

    cInfo " --> Archivo detectado. Esperando finalizacion de la descarga..."

    $tamanoAnterior = -1
    while ($true)
    {
        Start-Sleep -Seconds 2
        $tamanoActual = (Get-Item -LiteralPath $zipPath).Length

        if ($tamanoActual -eq $tamanoAnterior)
        {
            break
        }

        $tamanoAnterior = $tamanoActual
    }

    cInfo " --> Descarga finalizada: $zipPath."
}

function downloadAbrirNavegador($url)
{
    cInfo  " --> Se abrira el navegador para descargar el archivo."
    cBlink " --> IMPORTANTE: NO CIERRE ESTA VENTANA." 2000
    cOut   " --> Se reanudara solo al detectar el archivo."
    cAsk  " --> Presione [ENTER] para descargar..." 

    do {
        $k = [System.Console]::ReadKey($true)
    } while ($k.Key -ne [System.ConsoleKey]::Enter)

    Start-Process $url
}

# +---------+------------------------------------------------------------------+
# | Main                                                                       |
# +---------+------------------------------------------------------------------+

function mainRestaurar($cacheFolder,$vscodeHome,$vscodeWorkspace,$userFolder)
{
    if( folderExists $vscodeHome )
    {
        cStep "Creando respaldo de archivos del usuario."
        $bkpName = folderBackup $vscodeWorkspace $userFolder "workspaceBkp"
        cInfo " --> Respaldo creado en: $userFolder\$bkpName."
    }

    cStep "Restaurando VSCode desde cache."
    cacheRestaurar $cacheFolder $vscodeHome

    # autocopiado y lnk
    mainAutocopiarScript $USER_FOLDER $VSCODE_HOME

    # ejecuto y verifico que todo salio bien
    Start-Process "$VSCODE_HOME\RunVSCode.bat"
}

function mainCrearRestaurar($zipPath,$cacheRoot,$cacheExpanded,$cacheFolder,$vscodeHome,$vscodeWorkspace,$userFolder,$exe7z)
{
    #voy a crear un cache, borro los viejos
    folderDelete $cacheRoot

    cStep "Creando cache de VSCode."
    cacheCrear $zipPath $cacheRoot $cacheExpanded $cacheFolder $exe7z

    # borro el home porque no puedo saber a qué versión corresponde 
    folderDelete $vscodeHome

    # invoco a restaurar
    mainRestaurar $cacheFolder $vscodeHome $vscodeWorkspace $userFolder
}

function mainDescargarCrearRestaurar($url,$downloadFolder,$remoteVer,$remoteMD5,$cacheRoot,$vscodeHome,$vscodeWorkspace,$userFolder,$exe7z)
{
    # antes de descargar veo si ya tengo descargada última versión
    $filePath  = fileSearchOnFolders $remoteVer $SEARCH_FOLDERS

    if( $null -eq $filePath )
    {
        # no lo tiene => descargo
        cStep "Se requiere descargar VSCode."
        vscodeDescargar $url $downloadFolder $remoteVer $remoteMD5
        $filePath = $downloadFolder
    }
    else
    {
        cStep "Version $remoteVer encontrada en: $filePath."    
    }

    # descomprimo y genero el header
    $zipPath = "$filePath\$remoteVer"
    $cacheExpanded = "$cacheRoot\$remoteVer"
    $cacheFolder = "$cacheExpanded\vscode"

    # invoco a crearYRestaurar
    mainCrearRestaurar $zipPath $cacheRoot $cacheExpanded $cacheFolder $vscodeHome $vscodeWorkspace $userFolder $exe7z
}

function mainAsegurarCondicionesInicial($drive,$minSize,$vscodeHome)
{
    cStep "Verificando requerimientos."

    # espacio disponible
    $freeSpace = driveGetFreeSpace $drive

    if( $freeSpace -lt $minSize )
    {
        cError " --> Se requieren, al menos, ${minSize}GB libres en:$drive ($freeSpace)."
        pressAnyKey
        exit
    }

    # vscodeHome no debe estar locked
    if (folderIsLocked $vscodeHome)
    {
        cError " --> La carpeta $vscodeHome esta en uso. No se puede continuar."
        pressAnyKey
        exit
    }

    cInfo " --> El equipo cumple los requisitos."
}

function mainBuscarZipLocal($fileName,$md5,$SEARCH_FOLDERS)
{
    cStep "Buscando archivo: $fileName."
    $encontradoEn = fileSearchOnFolders $fileName $SEARCH_FOLDERS

    if( $null -eq $encontradoEn )
    {
        cWarn " --> Archivo no encontrado."
        return $null
    }

    # verifico el hash
    $hash = fileGetHash "$encontradoEn\$fileName"
    if( $hash.ToUpper() -ne $md5.ToUpper() )    
    {
        cError " --> El archivo $encontradoEn\$fileName esta corrupto."
        return $null
    }

    cInfo " --> Archivo encontrado en: $encontradoEn."
    return $encontradoEn
}


function mainObtener7z($toolsRoot, $szConfig) 
{
    $exePath = Join-Path $toolsRoot $szConfig.exeName
    $zipPath = Join-Path $toolsRoot $szConfig.zipName

    # 1. Si el exe ya existe, asumimos integridad (o chequeamos contra un hash del exe si existiera)
    if (Test-Path $exePath) 
    {
        return $exePath
    }

    # 2. Intento de descarga
    downloadFromGoogleDrive $szConfig.url $zipPath

    $ret = $null
    if (Test-Path $zipPath) 
    {
        # Validar ANTES de descomprimir
        $hash = fileGetHash $zipPath
        if ($hash -eq $szConfig.md5) 
        {
            # Descomprimir sólo si el hash coincide
            if (fileUnzip $zipPath $toolsRoot $false) 
            {
                $ret = $exePath
            }
        }
        else 
        {
            cError " --> Error de integridad: el MD5 del ZIP no coincide."
        }

        Remove-Item $zipPath -Force
    }

    return $ret
}

function vscodeVerificarActualizaciones($manifest, $localVer)
{    
    cStep "Buscando actualizaciones."
    if ($null -eq $manifest)
    {
        if ($null -eq $localVer)
        {
            # sin cache y sin manifest no puedo continuar
            cError " --> No hay informacion de descargas disponibles."
            pressAnyKey
            exit
        }

        # hay cache local pero no hay manifest
        cError " --> No fue posible verificar actualizaciones."
        return
    }

    # HAY MANIFEST
    # entorno activo: prod o test?
    $envName = $($manifest.active_env) 
    $remoteVer = $manifest.environments.$envName.version

    if ($null -ne $localVer)
    {
        if ($remoteVer -eq $localVer)
        {
            # cache = remoteVer => actualizado
            cInfo " --> No hay nuevas actualizaciones. Version actual: $localVer."
        }
        else
        {
            # hay actualizaciones
            cInfo " --> Actualizacion disponible: $localVer -> $remoteVer."
        }
    }
    else
    {
        cInfo " --> $remoteVer esta disponible para ser descargado."
    }
}

function mainAutocopiarScript($targetFolder, $targetLnk)
{
    cStep "Creando respaldo y acceso directo."
    $fullfileName = $PSCommandPath

    # 0. VALIDACIÓN CRUCIAL: ¿Ya nos estamos ejecutando desde la carpeta de destino?
    $currentFolder = Split-Path $fullfileName -Parent
    
    # Resolvemos rutas completas por si se usaron rutas relativas
    $resolvedTarget = (Resolve-Path $targetFolder -ErrorAction SilentlyContinue).Path
    if ($null -eq $resolvedTarget) { $resolvedTarget = $targetFolder }

    if ($currentFolder -eq $resolvedTarget)
    {
        return # Salimos de la función sin romper nada
    }

    try 
    {
        # 1. Copiar el script a la carpeta destino
        cInfo "Backup: $fullfileName."
        
        # [SOLUCIÓN AL TRUE]: Casteamos a [void] o asignamos a $null para que no escupa "True" en consola
        [void](fileCopy $fullfileName $targetFolder)

        # 2. Calcular la ruta del nuevo script copiado
        $scriptName = [System.IO.Path]::GetFileName($fullfileName)
        $copiedScriptPath = Join-Path $targetFolder $scriptName

        # [SOLUCIÓN AL LNK]: Si $targetLnk es una carpeta, le armamos el archivo .lnk adentro
        if ((Test-Path $targetLnk -PathType Container) -or $targetLnk -notlike "*.lnk") 
        {
            # Sacamos el nombre sin extensión (ej: install-vscode_v1.5) y le ponemos .lnk
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fullfileName)
            $shortcutFullPath = Join-Path $targetLnk "$baseName.lnk"
        } 
        else 
        {
            $shortcutFullPath = $targetLnk
        }

        # 3. Crear el acceso directo (.lnk) real
        cInfo "--> Acceso directo en: $shortcutFullPath"
        
        $wshShell = New-Object -ComObject WScript.Shell
        $shortcut = $wshShell.CreateShortcut($shortcutFullPath)
        
        $shortcut.TargetPath = "powershell.exe"
        $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$copiedScriptPath`""
        $shortcut.WorkingDirectory = $targetFolder
        $shortcut.Description = "Instalador y Sincronizador de VSCode"
        
        $shortcut.Save()
        
        cInfo "Proceso de copiado y acceso directo finalizado con exito."
    }
    catch 
    {
        cError "No se pudo crear el acceso directo: $_"
    }
}

function main()
{
    # veo qué versión local tengo instalada (si la tengo)
    $localVer  = vscodeObtenerVersionLocal $CACHE_ROOT

    #ASSERT
    # verifico condiciones iniciales: lock y size
    $sizeReq = if ($null -ne $localVer) { $FREESPACE_WITH_CACHE } else { $FREESPACE_NO_CACHE } 
    mainAsegurarCondicionesInicial $DRIVE_TO_INSTALL $sizeReq $VSCODE_HOME

    # leo el manifest 
    $manifest = vscodeObtenerManifest $MANIFEST_URL   

    # informo sobre las posibles actualizaciones
    vscodeVerificarActualizaciones $manifest $localVer
    
    # selecciono el entorno dinámicamente (prod o test)
    $envConfig = $manifest.environments.$($($manifest.active_env))
    $remoteVer = $envConfig.version
    $remoteUrl = $envConfig.url
    $remoteMD5 = $envConfig.md5

    # hay cache y es la última versión 
    if($NULL -ne $localVer -and $localVer -eq $remoteVer) 
    {
        # restauro cache
        $cacheExpanded = "$CACHE_ROOT\$localVer"
        $cacheFolder = "$cacheExpanded\vscode"
        mainRestaurar $cacheFolder $VSCODE_HOME $VSCODE_WORKSPACE $USER_FOLDER
        return
    }

    # hay cache, pero es viejo, y hay actualización
    if($NULL -ne $localVer -and $NULL -ne $remoteVer -and $localVer -ne $remoteVer)
    {
        # pregunto si desea restaurar (0) o actualizar (1)
        $op = vscodeActualizarORestaurarVersion $localVer $remoteVer
        if( $op -eq 0 )
        {
            # NO -> restauro versión local
            $cacheExpanded = "$CACHE_ROOT\$localVer"
            $cacheFolder = "$cacheExpanded\vscode"
            mainRestaurar $cacheFolder $VSCODE_HOME  $VSCODE_WORKSPACE $USER_FOLDER
        }
        else
        {
            # SI -> descargar, crear y restaurar
            mainDescargarCrearRestaurar $remoteUrl $DOWNLOAD_FOLDER $remoteVer $remoteMD5 $CACHE_ROOT $VSCODE_HOME $VSCODE_WORKSPACE $USER_FOLDER
        }

        return
    }

    # hay cache, pero no hay manifest
    if($NULL -ne $localVer -and $NULL -eq $remoteVer)
    {
        # Restauro versión local
        $cacheExpanded = "$CACHE_ROOT\$localVer"
        $cacheFolder = "$cacheExpanded\vscode"
        mainRestaurar $cacheFolder $VSCODE_HOME  $VSCODE_WORKSPACE $USER_FOLDER
        return
    }


    # Desde aquí NO HAY CACHE => necesito dezippear.
    # Veo si puedo disponer de 7z (mucho más rápido).
    $exe7z = mainObtener7z $TOOLS_ROOT $manifest.tools.sevenZip 

    # veo si tengo el .zip de la última versión
    # descargada, y asegurando que no está corrupta
    $filePath = mainBuscarZipLocal $remoteVer $remoteMD5 $SEARCH_FOLDERS

    # no hay cache, pero ya tengo el zip latest
    if($NULL -eq $localVer -and $NULL -ne $filePath)
    {
        # creo y restauro el cache
        $cacheExpanded = "$CACHE_ROOT\$remoteVer"
        $cacheFolder = "$cacheExpanded\vscode"
        $zipPath = "$filePath\$remoteVer"

        mainCrearRestaurar $zipPath $CACHE_ROOT $cacheExpanded $cacheFolder $VSCODE_HOME $VSCODE_WORKSPACE $USER_FOLDER $exe7z

        return
    }

    # no hay cache ni zip latest
    if($NULL -eq $localVer -and $NULL -eq $filePath)
    {
        # descargo, creo y restauro cache
        mainDescargarCrearRestaurar $remoteUrl $DOWNLOAD_FOLDER $remoteVer $remoteMD5 $CACHE_ROOT $VSCODE_HOME $VSCODE_WORKSPACE $USER_FOLDER $exe7z
        return
    }
}

# LLAMO A MAIN
main
