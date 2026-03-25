Function ConvertFrom-AnsiEscapedString {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true, Position=0)]
        [string]$InputValObject
    )

    begin {
        $escChar = [char]27

        function Convert-Escapes {
            param([string]$s)
            if ($null -eq $s) { return $s }

            # Protect fenced triple-backtick blocks first
            $literals = New-Object System.Collections.Generic.List[string]
            $tokenIndex = 0

            # newlines and returns
            $s = $s -replace '(?<!\\)\\n', "`n"
            $s = $s -replace '(?<!\\)\\r', "`r"

            # new lines are messed up
            # # Protect ```...``` (multiline, non-greedy)
            # $s = [Regex]::Replace($s, '```([\s\S]*?)```', {
            #     param($m)
            #     $literals.Add($m.Value)            # store the whole fenced block including backticks
            #     $token = "___ANSI_LITERAL_{0}___" -f $tokenIndex
            #     $tokenIndex++
            #     return $token
            # })

            # Then protect single-backtick inline spans `...` (no newlines)
            $s = [Regex]::Replace($s, '`([^`\r\n]*)`', {
                param($m)
                $literals.Add($m.Value)            # store with backticks
                $token = "___ANSI_LITERAL_{0}___" -f $tokenIndex
                $tokenIndex++
                return $token
            })

            # \x5c033 -> ESC
            $s = $s -replace '\\x5c0*33', $escChar

            # common escape forms
            $s = $s -replace '\\033', $escChar
            $s = $s -replace '\\e', $escChar
            $s = $s -replace '\\x1b', $escChar
            $s = $s -replace '\\x1B', $escChar


            # replace generic \xHH sequences safely
            while ($s -match '\\x([0-9A-Fa-f]{2})') {
                $hex = $matches[1]
                $char = [char]([Convert]::ToInt32($hex,16))
                $s = [Regex]::Replace($s, "\\x$hex", [Regex]::Escape($char), 1)
                $s = $s -replace [Regex]::Escape($char), $char
            }

            # Restore literal spans (tokens replaced with original stored values)
            for ($i = 0; $i -lt $literals.Count; $i++) {
                $token = "___ANSI_LITERAL_{0}___" -f $i
                $orig = $literals[$i]
                # Use Regex::Replace with escaped token -> escaped original, then unescape inserted original
                $s = [Regex]::Replace($s, [Regex]::Escape($token), [Regex]::Escape($orig))
                $s = $s -replace [Regex]::Escape($orig), $orig
            }

            return $s
        }

        $collected = ""
    }

    process {
        $inputVal = $InputValObject
        if ($inputVal -is [System.Array]) {
            $inputVal = ($inputVal -join "`n")
        } elseif ($null -ne $inputVal -and $inputVal -isnot [string]) {
            $inputVal = $inputVal.ToString()
        }

        $out = Convert-Escapes -s $inputVal

        # if ($null -ne $out) {
        #     Write-Host $out  -noNewline
        #     if ($out -match "(`r`n|`n)$") { Write-Host "" }
        # }

        $collected += $out
    }

    end {
        return $collected
    }
}

