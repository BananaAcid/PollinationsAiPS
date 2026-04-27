# Nabil Redmann - 2026-04-02
# License: MIT

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '', Scope = 'Function', Target = '*')] # allow aliases
[CmdletBinding()] # allow -Debug
Param() # no parameters, but required
$script:DoDebug = $DebugPreference # for internal use - activate in all functions ("inherited" from parent (this) script) - to use: `. .\files.ps1 -Debug`
Write-Debug "Loading PollinationsAiPS/files.ps1"


$script:BaseUri = "https://media.pollinations.ai"


Function Add-PollinationsAiFile {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        $Path,
        
        [string]
        [Alias("key")]
        $POLLINATIONSAI_API_KEY = $env:POLLINATIONSAI_API_KEY,
        
        [switch]
        $Details
    )

    begin {
        $global:LASTEXITCODE = 0
        if ($script:DoDebug) { $DebugPreference = $script:DoDebug }
        if (-not $POLLINATIONSAI_API_KEY) { throw "⚠️  POLLINATIONSAI API KEY is missing! (-key or -POLLINATIONSAI_API_KEY or set `$env:POLLINATIONSAI_API_KEY=`"sk_...`")" ; return $null }
    }

    process {
        if (-not (Test-Path $Path -PathType Leaf)) {
            throw "Cannot find file path '$Path'. Only local file paths are supported for raw binary upload."
            return $null # in case of -ErrorAction SilentlyContinue
        }

        if ((Get-Item $Path).Length -le 10MB) {
            throw "File size max is 10MB"
            return $null
        }

        $localPath = Resolve-Path $Path

        Write-Debug "Uploading file: $localPath"

        $uri = "$($script:BaseUri)/upload"
        $headers = @{ Authorization = "Bearer $POLLINATIONSAI_API_KEY" }

        $response,$err,$json = script:IWR -Uri $uri -Method Post -Headers $headers -InFile $localPath -filterTextHeaders $false # we expect JSON

        $url = $null
        $contentJson = @{}
        if (-not $err) {
            Write-Debug "File uploaded successfully"

            $contentJson = $json
            $url = if ($contentJson.url) { $contentJson.url.ToString().Trim() } else { $response.Content.Trim() }
        }

        Write-Debug "File $($contentJson.id) URL: $url"

        if ($Details) { 
            $ret = @{
                id = $contentJson.id
                hash = $contentJson.id
                uri = $(if ($url) { $url } else { $uri })
                contentType = $contentJson.contentType
                size = $contentJson.size
                duplicate = $contentJson.duplicate
                Headers = $response.Headers
                Content = $response.Content
                StatusCode = $response.StatusCode
            }
            if ($err) { $ret += @{ error = $err} }
        }
        else {
            if ($err) {
                $ret = $null # in case of -ErrorAction SilentlyContinue
            }
            else {
                $ret = $url
            }
        }

        return $ret
    }
}


# Throws on 404! This is on purpose
Function Get-PollinationsAiFile {
    [CmdletBinding(DefaultParameterSetName="None")]
    param(
        [string]
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0, ParameterSetName='None')]
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0, ParameterSetName='WithOut')]
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0, ParameterSetName='WithSave')]
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0, ParameterSetName='WithDetails')]
        $Hash,
        
        [string]
        [Parameter(Mandatory=$false, ParameterSetName='None')]
        [Parameter(Mandatory=$false, ParameterSetName='WithOut')]
        [Parameter(Mandatory=$false, ParameterSetName='WithSave')]
        [Parameter(Mandatory=$false, ParameterSetName='WithDetails')]
        [Alias("key")]
        $POLLINATIONSAI_API_KEY = $env:POLLINATIONSAI_API_KEY,

        [switch]
        [Parameter(Mandatory=$true, ParameterSetName='WithDetails')]
        [Parameter(Mandatory=$false, ParameterSetName='WithOut')]
        [Parameter(Mandatory=$false, ParameterSetName='WithSave')]
        $Details = $false,

        [switch]
        [Parameter(Mandatory=$true, ParameterSetName='WithSave')]
        $Save = $false,

        [string]
        [Parameter(Mandatory=$true, ParameterSetName='WithOut')]
        $Out = ""
    )

    begin {
        $global:LASTEXITCODE = 0
        if ($script:DoDebug) { $DebugPreference = $script:DoDebug }
        #? OPTIONAL:  if (-not $POLLINATIONSAI_API_KEY) { throw "⚠️  POLLINATIONSAI API KEY is missing! (-key or -POLLINATIONSAI_API_KEY or set `$env:POLLINATIONSAI_API_KEY=`"sk_...`")" ; return $null }
    }

    process {
        $headers = @{ "Content-Type" = "application/json" }
        if ($POLLINATIONSAI_API_KEY) { $headers += @{Authorization = "Bearer $POLLINATIONSAI_API_KEY"} } # optional

        $uri = "$($script:BaseUri)/$Hash"

        $ret = ""
        $response,$err,$json = script:IWR -Uri $uri -Method Get -Headers $headers
        

        $filepath = $null
        # error: no file to save        
        if (($out -ne "" -or $save -eq $true) -and $err) {  # in case of -ErrorAction SilentlyContinue
            $filepath = "" # property should be available, but empty
            Write-Debug "Filepath: no file saved due to an error"
        }
        # save the File
        elseif ($out -ne "" -or $save -eq $true) {

            if ($out -eq "") {
                #! Content-Disposition and X-Request-ID is always empty
                #! we need to use the $hash
                $targetFilename = $Hash
                
                # dir is temp dir
                $targetDir = [IO.Path]::GetTempPath()
                
                $filepath = [IO.Path]::Combine($targetDir, $targetFilename)
            }
            else {
                $filepath = [IO.Path]::Combine($PWD, $out)
            }
            
            # check .jpg and ignore case
            if ($response.Headers["Content-Type"] -eq "image/jpeg" -and -not $filepath.EndsWith(".jpg", [System.StringComparison]::OrdinalIgnoreCase)) {
                $filepath += ".jpg"
            }

            # unknown file type - results in this form encoded -- it should be application/octet-stream
            if (($response.Headers["Content-Type"] -eq "application/x-www-form-urlencoded" -or $response.Headers["Content-Type"] -eq "application/octet-stream") -and $out -eq "") {
                
                $ext = script:Get-FileTypeFromBytes $response.Content
                if ($ext) {
                    $filepath += "." + $ext
                }
                else {
                    Write-Warning "PollinationsAI API returned for file '$Hash' a wrong Content-Type of '$($response.Headers["Content-Type"])' and no filename was provided, the file type can not be determined - no extension added. Use -Out parameter to specify the filename."
                }
            }
            # png and others, like video
            elseif ($Null -eq (Split-Path $filepath -Leaf).Split(".")[1]) { #PWSH 6+ "" -eq (Split-Path $filepath -Leaf | Split-Path -Extension)
                $type = $response.Headers["Content-Type"] -split ";" | Select -First 1 |% { $_ -split "/"} | Select -Last 1
                $filepath += "." + $type
            }
            
            Write-Debug "Filepath: $filepath"
            
            # save the File
            [IO.File]::WriteAllBytes($filepath, $response.Content)
        }

        # return details
        if ($Details -eq $true) {
            $ret = @{
                id = $response.Headers.'X-Content-Hash' -or $Hash
                hash = $Hash
                uri = $uri
                contentType = $response.Headers.'Content-Type'
                size = $response.Headers.'Content-Length'
                Headers = $response.Headers
                Content = $response.Content
                StatusCode = $response.StatusCode
            }
            if ($null -ne $filepath) { $ret += @{ filePath = $filepath } } # filename is available (or an empty string)
            if ($err) { $ret += @{ error = $err} }
        }
        # return filepath
        elseif ($Save) { $ret = $filepath }
        # return file's content
        else {
            if ($err) { 
                $ret = $null # in case of -ErrorAction SilentlyContinue
            }
            else {
                $ret = $response.Content
            }
        }
        return $ret
    }
}


