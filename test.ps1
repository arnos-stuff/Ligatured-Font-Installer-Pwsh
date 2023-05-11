# reusable calls

# Extracts zip archives
Function Unzip(
    [string]$PathToArchive
) {
    
    Expand-Archive -LiteralPath $PathToArchive -ErrorAction SilentlyContinue -ErrorVariable Err

    If (!$Err) {
        Write-Host -ForegroundColor Yellow "📦 Archives unzipped."
    }
    else {
        Write-Debug -Message "Failed to unzip $PathToArchive using `Expand-Archive` call."
        $Err | Out-File "$PWD/font-download-error.log" ;
        Write-Debug -Message "Wrote the error message in file $PWD/font-download-error.log"
    }
        
} ;


Function DownloadFontZip(
    [string]$Uri,
    [string]$Name
    ) {
    # Parameter help description
    
    $uri = New-Object System.Uri $Uri
    $zipName = "$Name.zip"
    $zipPath = "$PWD\$zipName"
    $response = Invoke-RestMethod -Method GET -OutFile $zipPath -Uri $Uri -ErrorAction SilentlyContinue -ErrorVariable Err
        
    if (!$Err) {
        Write-Host -ForegroundColor Green "✅ Font archive downloaded."
        $zipPath ;
    }
    else {
        Write-Debug -Message "Could not get zip from URL, response: `n$response"
    }
        
} ;

Function DownloadFont(
    [string]$Uri,
    [string]$Name,
    [switch]$AutoUnzip = $false
    ) {

    if (!$AutoUnzip) {
        Write-Information -MessageData "📦🔄 You did not ask for auto archive unpacking. Proceeding with the .zip downloading."
    }
    
    $zipPath = DownloadFontZip($Uri, $Name)
    
    $Exists = $(Test-Path $zipPath -and $( Get-Item $zipPath).Length > 0)

    if (!$Exists) {
        Write-Error -Message "🚨 Could not download the file." -Category ConnectionError -ErrorAction Continue -ErrorVariable Err
    }
    else {
        if ($AutoUnzip) {
            Unzip -PathToArchive $zipPath  ;
            Write-Host -ForegroundColor Green "✅ Font archive downloaded and 🔄 unpacked."
        }
        else {
            Write-Host -ForegroundColor Green "✅ Font archive downloaded."
        }
    }
    
} ;



# small helper functions

function GetPercentage(
    [Int]$Step,
    [Int]$Total
) {
    100.0 * $Step / [float]$Total
} ;

function FilterArray(
    [string[]]$Data,
    [string[]]$Excludes
) {
    $Data | ForEach-Object { if ($_ -notin $Excludes ) { $_ } }    
} ;

## Main procedural code
# storing all that in arrays:

function Processing {
    param (
        [switch]$Download,
        [string[]]$Excludes = @()
    )

    $FullData = @(
        [pscustomobject]@{Name = 'jetbrains-mono'; Install=$true; Uri = 'https://download.jetbrains.com/fonts/JetBrainsMono-2.304.zip?_gl=1*1jyrilq*_ga*MTg0NjA1MDQ3NS4xNjgzNzI0MjMx*_ga_9J976DJZ68*MTY4MzcyNDIzMS4xLjEuMTY4MzcyNDM1MC42MC4wLjA.&_ga=2.23088563.846408337.1683724231-1846050475.1683724231' }
        [pscustomobject]@{Name = 'fira-code'; Install=$true; Uri = 'https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip' }
        [pscustomobject]@{Name = 'iosevka-base'; Install=$true; Uri = 'https://github.com/be5invis/Iosevka/releases/download/v22.1.1/super-ttc-iosevka-22.1.1.zip' }
        [pscustomobject]@{Name = 'iosevka-aile'; Install=$true; Uri = 'https://github.com/be5invis/Iosevka/releases/download/v22.1.1/super-ttc-iosevka-aile-22.1.1.zip' }
        [pscustomobject]@{Name = 'iosevka-curly'; Install=$true; Uri = 'https://github.com/be5invis/Iosevka/releases/download/v22.1.1/super-ttc-iosevka-curly-22.1.1.zip' }
        [pscustomobject]@{Name = 'haskling'; Install=$true; Uri = 'https://github.com/i-tu/Hasklig/releases/download/v1.2/Hasklig-1.2.zip' }
        [pscustomobject]@{Name = 'victor-mono'; Install=$true; Uri = 'https://rubjo.github.io/victor-mono/VictorMonoAll.zip' }
        [pscustomobject]@{Name = 'ibm-plex-mono'; Install=$true; Uri = 'https://github.com/IBM/plex/releases/download/v6.3.0/TrueType.zip' }
    )

    Write-Progress -Activity "This installer will download the following fonts:" -Status "Starting.."
    Write-Host -Object $($FullData | Format-Table)
    
    Write-Progress -Activity "Pick the ones you wish to discard" -Status "User information needed."

    $TIMEOUT = 7 ;
    $NUM_MAX_ASKS = 3;

    Write-Output "The default installer gets every font. Press any key in the next $TIMEOUT seconds to pick fonts interactively."
    while( (-not $Host.UI.RawUI.KeyAvailable) -and ($secondsRunning -lt 5) ){
        Write-Host ("Waiting for: " + (5-$secondsRunning))
        Start-Sleep -Seconds 1
        $secondsRunning++
    }

    $Selection = @()

    foreach($font in $FullData) {
        $Answer = '' ;
        $numAsks = 0 ;
        while ($Answer -inotin @('y', 'n' ,'0', '1', 'yes', 'no') -and ($numAsks -lt $NUM_MAX_ASKS)) {
            Read-Host "Do you wish to install font $($font.Name) ? (Y/N) [default=Y]" -OutVariable Answer
            $numAsks ++ ;
            Write-Host -ForegroundColor Red -NoNewline "Incorrect input ($Answer), expected: y/n/0/1/yes/no"
        }
        if ($Answer -inotin @('n', '0', 'no')) {
            $Selection += $font
        }
    }

    $Data = $Selection

    Write-Progress -Activity "Downloading Nerd Fonts with Ligatures" -Status "Starting.." -PercentComplete 0

    $NumFonts = $Data.Length ;
    $step = 1 ;
    $completion = GetPercentage -Step $step -Total $NumFonts

    Write-Host $($Data | Format-Table)

    foreach ($font in $Data) {
        
        $completion = GetPercentage -Step $step -Total $NumFonts
        Write-Progress -Activity "Downloading Nerd Fonts with Ligatures" -Status "Font Name = '$($font.Name)' ($step / $NumFonts)" -PercentComplete $completion -CurrentOperation $font.Name
        DownloadFont $font.Uri $font.Name
    }

}

Processing -Download -Excludes @()