Function Get-PollinationsAiByokWeb {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory=$false, ParameterSetName='None')]
        [Parameter(Mandatory=$false, ParameterSetName='Add')]
        [Parameter(Mandatory=$false, ParameterSetName='Init')]
        $Url = "http://localhost:8888/",
        
        [string]
        [Parameter(Mandatory=$false, ParameterSetName='None')]
        [Parameter(Mandatory=$false, ParameterSetName='Add')]
        [Parameter(Mandatory=$false, ParameterSetName='Init')]
        [Alias("key")]
        $AppKey = "pk_2ZpluqiajXYP5XfG",

        [switch]
        [Parameter(Mandatory=$true, ParameterSetName='Add')]
        $Add = $false, # Add the API Key to the profile and init within the current environment

        [switch]
        [Parameter(Mandatory=$true, ParameterSetName='Init')]
        $Init = $false # if not added, still init the API key within the current environment
    )

    # 1. Setup the listener
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add($Url)

    try {
        $listener.Start()
        Write-Debug "Server started on $Url"
    }
    catch {
        Write-Error "Failed to start the server. Port already in use?"
        $port = ([uri]$Url).Port
        netstat -ano | findstr ":$port"
        throw $_
    }

    # 2. Open the browser
    $authUrl = "https://enter.pollinations.ai/authorize?redirect_url={0}&app_key={1}" -f [System.Web.HttpUtility]::UrlEncode($Url), $AppKey
    Start-Process $authUrl


    $apiKey = $null
    $canceled = $null

    try {    
        # 2. Loop until we get the api_key query parameter
        Write-Host "Waiting for API Key... Press ESC to cancel." -ForegroundColor Yellow

        while ($null -eq $apiKey -and $null -eq $canceled) {

            $asyncResult = $listener.BeginGetContext($null, $null)
            
            while (-not $asyncResult.AsyncWaitHandle.WaitOne(50)) {

                if ([System.Console]::KeyAvailable) { #  always true: $Host.UI.RawUI.KeyAvailable
                    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    # on esc
                    if ($key.Character -eq [ConsoleKey]::Escape) {
                        $canceled = $true
                        break
                    }
                }
            }
            if ($canceled) {
                Write-Debug "Canceled by user."
                break
            }
            $context = $listener.EndGetContext($asyncResult)

            $request = $context.Request
            $apiKey = $request.QueryString["api_key"]
            $canceled = $request.QueryString["canceled"]
            $response = $context.Response
            $response.ContentType = "text/html"

            if ($null -ne $canceled) {
                $html = @"
<html style="display: grid; place-items: center;"><head><title>API Key - Pollinations AI</title></head><body style=" height: fit-content; font-family: sans-serif; ">
    <h1>Canceled!</h1>
    <p>API Key <b>NOT captured</b>. You can close the window.</p>
    <script>setTimeout(function() { window.close(); }, 1000);</script>
</body></html>
"@
                Write-Debug "Canceled"
            }
            elseif ($null -eq $apiKey) {
                # Serve the JS redirector
                $html = @"
<html style="display: grid; place-items: center;"><head><title>API Key - Pollinations AI</title></head><body style=" height: fit-content; font-family: sans-serif; ">
    <p>Processing...</p>
    <script>
        if (window.location.hash) {
            var hash = window.location.hash.substring(1);
            var params = new URLSearchParams(hash);
            var key = params.get('api_key');
            if (key) window.location.href = window.location.origin + '/?api_key=' + key;
        }
        else window.location.href = window.location.origin + '/?canceled=true';
    </script>
</body></html>
"@
            } else {
                # Serve the Success page
                $html = @"
<html style="display: grid; place-items: center;"><head><title>API Key - Pollinations AI</title></head><body style=" height: fit-content; font-family: sans-serif; ">
    <h1>Success!</h1>
    <p>API Key captured. You can close the window.</p>
    <script>setTimeout(function() { window.close(); }, 1000);</script>
</body></html>
"@
                Write-Debug "Successfully captured API Key: $apiKey"
            }

            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
        }
    }
    catch {
        $err = $_
        Write-Error "Error: $_"
    }
    finally {
        if ($listener.IsListening) { $listener.Stop() }
        $listener.Close()
        Write-Debug "Server stopped."

        if ($null -ne $err) {
            throw $err
        }
    }

    if ($Add) {
        if ($null -ne $apiKey) {   
            "`n`n`$env:POLLINATIONSAI_API_KEY = `"$($apiKey)`"" >> $PROFILE.CurrentUserAllHosts
            Write-Host "API Key added as `$env:POLLINATIONSAI_API_KEY to $($PROFILE.CurrentUserAllHosts)" -ForegroundColor Green
        }
        else {
            Write-Error "API Key not added to environment. Failed to capture API Key."
        }
    }
    if ($null -ne $apiKey -and ($Add -or $Init) ) {
        $env:POLLINATIONSAI_API_KEY = $apiKey # activate in session
    }

    return $apiKey
}




