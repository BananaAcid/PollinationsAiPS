#Requires -Modules SHiPS

using namespace Microsoft.PowerShell.SHiPS
using namespace System.IO

using namespace System.Windows.Media.Imaging


<#
.SYNOPSIS
    A SHiPS provider for Pollinations.ai Media Storage.
    
.DESCRIPTION
    To use this drive, mount it using the following commands:
    
    Import-Module .\files.ships.psm1
    New-PSDrive -Name PollinationsAI -PSProvider SHiPS -Root "files.ships#PollinationsRoot"
    
    Upload a file:
    New-Item -Path PollinationsAI:\ -Name "MyImage.jpg" -Value "C:\Local\Path\To\Image.jpg"
    
    Reference an already existing Pollinations hash:
    New-Item -Path PollinationsAI:\ -ItemType "HashRef" -Name "OldUpload" -Value "YOUR_HASH_HERE"
#>

# Maintains a session-level state for uploaded files since the API doesn't have a "List all files" endpoint
class PollinationsState {
    static [System.Collections.Generic.List[object]] $Files = [System.Collections.Generic.List[object]]::new()
    static [string] $StorageDir = ""
    static [bool] $Loaded = $false

    # Helper to generate the hashed JSON filename
    static [string] GetStateFilePath() {
        $apiKey = $env:POLLINATIONSAI_API_KEY
        $keyStr = if ($apiKey) { $apiKey } else { "anonymous" }
        $md5 = [System.Security.Cryptography.MD5]::Create()
        $hashBytes = $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($keyStr))
        $hashStr = [BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()
        $dir = [PollinationsState]::StorageDir
        if ([string]::IsNullOrEmpty($dir)) { $dir = $env:TEMP }
        return [Path]::Combine($dir, "files.$hashStr.json")
    }

    # Loads the saved files list from JSON
    static [void] Load() {
        if ([PollinationsState]::Loaded) { return }
        $path = [PollinationsState]::GetStateFilePath()
        if (Test-Path $path) {
            try {
                $json = Get-Content $path -Raw | ConvertFrom-Json
                [PollinationsState]::Files.Clear()
                if ($null -ne $json) {
                    $items = if ($json -is [array]) { $json } else { @($json) }
                    foreach ($item in $items) {
                        $f = [PollinationsFile]::new($item.Name, $item.Url, $item.Hash, $item.ContentType, $item.Size)
                        $f.Width = $item.Width
                        $f.Height = $item.Height
                        [PollinationsState]::Add($f)
                    }
                }
            } catch { Write-Warning "Failed to load PollinationsAI state: $_" }
        }
        [PollinationsState]::Loaded = $true
    }

    static [void] Save() {
        $path = [PollinationsState]::GetStateFilePath()
        try {
            if ([PollinationsState]::Files.Count -gt 0) {
                [PollinationsState]::Files | Select-Object Name, Url, Hash, ContentType, Size, Width, Height | ConvertTo-Json -Depth 2 | Set-Content $path -Force
            } elseif (Test-Path $path) {
                Remove-Item $path -Force
            }
        } catch { Write-Warning "Failed to save PollinationsAI state: $_" }
    }

    # Adds a new file to the state if it doesn't already exist
    static [void] Add([PollinationsFile]$file) {
        # Check if hash AND name already exist
        $duplicate = [PollinationsState]::Files | Where-Object { 
            $_.Hash -eq $file.Hash -or $_.Name -eq $file.Name 
        }

        if ($duplicate) {
            Write-Warning "File '$($file.Name)' with the same hash already exists in state. Skipping."
            return
        }

        # Add and persist
        [PollinationsState]::Files.Add($file)
        [PollinationsState]::Save()
    }
}

class PollinationsRoot : SHiPSDirectory {
    PollinationsRoot([string]$name) : base($name) { }

    [object[]] GetChildItem() {
        [PollinationsState]::Load()
        $results = [PollinationsState]::Files.ToArray()
        # Force the type name so Update-TypeData works on the SHiPS wrapped objects
        foreach ($r in $results) {
            if ($r.psobject.TypeNames[0] -ne "PollinationsFile") {
                $r.psobject.TypeNames.Insert(0, "PollinationsFile")
            }
        }
        return $results
    }

