# reusable calls

# Extracts zip archives
Function Unzip(
    [string]$PathToArchive
) {
    
    Expand-Archive -LiteralPath $PathToArchive -ErrorAction SilentlyContinue -ErrorVariable Err

    If (!$Err) {
        Write-Progress -Activity "Unzipping archives.." -Status "📦 Archives unzipped."
    }
    else {
        Write-Debug -Message "Failed to unzip $PathToArchive using `Expand-Archive` call."
        $Err | Out-File "$PWD/font-download-error.log" ;
        Write-Debug -Message "Wrote the error message in file $PWD/font-download-error.log"
    }
        
} ;





function FilterArray(
    [string[]]$Data,
    [string[]]$Excludes
) {
    $Data | ForEach-Object { if ($_ -notin $Excludes ) { $_ } }    
} ;

## Main procedural code
# storing all that in arrays:

Function DownloadFontZip(
    [pscustomobject]$font
) {
    # Parameter help description
    
    $uri = New-Object System.Uri $font.Uri
    $zipName = "$($font.Name).zip"
    $zipPath = "$PWD\$zipName"
    $response = Invoke-RestMethod -Method GET -OutFile $zipPath -Uri $Uri -ErrorAction SilentlyContinue -ErrorVariable Err
        
    if (!$Err) {
        Write-Progress  -Activity "Downloading Nerd Fonts with Ligatures" -Status "✅ Font archive downloaded."
        $zipPath ;
    }
    else {
        Write-Debug -Message "Could not get zip from URL, response: `n$response"
    }

    $Exists = $($(Test-Path $zipPath) -and $($( Get-Item $zipPath).Length > 0))

    $Exists
        
} ;

function Main {

    # remove the local dependency to make it portable, it requires an internet connection anyway
    # $FullData = Get-Content -Raw ".\Ligatured-Fonts-List.json" | ConvertFrom-Json ;
    $GistHostedJSON = "https://gist.githubusercontent.com/arnos-stuff/70f9397835154bef4e186899aa36da20/raw/ca0b02641f377c7663ef592817e9b92fa8146c30/Ligatured-Fonts-List.json"

    $Selected = $(Invoke-RestMethod $GistHostedJSON).SyncRoot | Out-GridView -Title "Select only the fonts you wish to install, and then click OK" -OutputMode Multiple


    Write-Progress -Activity "This installer will download the specified $($Selected.Length) / $($FullData.Length) fonts" -Status "Starting.."

    Write-Progress -Activity "Downloading Nerd Fonts with Ligatures" -Status "Starting.." -PercentComplete 0

    $NumFonts = [double]::Parse($Selected.Length);
    $step = 0.0 ;
    $completion = 0.0 ;

    foreach ($font in $Selected) {
        $completion = 100.0 * $step / $NumFonts
        Write-Progress -Activity "Downloading Nerd Fonts with Ligatures" -Status "Font Name = '$($font.Name)' ($step / $NumFonts)" -PercentComplete $completion -CurrentOperation $font.Name
    
        $Exists = DownloadFontZip($font)
    
        $step ++ ;

        if (!$Exists) {
            Write-Error -Message "🚨 Could not download the file." -Category ConnectionError -ErrorAction Continue -ErrorVariable Err
        }
    }

    Read-Host -Prompt "Do you want to auto unzip the files ? (Yes/No). Default is Yes. (y/n also accepted)" -OutVariable Wants

    if ($Wants.ToLower() -icontains "y") {

        Write-Progress -Activity "Downloading Nerd Fonts with Ligatures" -Completed -PercentComplete 100.0

        Write-Progress -Activity "Unzipping Archives..." -Status "Assessing"

        $zipStep = 0.0;
        $zipCompletion = 0.0 ;
        foreach ($font in $Selected) {
            $zipCompletion = 100.0 * $step / $NumFonts ;
            Write-Progress -Activity "Unzipping Archives..." -Status "Font Name = '$($font.Name)' ($zipStep / $NumFonts)" -PercentComplete $zipCompletion -CurrentOperation $font.Name
            $zipPath = "$PWD\$($font.Name).zip"
            Unzip -PathToArchive $zipPath
            $zipStep++;

        }

        Write-Progress -Activity "Unzipping Archives..." -Status "Done !" -Completed -PercentComplete 100.0

    }
    else {
        exit
    }

    Read-Host -Prompt "Do you want to auto register the fonts ? (Yes/No). Default is Yes. (y/n also accepted)" -OutVariable Wants

    if ($Wants.ToLower() -icontains "y") {
        $fontsPath = $PWD
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
        $fontFiles = @()
        Write-Progress -Activity "Registering Fonts" -Status "Enumerating font files"
        foreach ($font in $Selected) {
            Write-Progress -Activity "Registering Fonts" -Status "Enumerating font files: $($fontFiles.Length)"
            # Get all .ttf files recursively
            $fontFiles += Get-ChildItem -Path "$fontsPath\$($font.Name)" -Filter "*.ttf" -Recurse -ErrorAction SilentlyContinue
            $fontFiles += Get-ChildItem -Path "$fontsPath\$($font.Name)" -Filter "*.ttc" -Recurse -ErrorAction SilentlyContinue
        }
        $totalCount = $fontFiles.Count
        $currentCount = 0.0

        foreach ($fontFile in $fontFiles) {
            $fontName = $fontFile.Name
            $fontFullPath = $fontFile.FullName

            $fontRegistryPath = "$registryPath\$fontName"
            New-Item -Path $fontRegistryPath -ItemType String -Force | Out-Null
            Set-ItemProperty -Path $fontRegistryPath -Name "FontFile" -Value $fontFullPath | Out-Null
            Set-ItemProperty -Path $fontRegistryPath -Name "FontName" -Value $fontName | Out-Null

            # Update progress
            $currentCount++
            $progressPercentage = ($currentCount / $totalCount) * 100
            Write-Progress -Activity "Registering Fonts" -Status "Progress: $progressPercentage%" -PercentComplete $progressPercentage
        }
    }
        

    # Refresh the font cache
    $win32FontCacheService = Get-Service -Name "Winmgmt" -ErrorAction SilentlyContinue
    if ($null -ne $win32FontCacheService ) {
        $win32FontCacheService.Refresh()
    }
}


Main ; 