# Nabil Redmann - 2026-04-02
# License: MIT

Function Add-PollinationsAiFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$Path,
        [string][Alias("key")]$POLLINATIONSAI_API_KEY = $env:POLLINATIONSAI_API_KEY,
        [switch]$Details
    )
    process {
        if (-not $POLLINATIONSAI_API_KEY) { throw "⚠️  POLLINATIONSAI API KEY is missing! (-key or -POLLINATIONSAI_API_KEY or set `$env:POLLINATIONSAI_API_KEY=`"sk_...`")" }

        if (-not (Test-Path $Path -PathType Leaf)) {
            throw "Cannot find file path '$Path'. Only local file paths are supported for raw binary upload."
        }

        $localPath = Resolve-Path $Path

        $uri = "https://media.pollinations.ai/upload"
        $headers = @{ Authorization = "Bearer $POLLINATIONSAI_API_KEY" }

        try {
            $response = Invoke-WebRequest `
                -Uri $uri `
                -Method Post `
                -Headers $headers `
                -InFile $localPath `
                -ErrorAction Stop

            $contentJson = $response.Content | ConvertFrom-Json
            $url = if ($contentJson.url) { $contentJson.url.ToString().Trim() } else { $response.Content.Trim() }

            if ($Details) { 
                return @{
                    id = $contentJson.id
                    hash = $contentJson.id
                    url = $contentJson.url
                    contentType = $contentJson.contentType
                    size = $contentJson.size
                    duplicate = $contentJson.duplicate
                    Headers = $response.Headers
                    Content = $response.Content
                } 
            }
            else { return $url }
        }
        catch { throw $_ }
    }
}

# Throws on 404! This is on purpose
Function Get-PollinationsAiFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$Hash,
        [string][Alias("key")]$POLLINATIONSAI_API_KEY = $env:POLLINATIONSAI_API_KEY,
        [switch]$Details
    )
    process {
        $headers = @{ "Content-Type" = "application/json" }
        if ($POLLINATIONSAI_API_KEY) { $headers += @{Authorization = "Bearer $POLLINATIONSAI_API_KEY"} }

        $uri = "https://media.pollinations.ai/$Hash"
        try {
            $response = Invoke-WebRequest -Uri $uri -Method Get -Headers $headers -UseBasicParsing -ErrorAction Stop
            if ($Details) {
                return @{
                    id = $response.Headers.'X-Content-Hash' -or $Hash
                    hash = $Hash
                    url = $uri
                    contentType = $response.Headers.'Content-Type'
                    size = $response.Headers.'Content-Length'
                    Headers = $response.Headers
                    Content = $response.Content
                }
            }
            else { return $response.Content }
        } 
        catch { throw $_ }
    }
}

