<#

TODO:



BUG: downloading / GC



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
        Add-PollinationsAiFile ..\examples\wallpapers\wp_black-white.jpg PollinationsAi:\test\black-white.jpg
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




Fork with missing fnctions
    https://github.com/Scal-Human/SHiPS


#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '', Justification="For me there is no readability issue", Scope = 'Function', Target = '*')]
param()


#*IMG  Add-Type -AssemblyName PresentationCore
#*IMG  Add-Type -AssemblyName WindowsBase


# Import the SHiPS module
Import-Module SHiPS -ErrorAction SilentlyContinue

If (-not (Get-Module -Name SHiPS -ListAvailable)) {
    Install-Module SHiPS -Force
    Import-Module SHiPS
}

# Import the drive specs
Import-Module $PSScriptRoot\files.ships.psm1


$script:lastDriveName = $null

Function Enable-PollinationsAiDrive {
    param(
        $Name = "PollinationsAI",
        [switch]$Silent = $false
    )
    if (-not $env:POLLINATIONSAI_API_KEY) {
        if (-not $Silent) {
            throw "Please set the `$env:POLLINATIONSAI_API_KEY environment variable to use the PollinationsAI Drive. You can use 'Get-PollinationsAiByok -Add'. See the Readme for more information. Then restart the session or retry with 'Enable-PollinationsAiDrive'"
        }
        return
    }

    $pollinationsDrive = Get-PSDrive |? Root -eq "files.ships#PollinationsRoot"
    if ($pollinationsDrive) {
        $pollinationsDrive | Remove-PSDrive -ErrorAction Stop  # might be in use, e.g. is current path
    }

    $script:lastDriveName = $Name
    
    New-PSDrive -Name $Name -PSProvider SHiPS -Root "files.ships#PollinationsRoot" -Description "PollinationsAI Cloud Storage" -Scope Global
}

Function Get-PollinationsAiDrive {
    if ($script:lastDriveName) {
        return Get-PSDrive |? Root -eq "files.ships#PollinationsRoot"
    }
    else {
        return $null
    }
}

# Create the drive, but only if there is an api key
Enable-PollinationsAiDrive -Silent | Out-Null



<#
.SYNOPSIS
    Helper function to mimic Copy-Item behavior for PollinationsAI drive.
#>
function Add-PollinationsAiFileOld {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)][string]$Path,
        [Parameter(Mandatory=$false, Position=1)][string]$Destination = "$($script:lastDriveName):\\"
    )

    if (-not (Test-Path $Path)) { throw "Cannot find path '$Path' because it does not exist."}
    
    $fullPath = Convert-Path $Path -ErrorAction Stop
    $name = Split-Path $fullPath -Leaf
    $targetPath = $Destination

    # If Destination ends with a filename, split it
    if ($Destination -match "\.[a-zA-Z0-9]+$") {
        $name = Split-Path $Destination -Leaf
        $targetPath = Split-Path $Destination -Parent
        if ([string]::IsNullOrWhiteSpace($targetPath)) { $targetPath = "$($script:lastDriveName):\" }
    }

    if ($Destination -match "^$($script:lastDriveName):[\\/]") {
        # remove drive root, see if there is subfolder
        $relative = $Destination.Substring($script:lastDriveName.Length + 1).TrimStart('\','/')
        if ($relative -match "[\\/]" -and $relative -ne "") {
            throw "Subfolders are not supported in PollinationsAI drive. Specify a filename only."
        }
    }

    Write-Host "Uploading $(Split-Path $fullPath -Leaf) to $targetPath as $name..." -ForegroundColor Cyan
    
    $newItem = $null
    try {
        $newItem = New-Item -Path $targetPath -Name $name -ItemType "File" -Value $fullPath -ErrorAction Stop  # one of the the few suppoored ShiPS methods
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

function Get-PollinationsAiFileOld {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)][string]$Source,
        [Parameter(Mandatory=$false)][string]$Destination
    )

    # Accept either name or full drive path
    if ($Source -like "$($script:lastDriveName):*") {
        $Source = $Source.Substring($($script:lastDriveName).Length + 1).TrimStart('\','/')
    }

    # Use Get-Item to resolve the file object from the drive
    $fileObj = Get-Item "$($script:lastDriveName):\$Source" -ErrorAction Stop

    if (-not $fileObj) {
        throw "File '$Source' not found in PollinationsAI drive."
    }

    if (-not $Destination) {
        $Destination = Join-Path (Get-Location).Path $fileObj.Name
    } elseif (Test-Path $Destination -PathType Container) {
        $Destination = Join-Path $Destination $fileObj.Name
    }

    Write-Host "Downloading $($fileObj.Name) to $Destination..." -ForegroundColor Cyan

    # Use Get-Content to retrieve the content via SHiPS provider
    $content = Get-Content $fileObj -ErrorAction Stop

    # Save the byte array to file
    [IO.File]::WriteAllBytes($Destination, $content)

    Write-Host "Download Complete!" -ForegroundColor Green

    return (Resolve-Path $Destination)
}


function global:Copy-Item {
    [CmdletBinding(DefaultParameterSetName='Path', SupportsShouldProcess=$true)]
    param(
        [Parameter(ParameterSetName='Path', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][string[]]$Path,
        [Parameter(Position=1)][string]$Destination,
        [Parameter(ValueFromRemainingArguments=$true)][Object[]]$RemainingArgs
    )
    
    process {
        $currentDrive = (Get-Location).Drive.Name
        foreach ($p in $Path) {

            $sourceInDrive = $p -like "$($script:lastDriveName):*" -or ($currentDrive -eq $script:lastDriveName -and $p -notmatch '^[A-Za-z]:\\')
            $destInDrive   = $Destination -like "$($script:lastDriveName):*"

            if ($sourceInDrive -and -not $destInDrive) {
                # internal drive -> local path (download)
                try { Get-PollinationsAiFile -Source $p -Destination $Destination } catch { Write-Error $_ }
            } elseif (-not $sourceInDrive -and $destInDrive) {
                # local -> internal drive (upload)
                try { Add-PollinationsAiFile -Path $p -Destination $Destination } catch { Write-Error $_ }
            } elseif ($sourceInDrive -and $destInDrive) {
                Write-Error "PollinationsAI -> PollinationsAI copy is not supported."
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
            if ($resolvedPath -match ("^" + $script:lastDriveName + ":")) {
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