Function Remove-PollinationsAiFile {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        $Hash,

        [string]
        [Alias("key")]
        $POLLINATIONSAI_API_KEY = $env:POLLINATIONSAI_API_KEY,
        
        [switch]
        $Details
    )

    begin {
        $global:LASTEXITCODE = 0
        if ($script:DoDebug) { $DebugPreference = $script:DoDebug }
        if (-not $POLLINATIONSAI_API_KEY) { throw "⚠️  POLLINATIONSAI API KEY is missing! (-key or -POLLINATIONSAI_API_KEY or set `$env:POLLINATIONSAI_API_KEY=`"sk_...`")" ; return $null }
    }

    process {
        $headers = @{ "Content-Type" = "application/json"; Authorization = "Bearer $POLLINATIONSAI_API_KEY" }
        $uri = "$($script:BaseUri)/$Hash"

        $response,$err,$json = script:IWR -Uri $uri -Method Delete -Headers $headers -ErrorAction SilentlyContinue -filterTextHeaders $false # we expect JSON, we WANT the error info

        $contentJson = @{}
        if (-not $err) {
            $contentJson = $json
            Write-Debug "File deleted: $($contentJson.deleted)"
        }

        if ($Details) { 
            $ret = @{
                deleted = $contentJson.deleted
                id = $contentJson.id
                hash = if ($contentJson.id) { $contentJson.id } else { $Hash }
                uri = $uri
                Headers = $response.Headers
                Content = $response.Content
                StatusCode = $response.StatusCode
            }
            if ($err) { $ret += @{ error = $err} }
        }
        else {
            if ($err) {
                $ret = $false
            }
            else {
                $ret = $true
            }
        }

        return $ret
    }
}


#! ENDPOINT BUGGY - https://github.com/pollinations/pollinations/pull/10449
Function Export-PollinationsAiFile {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        $Hash,
        
        [string]
        [Alias("key")]
        $POLLINATIONSAI_API_KEY = $env:POLLINATIONSAI_API_KEY,
        
        [switch]
        $Details
    )

    begin {
        $global:LASTEXITCODE = 0
        if ($script:DoDebug) { $DebugPreference = $script:DoDebug }
        #? OPTIONAL:  if (-not $POLLINATIONSAI_API_KEY) { throw "⚠️  POLLINATIONSAI API KEY is missing! (-key or -POLLINATIONSAI_API_KEY or set `$env:POLLINATIONSAI_API_KEY=`"sk_...`")" ; return $null }
    }

    process {
        $headers = @{ "Content-Type" = "application/json" }
        if ($POLLINATIONSAI_API_KEY) { $headers += @{Authorization = "Bearer $POLLINATIONSAI_API_KEY"} }

        $uri = "$($script:BaseUri)/$Hash/metadata"

        $response,$err,$json = script:IWR -Uri $uri -Method Get -Headers $headers -ErrorAction SilentlyContinue -filterTextHeaders $false # we expect JSON, we WANT the error info

        if ($Details) {
            $ret = @{
                id = $Hash
                hash = $Hash
                uri = $uri
                Headers = $response.Headers
                Content = $response.Content
                data = $json
                StatusCode = $response.StatusCode
            }
            if ($err) { $ret += @{ error = $err} }
        }
        else {
            if ($err -and $err.StatusCode -eq 404) {   # file not found info
                $ret = $false
            }
            elseif ($err) {         # not a file info -> auth or something else
                $ret = $null
            }
            else {
                $ret = $json
            }
        }

        return $ret
    }

}


