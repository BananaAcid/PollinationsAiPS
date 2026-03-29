<#

TODO:

Update-TypeData DOES not reformat the output of "ls" 
-- see? https://github.com/rchaganti/PSConfDrive/blob/master/PSConfDrive.Format.ps1xml


renaming a file in the PSDrive ?  -> like downloading-renaming-online_Delete-uploading  (for Content-Deposition to work)



Uploaded Name is the same as destination name in copy?


copy to subfolder:
    error on copy
        copy ..\examples\wallpapers\wp_black-white.jpg PollinationsAi:\test\black-white.jpg
        Copy-Item: D:\GitHub\PollinationsAiPS\PollinationsAiPS\files.ps1:199:24
        Line |
        199 |  …            else { Microsoft.PowerShell.Management\Copy-Item @params }
            |                      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            | Source and destination path did not resolve to the same provider.


    only this works in upload - but nothing shows up in the directory (does nothing):
        Copy-PollinationsAiFile ..\examples\wallpapers\wp_black-white.jpg PollinationsAi:\test\black-white.jpg
        Uploading wp_black-white.jpg to PollinationsAi:\test as black-white.jpg...
        Done!

    ... Copy-Item should use get-item for downloading




get item by hash, even if it is not in $Files (just get it) -Check if media exists -> https://enter.pollinations.ai/api/docs#tag/-media-storage/HEAD/{hash}
    curl 'https://media.pollinations.ai/{hash}' \
    --request HEAD \
    --header 'Authorization: Bearer YOUR_SECRET_TOKEN'

    ... and add to $files, because the filename is in the header as part of the content-disposition

    ... copy (from pollinationsai: with -Hash instead of -Path) and get-content (from pollinationsai: -Path instead of -Hash) should work as well  (and also update $files)

    ... remove-item should work with -Hash as well /first getting the metadata from endpoint, then removing it



a function that can be piped into line by line with a hash or an array of hashes, that will get the metadata and add it to $files ( https://enter.pollinations.ai/api/docs#tag/-media-storage/HEAD/{hash} )
    ... to be able to load a "backup" of hashes


API KEY : multiple drives should be possible, with different API keys. Also changing the $env API KEY, the current drive should sill work with the key it got initialized with.
    - can a drive be initialized with a key?  like an WebDav/FTP Drive would work?


Fork with missing fnctions
    https://github.com/Scal-Human/SHiPS


#>


Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase


# Import the SHiPS module
Import-Module SHiPS -ErrorAction SilentlyContinue

If (-not (Get-Module -Name SHiPS -ListAvailable)) {
    Install-Module SHiPS -Force
    Import-Module SHiPS
}

# Import the drive specs
Import-Module $PSScriptRoot\files.ships.psm1


$script:lastDriveName = "";

Function Set-PollinationsAiDrive {
    param(
        $Name = "PollinationsAI",
        [switch]$Silent = $false
    )
    if (-not $env:POLLINATIONSAI_API_KEY) {
        if (-not $Silent) {
            throw "Please set the `$env:POLLINATIONSAI_API_KEY environment variable to use the PollinationsAI Drive. You can use 'Get-PollinationsAiByok -Add'. See the Readme for more information. Then restart the session or retry with 'Set-PollinationsAiDrive'"
        }
        return
    }

    if ($script:lastDriveName) {
        Remove-PSDrive -Name $lastDriveName -ErrorAction SilentlyContinue
    }
    $script:lastDriveName = $Name
    
    New-PSDrive -Name $Name -PSProvider SHiPS -Root "files.ships#PollinationsRoot" -Description "PollinationsAI Cloud Storage" -Scope Global    
}

Function Get-PollinationsAiDrive {
    if ($script:lastDriveName) {
        return Get-PSDrive -Name $script:lastDriveName
    }
    else {
        return $null
    }
}

# Create the drive, but only if there is an api key
Set-PollinationsAiDrive -Silent | Out-Null



<#
.SYNOPSIS
    Helper function to mimic Copy-Item behavior for PollinationsAI drive.
#>
function Copy-PollinationsAiFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)][string]$Path,
        [Parameter(Mandatory=$false, Position=1)][string]$Destination = "PollinationsAI:\"
    )

    if (-not (Test-Path $Path)) { throw "Cannot find path '$Path' because it does not exist."}
    
    $fullPath = Convert-Path $Path -ErrorAction Stop
    $name = Split-Path $fullPath -Leaf
    $targetPath = $Destination

    # If Destination ends with a filename, split it
    if ($Destination -match "\.[a-zA-Z0-9]+$") {
        $name = Split-Path $Destination -Leaf
        $targetPath = Split-Path $Destination -Parent
        if ([string]::IsNullOrWhiteSpace($targetPath)) { $targetPath = "PollinationsAI:\" }
    }

    Write-Host "Uploading $(Split-Path $fullPath -Leaf) to $targetPath as $name..." -ForegroundColor Cyan
    
    $newItem = $null
    try {
        $newItem = New-Item -Path $targetPath -Name $name -ItemType "File" -Value $fullPath -ErrorAction Stop
    }
    catch [System.Management.Automation.MethodInvocationException] {
        throw $_
    }
    catch {
        $targetDir = Get-Item $targetPath -ErrorAction SilentlyContinue
        if ($targetDir -and $targetDir.psobject.Methods.Match('NewItem').Count -gt 0) {
            $newItem = $targetDir.NewItem($name, "File", $fullPath)
        } else {
            throw $_
        }
    }
    
    if ($newItem) {
        Write-Host "Done! Hash: $($newItem.Hash) | Url: $($newItem.Url)" -ForegroundColor Green
    } else {
        Write-Host "Done!" -ForegroundColor Green
    }

    return $newItem
}

