# Nabil Redmann - 2026-04-02
# License: MIT

Function Add-PollinationsAiFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)] [string]$Path,
        [string][Alias("key")]$POLLINATIONSAI_API_KEY = $env:POLLINATIONSAI_API_KEY,
        [switch]$Details
    )
    process {
        if (-not $POLLINATIONSAI_API_KEY) { 
            throw "⚠️  POLLINATIONSAI API KEY is missing! (-key or -POLLINATIONSAI_API_KEY or set `$env:POLLINATIONSAI_API_KEY=`"sk_...`")" 
        }

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
            } else { return $url }
        } catch {
            throw $_
        }
    }
}

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
                    Headers = $response.Headers;
                    Content = $response.Content;
                    "Content-Type" = $response.Headers.'Content-Type';
                    "Content-Length" = $response.Headers.'Content-Length';
                }
            } else {
                return $response.Content
            }
        } catch {
            throw $_
        }
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
        if (-not $POLLINATIONSAI_API_KEY) { 
            throw "⚠️  POLLINATIONSAI API KEY is missing! (-key or -POLLINATIONSAI_API_KEY or set `$env:POLLINATIONSAI_API_KEY=`"sk_...`")" 
        }
        $headers = @{ "Content-Type" = "application/json"; Authorization = "Bearer $POLLINATIONSAI_API_KEY" }

        $uri = "https://media.pollinations.ai/$Hash"
        try {
            $response = Invoke-WebRequest -Uri $uri -Method Delete -Headers $headers -ErrorAction Stop
            if ($Details) { 
                $contentJson = $response.Content | ConvertFrom-Json
                return @{
                    deleted = $contentJson.deleted
                    id = $contentJson.id
                    Headers = $response.Headers
                    Content = $response.Content
                } 
            } else { return $true }
        } catch {
            if ($_.Exception.Response -and $_.Exception.Response.StatusCode.value__ -eq 404) {
                if ($Details) { 
                    $contentJson = $_.Exception.Response.Content | ConvertFrom-Json
                    return @{
                        deleted = $contentJson.deleted
                        id = $contentJson.id
                        Headers = $_.Exception.Response.Headers
                        Content = $_.Exception.Response.Content
                    } 
                } else { return $false }
            } else { throw $_ }
        }
    }
}

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
            if ($Details) { return @{ Headers = $response.Headers; Content = $response.Content } } else { return ($response.Content | ConvertFrom-Json) }
        } catch {
            throw $_
        }
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
        if (-not $POLLINATIONSAI_API_KEY) { 
            throw "⚠️  POLLINATIONSAI API KEY is missing! (-key or -POLLINATIONSAI_API_KEY or set `$env:POLLINATIONSAI_API_KEY=`"sk_...`")" 
        }

        $uri = "https://media.pollinations.ai/$Hash"
        try {
            $response = Invoke-WebRequest -Uri $uri -Method Head -UseBasicParsing -ErrorAction Stop
            if ($Details) { 
                return @{
                    ContentType = $response.Headers.'Content-Type'
                    ContentLength = $response.Headers.'Content-Length'
                    Headers = $response.Headers
                } 
            } else { return $true }
        } catch {
            if ($_.Exception.Response -and $_.Exception.Response.StatusCode.value__ -eq 404) {
                if ($Details) { 
                    return @{
                        ContentType = $_.Exception.Response.Headers.'Content-Type'
                        ContentLength = $_.Exception.Response.Headers.'Content-Length'
                        Headers = $_.Exception.Response.Headers
                    } 
                } else { return $false }
            } else { throw $_ }
        }
    }
}

Function Measure-PollinationsAiFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][string]$Path,
        [string][Alias("key")]$POLLINATIONSAI_API_KEY = $env:POLLINATIONSAI_API_KEY,
        [switch]$KeepLocal,
        [switch]$Details
    )

    process {
        if (-not $POLLINATIONSAI_API_KEY) { 
            throw "⚠️  POLLINATIONSAI API KEY is missing! (-key or -POLLINATIONSAI_API_KEY or set `$env:POLLINATIONSAI_API_KEY=`"sk_...`")" 
        }

        $createdTemp = $false
        try {
            if ([string]::IsNullOrWhiteSpace($Path)) {
                # use stable online test image instead of an ad hoc text file
                $Path = Join-Path ([IO.Path]::GetTempPath()) ("pollinationsaitest_{0}.png" -f [guid]::NewGuid())
                $sourceUrl = "https://upload.wikimedia.org/wikipedia/en/thumb/8/80/Wikipedia-logo-v2.svg/960px-Wikipedia-logo-v2.svg.png"
                Invoke-WebRequest -Uri $sourceUrl -OutFile $Path -UseBasicParsing -ErrorAction Stop
                $createdTemp = $true
            } else {
                if (-not (Test-Path $Path -PathType Leaf)) {
                    throw "Path not found: $Path"
                }
            }

            $upload = Add-PollinationsAiFile -Path $Path -POLLINATIONSAI_API_KEY $POLLINATIONSAI_API_KEY -Details
            if ($null -eq $upload -and -not $Details) {
                # fallback in case Function returns URL only
                $url = Add-PollinationsAiFile -Path $Path -POLLINATIONSAI_API_KEY $POLLINATIONSAI_API_KEY
                $hash = $url -replace '^.*/',''
            } elseif ($Details) {
                $hash = ($upload.Content | ConvertFrom-Json).url -replace '^.*/',''
            }

            $check1 = Test-PollinationsAiFile -Hash $hash -POLLINATIONSAI_API_KEY $POLLINATIONSAI_API_KEY -Details
            $get1   = Get-PollinationsAiFile -Hash $hash -POLLINATIONSAI_API_KEY $POLLINATIONSAI_API_KEY -Details
            $meta1  = Export-PollinationsAiFile -Hash $hash -POLLINATIONSAI_API_KEY $POLLINATIONSAI_API_KEY -Details
            $rm1    = Remove-PollinationsAiFile -Hash $hash -POLLINATIONSAI_API_KEY $POLLINATIONSAI_API_KEY -Details
            $check2 = Test-PollinationsAiFile -Hash $hash -POLLINATIONSAI_API_KEY $POLLINATIONSAI_API_KEY -Details

            $result = [pscustomobject]@{
                InputPath      = $Path
                Uploaded       = $true
                Hash           = $hash
                UploadResult   = $upload
                TestBefore     = $check1
                GetResult      = if ($Details) { $get1 } else { $null }
                Metadata       = if ($Details) { $meta1 } else { $null }
                RemoveResult   = $rm1
                TestAfter      = $check2
                Success        = ($check1.Headers.'X-Status' -eq '200' -and $check2.Headers.'X-Status' -ne '200')
            }
            if ($Details) { return $result } else { return $result.Success }
        } finally {
            if ($createdTemp -and -not $KeepLocal -and (Test-Path $Path)) {
                Remove-Item $Path -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