Function Test-PollinationsAiFile {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        $Hash,

        [string]
        [Alias("key")]
        $POLLINATIONSAI_API_KEY = $env:POLLINATIONSAI_API_KEY,

        [switch]
        $Details
    )

    begin {
        $global:LASTEXITCODE = 0
        if ($script:DoDebug) { $DebugPreference = $script:DoDebug }
        #? OPTIONAL:  if (-not $POLLINATIONSAI_API_KEY) { throw "⚠️  POLLINATIONSAI API KEY is missing! (-key or -POLLINATIONSAI_API_KEY or set `$env:POLLINATIONSAI_API_KEY=`"sk_...`")" ; return $null }
    }

    process {
        $headers = @{ "Content-Type" = "application/json" }
        if ($POLLINATIONSAI_API_KEY) { $headers += @{Authorization = "Bearer $POLLINATIONSAI_API_KEY"} }

        $uri = "$($script:BaseUri)/$Hash"

        $response,$err,$json = script:IWR -Uri $uri -Method Head -Headers $headers -ErrorAction SilentlyContinue # we WANT the error info

        Write-Debug "File $Hash exists: $(-not $err)"

        if ($Details) { 
            $ret = @{
                success = (-not $err)
                id = $Hash # API is missing headers: X-Content-Hash,X-Content-Size
                hash = $Hash
                uri = $uri
                contentType = if (-not $err) { $response.Headers.'Content-Type' }
                contentLength = if (-not $err) { $response.Headers.'Content-Length' }
                Headers = $response.Headers
                StatusCode = $response.StatusCode
            }
            if ($err) { $ret += @{ error = $err} }
        }
        else {
            if ($err -and $err.StatusCode -eq 404) {   # file not found info
                $ret = $false
            }
            elseif ($err) {         # not a file info -> auth or something else
                $ret = $null
            }
            else {
                $ret = $true   # file found info
            }
        }

        return $ret
    }
}