function global:Copy-Item {
    [CmdletBinding(DefaultParameterSetName='Path', SupportsShouldProcess=$true)]
    param(
        [Parameter(ParameterSetName='Path', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][string[]]$Path,
        [Parameter(Position=1)][string]$Destination,
        [Parameter(ValueFromRemainingArguments=$true)][Object[]]$RemainingArgs
    )
    
    process {
        foreach ($p in $Path) {
            # Resolve the path to check if it's a PollinationsAI path (handles relative paths while inside the drive)
            $resolvedPath = try { (Resolve-Path $p -ErrorAction SilentlyContinue).Path } catch { $p }
            $resolvedDest = try { (Resolve-Path $Destination -ErrorAction SilentlyContinue).Path } catch { $Destination }

            $isUpload = ($null -ne $resolvedDest) -and ($resolvedDest -match "^PollinationsAI:")
            $isDownload = ($null -ne $resolvedPath) -and ($resolvedPath -match "^PollinationsAI:")
            
            if ($isUpload -and -not $isDownload) {
                try {
                    Copy-PollinationsAiFile -Path $p -Destination $Destination
                } catch {
                    Write-Error $_
                }
            } elseif ($isDownload -and -not $isUpload) {
                $fileName = Split-Path $resolvedPath -Leaf
                $destPath = $Destination
                
                if (-not $Destination) {
                    $destPath = Join-Path (Get-Location).Path $fileName
                } elseif (Test-Path $Destination -PathType Container) { 
                    $destPath = Join-Path $Destination $fileName 
                }
                
                Write-Host "Downloading $fileName to $destPath..." -ForegroundColor Cyan
                [PollinationsState]::Load()
                $fileObj = [PollinationsState]::Files | Where-Object { $_.Name -eq $fileName } | Select-Object -First 1
                
                if ($fileObj) {
                    Invoke-WebRequest -Uri $fileObj.Url -OutFile $destPath
                    Write-Host "Download Complete!" -ForegroundColor Green
                } else {
                    Write-Error "File '$fileName' not found in cache. Ensure you use 'ls' to refresh the drive first."
                }
            } else {
                # Fix for positional parameter error: Use splatting to avoid passing nulls or empty arrays
                $params = @{ Path = $p }
                if ($Destination) { $params["Destination"] = $Destination }
                
                # Use & to call native Copy-Item and avoid recursion if this function is named Copy-Item
                if ($RemainingArgs) { Microsoft.PowerShell.Management\Copy-Item @params @RemainingArgs }
                else { Microsoft.PowerShell.Management\Copy-Item @params }
            }
        }
    }
}

function global:Remove-Item {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][string[]]$Path,
        [Parameter(ValueFromRemainingArguments=$true)][Object[]]$RemainingArgs
    )
    process {
        foreach ($p in $Path) {
            $resolvedPath = try { (Resolve-Path $p -ErrorAction SilentlyContinue).Path } catch { $p }
            if ($resolvedPath -match "^PollinationsAI:") {
                # Force SHiPS to call the class's RemoveItem() method
                $item = Get-Item $resolvedPath -ErrorAction SilentlyContinue
                if ($item -and $item.psobject.Methods.Match('RemoveItem').Count -gt 0) {
                    if ($PSCmdlet.ShouldProcess($resolvedPath, "Delete from Pollinations API")) {
                        $item.RemoveItem()
                    }
                } else {
                    $params = @{ Path = $p }
                    if ($RemainingArgs) { Microsoft.PowerShell.Management\Remove-Item @params @RemainingArgs }
                    else { Microsoft.PowerShell.Management\Remove-Item @params }
                }
            } else {
                $params = @{ Path = $p }
                if ($RemainingArgs) { Microsoft.PowerShell.Management\Remove-Item @params @RemainingArgs }
                else { Microsoft.PowerShell.Management\Remove-Item @params }
            }
        }
    }
}