# https://datatracker.ietf.org/doc/html/rfc8628
# https://enter.pollinations.ai/api/docs#tag/-bring-your-own-pollen -> 🖥️ CLIs & Headless Apps (Device Flow)
# .Alias Get-PollinationsAiDeviceToken
function Get-PollinationsAiByok {
    param(
        [string]
        [Parameter(Mandatory=$false, ParameterSetName='None')]
        [Parameter(Mandatory=$false, ParameterSetName='Add')]
        [Parameter(Mandatory=$false, ParameterSetName='Init')]
        [Alias("AppKey")]
        [Alias("Key")]
        $ClientId = "pk_2ZpluqiajXYP5XfG",

        [switch]
        [Parameter(Mandatory=$true, ParameterSetName='Add')]
        $Add = $false, # Add the API Key to the profile and init within the current environment

        [switch]
        [Parameter(Mandatory=$true, ParameterSetName='Init')]
        $Init = $false, # if not added, still init the API key within the current environment


        [int]
        [Parameter(Mandatory=$false, ParameterSetName='None')]
        [Parameter(Mandatory=$false, ParameterSetName='Add')]
        [Parameter(Mandatory=$false, ParameterSetName='Init')]
        $TimeoutSeconds = 0,

        [int]
        [Parameter(Mandatory=$false, ParameterSetName='None')]
        [Parameter(Mandatory=$false, ParameterSetName='Add')]
        [Parameter(Mandatory=$false, ParameterSetName='Init')]
        $IntervalSeconds = 1
    )

    $BaseUrl = "https://enter.pollinations.ai/api/device"

    # initiate device code request - get handshake token and activation dialog url
    Write-Host "Requesting device code..." -ForegroundColor Cyan
    $deviceInfo = Invoke-RestMethod -Uri "$BaseUrl/code" -Method Post -Body (@{
        client_id = $ClientId
        scope     = "generate"
    } | ConvertTo-Json) -ContentType "application/json"

    # extra info for the user
    Write-Host "`nVisit: $($deviceInfo.verification_uri_complete)" -ForegroundColor Yellow
    Write-Host "Code: $($deviceInfo.user_code)" -ForegroundColor Green
    Write-Host "Waiting for confirmation... Press ESC to cancel." -ForegroundColor Gray

    
    # open browser with device code and pollen confirmation
    Start-Process $deviceInfo.verification_uri_complete

    $accessToken = $null
    $canceled = $false
    $lastRequestTime =[DateTime]::MinValue
    $startTime = Get-Date
    $intervalSeconds = if ($IntervalSeconds -gt 0) { $IntervalSeconds } else { [double]$deviceInfo.interval }
    $expirationTime = if ($TimeoutSeconds -gt 0) { $TimeoutSeconds } else { [double]$deviceInfo.expires_in }

    # waiting for API
    while ($null -eq $accessToken) {
        $currentTime = Get-Date

        # check for total expiration
        if (($currentTime - $startTime).TotalSeconds -gt $expirationTime) {
            Write-Warning "`nAuthorization request timed out after $expirationTime seconds."
            return $null
        }

        # check for ESC key
        if ([System.Console]::KeyAvailable) { #  always true: $Host.UI.RawUI.KeyAvailable
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            # on esc
            if ($key.Character -eq [ConsoleKey]::Escape) {
                $canceled = $true
                break
            }
        }

        # API polling
        if (($currentTime - $lastRequestTime).TotalSeconds -ge $intervalSeconds) {
            $lastRequestTime = Get-Date 

            try {
                $tokenResponse = Invoke-RestMethod -Uri "$BaseUrl/token" -Method Post -Body (@{
                    device_code = $deviceInfo.device_code
                } | ConvertTo-Json) -ContentType "application/json" -ErrorAction Stop
                
                $accessToken = $tokenResponse.access_token
            }
            catch {
                # handle HTTP error responses
                if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
                    try {
                        # Parse the error JSON
                        $errorData = $_.ErrorDetails.Message | ConvertFrom-Json
                        
                        if ($errorData.error -eq "access_denied") {
                            Write-Host "" # newline, since warning eats it
                            Write-Warning "Access denied by the user."
                            return $null
                        }
                        elseif ($errorData.error -eq "expired_token") {
                            Write-Error "`nThe device code has expired."
                            return $null
                        }
                        elseif ($errorData.error -eq "authorization_pending" -or $errorData.error.code -eq "NOT_FOUND") {
                            # Expected states while waiting for user action. Do nothing.
                        }
                    }
                    catch {
                        # JSON parsing failed, safely ignore and continue polling
                    }
                }
            }
        }

        # keep responsiveness high and CPU usage low
        Start-Sleep -Milliseconds 100
    }

    if ($canceled) {
        Write-Host "`nOperation canceled by user." -ForegroundColor Red
        return $null
    }

    if ($accessToken) {
        Write-Host "`nSuccessfully retrieved access token!" -ForegroundColor Green
    }

    if ($Add) {
        if ($null -ne $accessToken) {   
            "`n`n`$env:POLLINATIONSAI_API_KEY = `"$($accessToken)`"" >> $PROFILE.CurrentUserAllHosts
            Write-Host "API Key added as `$env:POLLINATIONSAI_API_KEY to $($PROFILE.CurrentUserAllHosts)" -ForegroundColor Green
        }
        else {
            Write-Error "API Key not added to environment. Failed to retrieve access token."
        }
    }
    if ($null -ne $accessToken -and ($Add -or $Init) ) {
        $env:POLLINATIONSAI_API_KEY = $accessToken # activate in session
    }

    return $accessToken
}