function DownloadToFilePath ($downloadUrl, $targetFile)
{
    Write-Output ("Downloading installation files from URL: $downloadUrl to $targetFile")
    $targetFolder = Split-Path $targetFile

    if((Test-Path -path $targetFile))
    {
        Write-Output "Deleting old target file $targetFile"
        Remove-Item $targetFile -Force | Out-Null
    }

    if(-not (Test-Path -path $targetFolder))
    {
        Write-Output "Creating folder $targetFolder"
        New-Item -ItemType Directory -Force -Path $targetFolder | Out-Null
    }

    #Download the file
    $downloadAttempts = 0
    do
    {
        $downloadAttempts++

        try
        {
            $WebClient = New-Object System.Net.WebClient
            $WebClient.DownloadFile($downloadUrl,$targetFile)
            break
        }
        catch
        {
            Write-Output "Caught exception during download..."
            if ($_.Exception.InnerException){
                Write-Output "InnerException: $($_.InnerException.Message)"
            }
            else {
                Write-Output "Exception: $($_.Exception.Message)"
            }
        }

    } while ($downloadAttempts -lt 5)

    if($downloadAttempts -eq 5)
    {
        Write-Error "Download of $downloadUrl failed repeatedly. Giving up."
    }
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

Write-Output "Installing Test Architect"
$logFolder = Join-path -path $env:ProgramData -childPath "DTLArt_TA"
$downloadUrl = 'http://testarchitect.com/data/ta_build/8_3_u_4/TAClient/x64/TestArchitect_8.3.4.071_x64.zip'
$downloadISS = 'https://raw.githubusercontent.com/Evit15/AzureArtifact/master/Artifacts/window-TestArchitest/install.iss'
$localFile = Join-Path $logFolder 'TestArchitect.zip'
$localISS = Join-Path $logFolder 'install.iss'
#### Download TA
DownloadToFilePath $downloadUrl $localFile
#### Download ISS
DownloadToFilePath $downloadISS $localISS
Unzip $localFile "$logFolder\TestArchitect"
$fullLocalFile = Join-Path $logFolder 'TestArchitect\TestArchitect_8.3.4.071_x64.exe'
$argumentList = "-s -f1'$localISS'"
Write-Output "Running install $fullLocalFile $argumentList"
$retCode = Start-Process -FilePath $fullLocalFile -ArgumentList $argumentList -Wait -PassThru

if ($retCode.ExitCode -ne 0 -and $retCode.ExitCode -ne 3010)
{
    Write-Error "Product installation of $fullLocalFile failed with exit code: $($retCode.ExitCode.ToString())"    
}
else
{
    Write-Output "Test Architect install succeeded. "
}