    [object] NewItem([string]$name, [string]$itemType, [object]$value) {
        if (-not $value) {
            throw "Please provide a value. For file upload, provide the local file path via -Value."
        }

        $apiKey = $env:POLLINATIONSAI_API_KEY
        if (-not $apiKey) {   # required by upload
            throw "Please set the POLLINATIONSAI_API_KEY environment variable."
        }

        # 1. Handle adding an existing Pollinations Hash without uploading
        if ($itemType -eq "HashRef") {
            $hash = $value.ToString()
            $url = "https://media.pollinations.ai/$hash"
            $name = if ([string]::IsNullOrWhiteSpace($name)) { $hash } else { $name }
            $newRefFile = [PollinationsFile]::new($name, $url, $hash)
            $this.FetchMetadata($newRefFile)
            [PollinationsState]::Add($newRefFile)
            [PollinationsState]::Save()
            return $newRefFile
        }

        # 2. Handle uploading a new file (Default)
        $localFilePath = $value.ToString()

        # Resolve absolute path in case user executes this while already INSIDE the PollinationsAI:\ drive
        if (-not [Path]::IsPathRooted($localFilePath)) {
            $localFilePath = "$((Get-Location).ProviderPath)\$localFilePath"
        }
        if (-not (Test-Path $localFilePath)) { throw "File not found: $localFilePath" }
        $name = if ([string]::IsNullOrWhiteSpace($name)) { [Path]::GetFileName($localFilePath) } else { $name }

        $headers = @{}
        $headers["Authorization"] = "Bearer $apiKey"

        $fileSize = (Get-Item -Path $localFilePath).Length
        $headers["Content-Length"] = $fileSize

        $uri = "https://media.pollinations.ai/upload"
        $ext = [Path]::GetExtension($localFilePath).ToLower()
        $contentType = "application/octet-stream"

        # Resolve standard file extensions
        $contentType = switch ($ext) {
            ".jpg"  { "image/jpeg" }
            ".jpeg" { "image/jpeg" }
            ".png"  { "image/png" }
            ".gif"  { "image/gif" }
            ".mp4"  { "video/mp4" }
            ".mp3"  { "audio/mpeg" }
            ".wav"  { "audio/wav" }
            ".txt"  { "text/plain" }
            ".json" { "application/json" }
        }

        Write-Verbose "Uploading $localFilePath to $uri..."
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -InFile $localFilePath -ContentType $contentType
        $url = if ($response -is [string]) { 
            $response.Trim() 
        } elseif ($null -ne $response.url) { 
            $response.url.ToString().Trim() 
        } else { 
            $response | ConvertTo-Json -Compress 
        }

        # Extract content hash from the URL
        $hash = $url -replace "^.*/", ""

        $newFile = [PollinationsFile]::new($name, $url, $hash, $contentType, $fileSize)
        
        # might not return anything
        $this.FetchMetadata($newFile)

        # This reads only the header metadata without loading the full image into RAM
        if ($contentType -like "image/*" -or $contentType -like "video/*" -and $newFile.Width -eq 0 -and $newFile.Height -eq 0) {
            $stream = $null
            try {
                $stream = [File]::OpenRead($localFilePath)
                $decoder = [BitmapDecoder]::Create($stream, "None", "Default")

                $newFile.Width = $decoder.Frames[0].PixelWidth                  # !   is this working ?
                $newFile.Height = $decoder.Frames[0].PixelHeight

                Write-Verbose "Successfully read image metadata from $localFilePath"
            } catch { 
                Write-Warning "Failed to read image metadata from $localFilePath"
            }
            finally { if ($stream) { $stream.Close(); $stream.Dispose() } }
        }

        [PollinationsState]::Add($newFile)
        #[PollinationsState]::Add($newFile)
        [PollinationsState]::Save()

        return $newFile
    }

    # Helper function to extract metadata
    [void] FetchMetadata([PollinationsFile]$fileItem) {
        $apiKey = $env:POLLINATIONSAI_API_KEY
        $headers = @{}
        $headers["Authorization"] = "Bearer $apiKey"

        try {
            $metaUri = "https://media.pollinations.ai/$($fileItem.Hash)/metadata"
            $meta = Invoke-RestMethod -Uri $metaUri -Method Get -Headers $headers -ErrorAction SilentlyContinue
            if ($null -ne $meta) {
                if ($null -ne $meta.size)   { $fileItem.Size = [int]$meta.size }
                if ($null -ne $meta.type)   { $fileItem.ContentType = [string]$meta.type }
                if ($null -ne $meta.width)  { $fileItem.Width = [int]$meta.width }
                if ($null -ne $meta.height) { $fileItem.Height = [int]$meta.height }
            }
        } catch { }
    }
}

class PollinationsFile : SHiPSLeaf {
    [string]$Url
    [string]$Hash
    [string]$ContentType
    [int]$Size
    [int]$Width
    [int]$Height

    PollinationsFile([string]$name, [string]$url, [string]$hash, [string]$contentType = "unknonwn", [int]$size = 0) : base($name) {
        $this.Url = $url
        $this.Hash = $hash
        $this.ContentType = $contentType
        $this.Size = $size
        $this.Width = 0
        $this.Height = 0
    }

    # This method is called by SHiPS to run Get-Content
    [object[]] GetContent() {
        Write-Verbose "Fetching content from $($this.Url)..."
        try {
            $data = Invoke-WebRequest -Uri $this.Url -Method Get -UseBasicParsing -ErrorAction Stop
            # Return as a single object (byte array)
            return $data.Content
        } catch {
            throw "Failed to download content for $($this.Name): $($_.Exception.Message)"
        }
    }

    # This method is called by Remove-Item
    [void] RemoveItem() {
        $apiKey = $env:POLLINATIONSAI_API_KEY
        $headers = @{}
        if ($apiKey) { $headers["Authorization"] = "Bearer $apiKey" }
        
        $deleteUri = "https://media.pollinations.ai/$($this.Hash)"
        Write-Verbose "Deleting from API: $deleteUri"
        
        try {
            # Perform API deletion
            $null = Invoke-RestMethod -Uri $deleteUri -Method Delete -Headers $headers -ErrorAction Stop
            
            # Remove from local state
            $toRemove = [PollinationsState]::Files | Where-Object { $_.Hash -eq $this.Hash }
            if ($null -ne $toRemove) {
                [PollinationsState]::Files.Remove($toRemove)
                [PollinationsState]::Save()
            }
            Write-Host "Successfully deleted $($this.Name) ($($this.Hash))" -ForegroundColor Yellow
        } catch {
            if ($_.Exception.Response -and $_.Exception.Response.StatusCode.value__ -eq 404) {
                Write-Warning "The file with hash $($this.Hash) was not found on the server. It may have already been deleted."
            } else {
                throw "Failed to delete file from Pollinations API: $($_.Exception.Message)"
            }
        }
    }

}

# Tell the state where to save the files.(hashedkey).json
[PollinationsState]::StorageDir = $PSScriptRoot

# Re-format PowerShell's 'ls' default view so you instantly see Hashes!
Update-TypeData -TypeName "PollinationsFile" -DefaultDisplayPropertySet "Name", "Hash", "Size", "ContentType" -Force