Function Remove-PollinationsAiFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$Hash,
        [string][Alias("key")]$POLLINATIONSAI_API_KEY = $env:POLLINATIONSAI_API_KEY,
        [switch]$Details
    )
    process {
        if (-not $POLLINATIONSAI_API_KEY) { throw "⚠️  POLLINATIONSAI API KEY is missing! (-key or -POLLINATIONSAI_API_KEY or set `$env:POLLINATIONSAI_API_KEY=`"sk_...`")" }

        $headers = @{ "Content-Type" = "application/json"; Authorization = "Bearer $POLLINATIONSAI_API_KEY" }
        $uri = "https://media.pollinations.ai/$Hash"

        try {
            $response = Invoke-WebRequest -Uri $uri -Method Delete -Headers $headers -ErrorAction Stop
            if ($Details) { 
                $contentJson = $response.Content | ConvertFrom-Json
                return @{
                    deleted = $contentJson.deleted
                    id = $contentJson.id # API is missing heders: X-Content-Hash,X-Content-Size - but provides Content.id
                    hash = $Hash
                    url = $uri
                    Headers = $response.Headers
                    Content = $response.Content
                } 
            } 
            else { return $true }
        } 
        catch {
            if ($_.Exception.Response -and $_.Exception.Response.StatusCode.value__ -eq 404) {
                if ($Details) { 
                    $contentJson = $_.Exception.Response.Content | ConvertFrom-Json
                    return @{
                        deleted = $contentJson.deleted -or $false
                        id = $contentJson.id -or $Hash
                        hash = $Hash
                        url = $uri
                        Headers = $_.Exception.Response.Headers
                        Content = $_.Exception.Response.Content
                    } 
                } 
                else { return $false }
            } 
            else { throw $_ }
        }
    }
}

#! ENDPOINT BUGGY - So no 404 handling yet.
Function Export-PollinationsAiFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$Hash,
        [string][Alias("key")]$POLLINATIONSAI_API_KEY = $env:POLLINATIONSAI_API_KEY,
        [switch]$Details
    )
    process {
        $headers = @{ "Content-Type" = "application/json" }
        if ($POLLINATIONSAI_API_KEY) { $headers += @{Authorization = "Bearer $POLLINATIONSAI_API_KEY"} }

        $uri = "https://media.pollinations.ai/$Hash/metadata"
        try {
            $response = Invoke-WebRequest -Uri $uri -Method Get -Headers $headers -ErrorAction Stop
            if ($Details) {
                return @{
                    id = $Hash
                    hash = $Hash
                    url = $uri
                    Headers = $response.Headers
                    Content = $response.Content
                }
            }
            else { return ($response.Content | ConvertFrom-Json) }
        }
        catch { throw $_ }
    }
}

Function Test-PollinationsAiFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$Hash,
        [string][Alias("key")]$POLLINATIONSAI_API_KEY = $env:POLLINATIONSAI_API_KEY,
        [switch]$Details
    )
    process {
        if (-not $POLLINATIONSAI_API_KEY) { throw "⚠️  POLLINATIONSAI API KEY is missing! (-key or -POLLINATIONSAI_API_KEY or set `$env:POLLINATIONSAI_API_KEY=`"sk_...`")" }

        $uri = "https://media.pollinations.ai/$Hash"
        try {
            $response = Invoke-WebRequest -Uri $uri -Method Head -UseBasicParsing -ErrorAction Stop
            if ($Details) { 
                return @{
                    success = $true
                    id = $Hash # API is missing headers: X-Content-Hash,X-Content-Size
                    hash = $Hash
                    url = $uri
                    contentType = $response.Headers.'Content-Type'
                    contentLength = $response.Headers.'Content-Length'
                    Headers = $response.Headers
                } 
            }
            else { return $true }
        }
        catch {
            if ($_.Exception.Response -and $_.Exception.Response.StatusCode.value__ -eq 404) {
                if ($Details) { 
                    return @{
                        success = $false
                        id = $Hash # API is missing headers: X-Content-Hash,X-Content-Size
                        hash = $Hash
                        url = $uri
                        contentType = $_.Exception.Response.Headers.'Content-Type'
                        contentLength = $_.Exception.Response.Headers.'Content-Length'
                        Headers = $_.Exception.Response.Headers
                    } 
                }
                else { return $false }
            }
            else { throw $_ }
        }
    }
}