Function Get-PollinationsAiEncodedImage {
    # `data:image/png;base64,` or  `data:image/jpeg;base64,`
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$Path,
        [switch]$Details
    )

    begin {
        $global:LASTEXITCODE = 0
        if ($script:DoDebug) { $DebugPreference = $script:DoDebug }
    }

    process {
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
            if ($bytes[0] -eq 0x42 -and $bytes[1] -eq 0x4D) { $type = "bmp" }

            if ($type -eq "") { throw "File is not an jpeg/png/bmp image!" }

            Write-Debug "Image type: $type"

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


<# 
    Invoke-WebRequest fallback for PowerShell 5.1 (but looses the error message from within the response's content)
#>
Function script:IWR {
    param(
        [Parameter(Mandatory=$true)]$Uri,
        $Method = "Get",
        $Headers = @{},
        $filterTextHeaders = $true,   # in case we expect JSON, set filterTextHeaders to false
        
        $InFile = $null
    )

    if ($script:DoDebug) { $DebugPreference = $script:DoDebug }

    Write-Debug "Request $Method $uri"

    
    # prepare additional (known) parameters, if needed
    if ($InFile) {
        $params = @{ InFile = $InFile }
    }
    else {
        $params = @{}
    }
    
    # check for PowerShell 7+
    $canSkip = (Get-Command Invoke-WebRequest).Parameters.ContainsKey('SkipHttpErrorCheck')

    if ($canSkip) {
        $response = Invoke-WebRequest -Uri $Uri -Method $Method -Headers $Headers   @params   -UseBasicParsing     -SkipHttpErrorCheck    # get the error message in the response
    }
    else {
        # Fallback for PowerShell 5.1 -->  does only show the status code, since the response is dropped by Invoke-WebRequest
        try {
            $response = Invoke-WebRequest -Uri $Uri -Method $Method -Headers $Headers   @params   -UseBasicParsing     -ErrorAction Stop
        }
        catch {
            # no message from content possible on error in PS 5.1 ... Headers are just the keynames and no values
            #$response = @{ StatusCode = $_.Exception.Response.StatusCode.Value__; Message = $_.Exception.Response.StatusCode; Headers = $_.Exception.Response.Headers }
            
            # get the content properly and extract headers ---------
            $stream = $_.Exception.Response.GetResponseStream()
            if ($stream.CanSeek) { $stream.Position = 0 }

            # Read into a MemoryStream to get all bytes
            $memoryStream = New-Object System.IO.MemoryStream
            $stream.CopyTo($memoryStream)
            $bytes = $memoryStream.ToArray()
            $memoryStream.Dispose()
            $contentString = [System.Text.Encoding]::UTF8.GetString($bytes)
            
            # Extract Headers properly, WebHeaderCollection -> Hashtable
            $headers = @{}
            foreach ($key in $_.Exception.Response.Headers.AllKeys) { $headers[$key] = $_.Exception.Response.Headers[$key] }

            $response = [PSCustomObject]@{
                StatusCode = [int]$_.Exception.Response.StatusCode
                Content    =  $contentString
                #RawBytes   = $bytes         # The binary version
                Headers    = $headers
            }
        }
    }

    # check for errors (image endpoint format and media storage endpoint format)
    $err = $null
    if ($response.StatusCode -ne 200) {
        Write-Debug "Error status code: $($response.StatusCode)"
        if ($response.Content -and $response.Headers["Content-Type"] -like "application/json") {
            $content = $response.Content | ConvertFrom-Json
            $err = [PSCustomObject]@{
                StatusCode = if ($content.status) {$content.status} else {$response.StatusCode}
                Message = if ($content.error -and $content.error.message) {$content.error.message} else {$content.error}
                ResponseInstance = $response
            }
        }
        else {
            $err = [PSCustomObject]@{
                StatusCode = $response.StatusCode
                Message = $response.Content
                Uri = $Uri
                ResponseInstance = $response
            }
        }

        Write-Debug "Error message: $($err.Message)"
        #Write-Error "$($err.StatusCode): $($err.Message)"

        # set error code
        $global:LASTEXITCODE = $err.StatusCode
        throw $err
    }
    # API is broken - Status code 200, but there is an error message in the content
    elseif ($filterTextHeaders -and ($response.Headers["Content-Type"] -like "text/*" -or $response.Headers["Content-Type"] -like "application/json")) {
        Write-Debug "Error unexpected content with content type: $($response.Headers["Content-Type"])"
        $err = [PSCustomObject]@{
            StatusCode = $response.StatusCode
            Message = "Unexpected content with content type: " + $response.Headers["Content-Type"]
            Uri = $Uri
            ResponseInstance = $response
        }

        Write-Debug "Error content: $($response.Content)"
        # Write-Error $response.Content
        # Write-Error ($err.StatusCode + ": " + $err.Message)

        # set error code
        $global:LASTEXITCODE = 200
        throw $err
    }

    # check for JSON, if $filterTextHeaders is false or -ErrorAction is SilentlyContinue
    $json = $null
    if ($response.Headers["Content-Type"] -like "application/json") {
        $json = $response.Content | ConvertFrom-Json
    }

    # application/x-www-form-urlencoded  .... storage api returns this
    # ... the content is bytes (currently)

    return $response, $err, $json
}


<#
    Get file extension from bytes - Advanced Windows version or simple fallback
#>
Function script:Get-FileTypeFromBytes {
    param (
        [byte[]]$Content
    )

    # I bumped this to 12 to prevent strict-mode index errors, 
    # since WAV and AVI check up to the 11th byte.
    if ($null -eq $Content -or $Content.Count -lt 12) {
        return $false
    }

    # Extract the first few bytes for comparison
    # We use a switch with -CaseSensitive or simple byte matching
    switch -Regex ($null) {
        # JPEG: FF D8 FF
        { $Content[0] -eq 0xFF -and $Content[1] -eq 0xD8 -and $Content[2] -eq 0xFF } { "jpg" }
        
        # PNG: 89 50 4E 47
        { $Content[0] -eq 0x89 -and $Content[1] -eq 0x50 -and $Content[2] -eq 0x4E -and $Content[3] -eq 0x47 } { "png" }
        
        # BMP: 42 4D
        { $Content[0] -eq 0x42 -and $Content[1] -eq 0x4D } { "bmp" }
        
        # AVI: 52 49 46 46 (RIFF) followed by 'AVI ' at offset 8
        { $Content[0] -eq 0x52 -and $Content[1] -eq 0x49 -and $Content[2] -eq 0x46 -and $Content[3] -eq 0x46 -and 
          $Content[8] -eq 0x41 -and $Content[9] -eq 0x56 -and $Content[10] -eq 0x49 } { "avi" }

        # WAV: 52 49 46 46 (RIFF) followed by 'WAVE' at offset 8
        { $Content[0] -eq 0x52 -and $Content[1] -eq 0x49 -and $Content[2] -eq 0x46 -and $Content[3] -eq 0x46 -and 
          $Content[8] -eq 0x57 -and $Content[9] -eq 0x41 -and $Content[10] -eq 0x56 -and $Content[11] -eq 0x45 } { "wav" }
        
        # MPG (MPEG): 00 00 01 BA or 00 00 01 B3
        { $Content[0] -eq 0x00 -and $Content[1] -eq 0x00 -and $Content[2] -eq 0x01 -and ($Content[3] -eq 0xBA -or $Content[3] -eq 0xB3) } { "mpg" }
        
        # HEIF: Looks for 'ftyp' at offset 4
        { $Content[4] -eq 0x66 -and $Content[5] -eq 0x74 -and $Content[6] -eq 0x79 -and $Content[7] -eq 0x70 } { "heif" }

        # MP3 (With ID3 Tag): 49 44 33 ("ID3")
        { $Content[0] -eq 0x49 -and $Content[1] -eq 0x44 -and $Content[2] -eq 0x33 } { "mp3" }

        # MP3 (Without ID3 Tag, MPEG ADTS sync word): FF FB, FF F3, or FF F2
        { $Content[0] -eq 0xFF -and ($Content[1] -eq 0xFB -or $Content[1] -eq 0xF3 -or $Content[1] -eq 0xF2) } { "mp3" }

        # AC3: 0B 77
        { $Content[0] -eq 0x0B -and $Content[1] -eq 0x77 } { "ac3" }
        
        Default { $null }
    }
}