Function Get-PollinationsAiEncodedImage {
    # `data:image/png;base64,` or  `data:image/jpeg;base64,`
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$Path,
        [string][Alias("key")]$POLLINATIONSAI_API_KEY = $env:POLLINATIONSAI_API_KEY,
        [switch]$Details
    )
    process {
        if (-not $POLLINATIONSAI_API_KEY) { throw "⚠️  POLLINATIONSAI API KEY is missing! (-key or -POLLINATIONSAI_API_KEY or set `$env:POLLINATIONSAI_API_KEY=`"sk_...`")" }

        try {
            Add-Type -AssemblyName System.Web
            
            $filePath = Resolve-Path $Path
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $encodedImage = [System.Convert]::ToBase64String($bytes)
            
            # check $bytes the file content, what content type the image has (GetMimeMapping won't work)
            $type = ""
            if ($bytes[0] -eq 0x89 -and $bytes[1] -eq 0x50 -and $bytes[2] -eq 0x4E -and $bytes[3] -eq 0x47) { $type = "png" }
            if ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xD8 -and $bytes[2] -eq 0xFF -and $bytes[3] -eq 0xE0) { $type = "jpeg" }
            if ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xD8 -and $bytes[2] -eq 0xFF -and $bytes[3] -eq 0xE1) { $type = "jpeg" }
            if ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xD8 -and $bytes[2] -eq 0xFF -and $bytes[3] -eq 0xE2) { $type = "jpeg" }
            if ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xD8 -and $bytes[2] -eq 0xFF -and $bytes[3] -eq 0xE3) { $type = "jpeg" }

            if ($type -eq "") { throw "File is not an jpeg/png image!" }

            # content
            $content = "data:image/$type;base64,$encodedImage"
            if ($Details) { 
                return @{
                    id = $Hash
                    hash = $Hash
                    Content = $content
                    contentType = "image/$type"
                    path = $filePath
                }
            }
            else { return $content }
        }
        catch { throw $_ }
    }
}


<#
    .Notes
        To run:  PS> . Measure-PollinationsAiFile -Details

        Allows to dig into the vars, eg. $result
#>
Function Measure-PollinationsAiFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][string]$PathTestImage,
        [string][Alias("key")]$POLLINATIONSAI_API_KEY = $env:POLLINATIONSAI_API_KEY,
        [switch]$KeepLocal,
        [switch]$Details
    )

    process {
        if (-not $POLLINATIONSAI_API_KEY) { throw "⚠️  POLLINATIONSAI API KEY is missing! (-key or -POLLINATIONSAI_API_KEY or set `$env:POLLINATIONSAI_API_KEY=`"sk_...`")" }

        $createdTemp = $false
        try {
            if ([string]::IsNullOrWhiteSpace($PathTestImage)) {
                # use stable online test image instead of an ad hoc text file
                $PathTestImage = Join-Path ([IO.Path]::GetTempPath()) ("pollinationsaitest_{0}.png" -f [guid]::NewGuid())
                $sourceUrl = "https://upload.wikimedia.org/wikipedia/en/thumb/8/80/Wikipedia-logo-v2.svg/960px-Wikipedia-logo-v2.svg.png"
                Invoke-WebRequest -Uri $sourceUrl -OutFile $PathTestImage -UseBasicParsing -ErrorAction Stop
                $createdTemp = $true
            } else {
                if (-not (Test-Path $PathTestImage -PathType Leaf)) {
                    throw "Path not found: $PathTestImage"
                }
            }

            # Test Upload
            $upload = Add-PollinationsAiFile -Path $PathTestImage -POLLINATIONSAI_API_KEY $POLLINATIONSAI_API_KEY -Details
            if ($null -eq $upload) {
                # fallback in case Function returns URL only
                $url = Add-PollinationsAiFile -Path $PathTestImage -POLLINATIONSAI_API_KEY $POLLINATIONSAI_API_KEY
                $hash = $url -replace '^.*/',''
            } else {
                # upload is a hashtable with id/hash/url/etc
                $hash = $upload.hash
                if (-not $hash) {
                    $hash = $upload.url -replace '^.*/',''
                }
            }

            # Test with -Details
            $check1Detail = $null
            $get1Detail = $null
            $meta1Detail = $null
            $rm1Detail = $null
            $check2Detail = $null
            
            try { $check1Detail = Test-PollinationsAiFile -Hash $hash -POLLINATIONSAI_API_KEY $POLLINATIONSAI_API_KEY -Details } 
            catch { Write-Warning "Test-PollinationsAiFile (before, -Details) failed: $_" }
            
            try { $get1Detail = Get-PollinationsAiFile -Hash $hash -POLLINATIONSAI_API_KEY $POLLINATIONSAI_API_KEY -Details } 
            catch { Write-Warning "Get-PollinationsAiFile (-Details) failed: $_" }
            
            try { $meta1Detail = Export-PollinationsAiFile -Hash $hash -POLLINATIONSAI_API_KEY $POLLINATIONSAI_API_KEY -Details } 
            catch { Write-Warning "Export-PollinationsAiFile (-Details) failed: $_" }

            # Test without -Details (basic return value test)
            $check1NoDetail = $null
            $get1NoDetail = $null
            $meta1NoDetail = $null
            
            try { $check1NoDetail = Test-PollinationsAiFile -Hash $hash -POLLINATIONSAI_API_KEY $POLLINATIONSAI_API_KEY } 
            catch { Write-Warning "Test-PollinationsAiFile (before, no -Details) failed: $_" }
            
            try { $get1NoDetail = Get-PollinationsAiFile -Hash $hash -POLLINATIONSAI_API_KEY $POLLINATIONSAI_API_KEY } 
            catch { Write-Warning "Get-PollinationsAiFile (no -Details) failed: $_" }
            
            try { $meta1NoDetail = Export-PollinationsAiFile -Hash $hash -POLLINATIONSAI_API_KEY $POLLINATIONSAI_API_KEY } 
            catch { Write-Warning "Export-PollinationsAiFile (no -Details) failed: $_" }

            # Remove file
            $rm1Detail = $null
            $rm1NoDetail = $null
            try { $rm1Detail = Remove-PollinationsAiFile -Hash $hash -POLLINATIONSAI_API_KEY $POLLINATIONSAI_API_KEY -Details } 
            catch { Write-Warning "Remove-PollinationsAiFile (-Details) failed: $_" }
            
            try { $rm1NoDetail = Remove-PollinationsAiFile -Hash $hash -POLLINATIONSAI_API_KEY $POLLINATIONSAI_API_KEY } 
            catch { Write-Warning "Remove-PollinationsAiFile (no -Details) failed: $_" }

            # Test after deletion
            $check2NoDetail = $null
            $check2Detail = $null
            try { $check2Detail = Test-PollinationsAiFile -Hash $hash -POLLINATIONSAI_API_KEY $POLLINATIONSAI_API_KEY -Details } 
            catch { Write-Warning "Test-PollinationsAiFile (after, -Details) failed: $_" }
            
            try { $check2NoDetail = Test-PollinationsAiFile -Hash $hash -POLLINATIONSAI_API_KEY $POLLINATIONSAI_API_KEY } 
            catch { Write-Warning "Test-PollinationsAiFile (after, no -Details) failed: $_" }

            # Determine success: file existed before, doesn't exist after
            $beforeExists = if ($check1Detail) { $null -ne $check1Detail.ContentType } else { $check1NoDetail -eq $true }
            $afterExists = if ($check2Detail) { $null -ne $check2Detail.ContentType } else { $check2NoDetail -eq $true }
            $successFlag = $beforeExists -and (-not $afterExists)

            $result = [pscustomobject]@{
                InputPath      = $PathTestImage
                Uploaded       = $true
                Hash           = $hash
                UploadResult   = $upload
                TestBefore    = $check1Detail
                TestBeforeNoDetail = $check1NoDetail
                GetResult      = if ($Details) { $get1Detail } else { $null }
                GetResultNoDetail = if ($Details) { $get1NoDetail } else { $null }
                Metadata       = if ($Details) { $meta1Detail } else { $null }
                MetadataNoDetail = if ($Details) { $meta1NoDetail } else { $null }
                RemoveResult   = $rm1Detail
                RemoveResultNoDetail = $rm1NoDetail
                TestAfter      = $check2Detail
                TestAfterNoDetail = $check2NoDetail
                Success        = $successFlag
                MultiFileUpload = $null
                MultiFileRemove = $null
                MultiFileUploadSuccess = $false
                MultiFileRemoveSuccess = $false
            }

            # additional test: multi-file upload via pipeline + multi-hash remove via pipeline
            $multiFileUrls = @(
                "https://upload.wikimedia.org/wikipedia/en/thumb/4/4a/Commons-logo.svg/500px-Commons-logo.svg.png",
                "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c0/Enwiki-25.svg/500px-Enwiki-25.svg.png"
            )
            $tmpFiles = @()
            try {
                foreach ($u in $multiFileUrls) {
                    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("pollinationsaitest_{0}.png" -f [guid]::NewGuid())
                    Invoke-WebRequest -Uri $u -OutFile $tmp -UseBasicParsing -ErrorAction Stop
                    $tmpFiles += $tmp
                }

                $multiUpload = $tmpFiles | Add-PollinationsAiFile -POLLINATIONSAI_API_KEY $POLLINATIONSAI_API_KEY -Details
                $multiHashes = $multiUpload | ForEach-Object { $_.hash }
                $multiRemove = $multiHashes | Remove-PollinationsAiFile -POLLINATIONSAI_API_KEY $POLLINATIONSAI_API_KEY -Details

                $result.MultiFileUpload = $multiUpload
                $result.MultiFileRemove = $multiRemove
                $result.MultiFileUploadSuccess = ($multiUpload.Count -eq $tmpFiles.Count)
                $result.MultiFileRemoveSuccess = ($multiRemove | Where-Object { $_ -and $_.deleted } | Measure-Object).Count -eq $tmpFiles.Count
            } catch {
                Write-Warning "Multi-file pipeline test failed: $_"
                $result.MultiFileUploadSuccess = $false
                $result.MultiFileRemoveSuccess = $false
            } finally {
                foreach ($t in $tmpFiles) { Remove-Item -Path $t -ErrorAction SilentlyContinue }
            }

            if ($Details) { return $result } else { Write-Host "Success: $([string]$result.Success)"; return $true }
        } finally {
            if ($createdTemp -and -not $KeepLocal -and (Test-Path $PathTestImage)) {
                Remove-Item $PathTestImage -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
