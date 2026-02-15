# Nabil Redmann - 2026-02-15
# License: MIT

<#
    .SYNOPSIS
    Generate text using the Pollinations AI API.

    .DESCRIPTION
    Generate text based on the given prompt using the Pollinations AI API.

    .PARAMETER content
    The prompt for the text.
    Piping into this script, will use this parameter.
    .PARAMETER prompt
    Alternative to content.
    The prompt for the text.

    .PARAMETER settings
    A hashtable of settings passed to the Pollinations AI API.

    .PARAMETER model
    The model to use for text generation.

    .PARAMETER assignedModelList
    The endpoint the model is from to use for audio generation (text or audio model list).

    .PARAMETER POLLINATIONSAI_API_KEY
    The API key to use for the Pollinations AI API.
    .PARAMETER key
    Alternative to POLLINATIONSAI_API_KEY.
    The API key to use for the Pollinations AI API.

    .PARAMETER out
    The local path to save the generated text.
    
    .PARAMETER save
    Will save to the system temp folder.

    .PARAMETER details
    Will return the details of the generated text (headers + content).

    .PARAMETER getSettingsDefault
    Get the default settings for the Pollinations AI API.

    .PaRAMETER listModels
    Get the list of available models for the Pollinations AI API.

    .EXAMPLE
    PS C:\> Get-PollinationsAiText -listModels
    PS C:\> Get-PollinationsAiText -content "a cat" -model "openai" -save

    List the available models, then generate an text based on the prompt "a cat" and save it.

    .EXAMPLE
    PS C:\> Get-PollinationsAiText "a cat" -set @{"system" = "just output a comma separated list of typical colors"}

    Generate an text based on the prompt "a cat" and set the system prompt to "just output a comma separated list of typical colors".

    .EXAMPLE
    PS C:\> $env:POLLINATIONSAI_API_KEY = "sk_..."
    PS C:\> $s = Get-PollinationsAiText -getSettingsDefault
    PS C:\> $s
        Name                           Value
        ----                           -----
        system
        temperature                    1
        seed                           0
        
    PS C:\> $s.temperature = 2.0
    PS C:\> Get-PollinationsAiText -content "a cat" -settings $s -out acat.jpg

    .NOTES
    Performance -> set AssignedModelList to either 'text' or 'audio' to prevent 2 extra API calls for checking model lists

    .NOTES
    To get audio for designated models, restrict the output modalities to "audio", and use:
        -set @{"modalities" = "audio"}

    .NOTES
    Use  -Debug  to see the Write-Debug output

    TEST with httpie:
    https GET gen.pollinations.ai/text/describe%20a%20cat --verbose -A bearer -a sk_* model==nomnom

    .OUTPUTS
    The generated text content
    OR
    content and headers as @{ Headers; Content; Uri } using: -details

    Error:
        throws @{ StatusCode = <error code>; Message = <error message> }
#>
Function Get-PollinationsAiText {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '', Scope = 'Function', Target = '*')]
    [CmdletBinding(DefaultParameterSetName="None")]
    param (
        [string]
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName='None', Position=0, HelpMessage="Prompt for the text")]
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName='WithOut', Position=0, HelpMessage="Prompt for the text")]
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName='WithSave', Position=0, HelpMessage="Prompt for the text")]
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName='WithDetails', Position=0, HelpMessage="Prompt for the text")]
        [Alias("prompt")]
        $content,

        [hashtable]
        [Parameter(Mandatory=$false, ParameterSetName='None', HelpMessage="A hashtable of settings passed to the Pollinations AI API, see https://enter.pollinations.ai/api/docs#tag/genpollinationsai/GET/text/{prompt}")]
        [Parameter(Mandatory=$false, ParameterSetName='WithOut', HelpMessage="A hashtable of settings passed to the Pollinations AI API, see https://enter.pollinations.ai/api/docs#tag/genpollinationsai/GET/text/{prompt}")]
        [Parameter(Mandatory=$false, ParameterSetName='WithSave', HelpMessage="A hashtable of settings passed to the Pollinations AI API, see https://enter.pollinations.ai/api/docs#tag/genpollinationsai/GET/text/{prompt}")]
        [Parameter(Mandatory=$false, ParameterSetName='WithDetails', HelpMessage="A hashtable of settings passed to the Pollinations AI API, see https://enter.pollinations.ai/api/docs#tag/genpollinationsai/GET/text/{prompt}")]
        $settings = @{},
        
        [string]
        [Parameter(Mandatory=$false, ParameterSetName='None', HelpMessage="The model to use for text generation. Defaults to 'ztext'. See https://enter.pollinations.ai/api/docs#tag/genpollinationsai/GET/text/{prompt}.query.model")]
        [Parameter(Mandatory=$false, ParameterSetName='WithOut', HelpMessage="The model to use for text generation. Defaults to 'ztext'. See https://enter.pollinations.ai/api/docs#tag/genpollinationsai/GET/text/{prompt}.query.model")]
        [Parameter(Mandatory=$false, ParameterSetName='WithSave', HelpMessage="The model to use for text generation. Defaults to 'ztext'. See https://enter.pollinations.ai/api/docs#tag/genpollinationsai/GET/text/{prompt}.query.model")]
        [Parameter(Mandatory=$false, ParameterSetName='WithDetails', HelpMessage="The model to use for text generation. Defaults to 'ztext'. See https://enter.pollinations.ai/api/docs#tag/genpollinationsai/GET/text/{prompt}.query.model")]
        $model = "nova-fast",

        [string]
        [Parameter(Mandatory=$false, ParameterSetName='None')]
        [Parameter(Mandatory=$false, ParameterSetName='WithOut')]
        [Parameter(Mandatory=$false, ParameterSetName='WithSave')]
        [Parameter(Mandatory=$false, ParameterSetName='WithDetails')]
        $assignedModelList = "", # 'text' or 'audio' -  set to prevent 2 extra API calls for checking model lists

        [string]
        [Parameter(Mandatory=$false, ParameterSetName='None')]
        [Parameter(Mandatory=$false, ParameterSetName='WithOut')]
        [Parameter(Mandatory=$false, ParameterSetName='WithSave')]
        [Parameter(Mandatory=$false, ParameterSetName='WithDetails')]
        [Alias("key")]
        $POLLINATIONSAI_API_KEY = $env:POLLINATIONSAI_API_KEY,
        
        [switch]
        [Parameter(Mandatory=$false, ParameterSetName='None')]
        [Parameter(Mandatory=$false, ParameterSetName='WithOut')]
        [Parameter(Mandatory=$false, ParameterSetName='WithSave')]
        [Parameter(Mandatory=$false, ParameterSetName='WithDetails')]
        [Alias("nocache")]
        $bypassCache = $false,  # this only bypasses the cloudflare cache, resulting in a newly generated response.

        [string]
        [Parameter(Mandatory=$true, ParameterSetName='WithOut')]
        $out = "",
        
        [switch]
        [Parameter(Mandatory=$true, ParameterSetName='WithSave')]
        $save = $false,                                                     # save a file with `-out <name>` or `-save` to save it with a provided name to the sys temp

        [switch]
        [Parameter(Mandatory=$true, ParameterSetName='WithDetails')]
        [Parameter(Mandatory=$false, ParameterSetName='WithOut')]
        [Parameter(Mandatory=$false, ParameterSetName='WithSave')]
        [Parameter(Mandatory=$false, ParameterSetName='GetModelsList')]
        $details = $false,

        # stand alone
        [switch]
        [Parameter(Mandatory=$true, ParameterSetName='GetSettingsDefault')]
        $getSettingsDefault = $false,

        # stand alone
        [switch]
        [Parameter(Mandatory=$true, ParameterSetName='GetModelsList')]
        $listModels = $false
    )


    # ---------------------------------------------------------------


    <#
    .LINK
    https://enter.pollinations.ai/api/docs#tag/genpollinationsai/GET/text/{prompt}
    #>
    $defaultSettingsByApi = @{
        seed = 0 # 0 == random, max == 9007199254740991
        system = ""
        temperature = 1.0
        voice = "alloy" # only for openai-audio, see https://platform.openai.com/docs/guides/text-to-speech#voice-options
    }


    if ($getSettingsDefault) {
        return $defaultSettingsByApi
    }


    Function getList {
        $response = Invoke-WebRequest -Uri "https://gen.pollinations.ai/text/models" -Method Get -UseBasicParsing
        $listText = $response.content | ConvertFrom-Json |? {$_.output_modalities -Contains "text"} |% {$_ | Add-Member -MemberType NoteProperty -Name ModelsList -Value 'text'; $_} | select -ExcludeProperty 'is_specialized', 'tools'

        $response = Invoke-WebRequest -Uri "https://gen.pollinations.ai/audio/models" -Method Get -UseBasicParsing
        $listAudio = $response.content | ConvertFrom-Json |? {$_.output_modalities -Contains "text"} |% {$_ | Add-Member -MemberType NoteProperty -Name ModelsList -Value 'audio'; $_} | select -ExcludeProperty 'is_specialized', 'tools'

        return @($listText) + @($listAudio)
    }

    if ($listModels -eq $true) {
        $list = getList

        if ($details) {
            return $list
        }
        else {
            return $list | Format-Table
        }
    }


    # ---------------------------------------------------------------


    if (-not $POLLINATIONSAI_API_KEY) { throw "⚠️  POLLINATIONSAI API KEY is missing! (-key or -POLLINATIONSAI_API_KEY or set `$env:POLLINATIONSAI_API_KEY=`"sk_...`")" }


    # ---------------------------------------------------------------


    #* we do not merge the defaults into this settings object by default, because the generated URL query would be longer then necessary
    $querySettings = @{
        "model" = if (-not $model) { "nova-fast" } else { $model } # since this could be set to ""
        #"json" = "true"  # we always want the response as JSON  #! *JSON-BUG ... But that results in plaintext or json formatted error https://github.com/pollinations/pollinations/issues/7413

        "modalities[]" = "text"
    } + $settings

    # bypasses cloudflare cache
    if ($bypassCache) {
        $querySettings["cacheBuster"] = [string](Get-Date).Ticks + (Get-Random)
    }

    $headers = @{
        "Authorization" = "Bearer $POLLINATIONSAI_API_KEY"
    }

    if ($assignedModelList -eq "") {
        $assignedModelList = getList |? {$_.name -eq $model} | select -ExpandProperty ModelsList

        if ($assignedModelList -eq "") {
            throw [PSCustomObject]@{ Message = "Model unknown. Could not be found in the text or audio list of models." }
        }
    }

    $baseUrl = "https://gen.pollinations.ai/{0}" -f $assignedModelList

    # stringify query and convert prompt
    $queryStr = ($querySettings.GetEnumerator() |% { [uri]::EscapeDataString($_.Key) + "=" + [uri]::EscapeDataString($_.Value) } ) -join "&"
    $promptSlug = [uri]::EscapeDataString($content)

    # construct URI
    $uri = "{0}/{1}?{2}" -f $baseUrl, $promptSlug, $queryStr
    Write-Debug "URI: $uri"

    # check for PowerShell 7+
    $canSkip = (Get-Command Invoke-WebRequest).Parameters.ContainsKey('SkipHttpErrorCheck')

    if ($canSkip) {
        $response = Invoke-WebRequest -Uri $uri -Method Get -Headers $headers -UseBasicParsing     -SkipHttpErrorCheck    # get the error message in the response
    }
    else {
        # Fallback for PowerShell 5.1 -->  does only show the status code, since the response is dropped by Invoke-WebRequest
        try {
            $response = Invoke-WebRequest -Uri $uri -Method Get -Headers $headers -UseBasicParsing     -ErrorAction Stop
        }
        catch {
            $response = @{ StatusCode = $_.Exception.Response.StatusCode.Value__; Message = $_.Exception.Response.StatusCode }
        }
    }

    # check for errors
    if ($response.StatusCode -ne 200) {
        $err = if ($response.content) {$response.content | ConvertFrom-Json |% { @{ StatusCode = $_.status; Message = $_.error.message} }} else { $response }
        Write-Error $err

        # set error code
        $global:LASTEXITCODE = $response.StatusCode
        throw [PSCustomObject]$err
    }
    #! *JSON-BUG ... The json param does not work. It results in plaintext or json formatted error https://github.com/pollinations/pollinations/issues/7413
    # elseif ($response.Headers["Content-Type"] -notlike "*/json") {
    #     Write-Error $response.Content

    #     # set error code
    #     $global:LASTEXITCODE = 200
    #     throw [PSCustomObject]@{ StatusCode = $response.StatusCode; Message = $response.Content }
    # }


    $ret = ""

    # save the text
    if ($out -ne "" -or $save -eq $true) {

        if ($out -eq "") {
            #* NOTE: 'Content-Disposition' is always missing on the text endpoint
            $targetFilename = $response.Headers["X-Request-ID"].Trim()
            if ($targetFilename -eq "") { $targetFilename = (Get-Date).ToString("yyyyMMddHHmmss") + "-" + (Get-Random) }
            
            # dir is temp dir
            $targetDir = [IO.Path]::GetTempPath()
            
            $filepath = [IO.Path]::Combine($targetDir, $targetFilename)
        }
        else {
            $filepath = [IO.Path]::Combine($PWD, $out)
        }
        
        if ($Null -eq (Split-Path $filepath -Leaf).Split(".")[1]) { #PWSH 6+ "" -eq (Split-Path $filepath -Leaf | Split-Path -Extension)
            # 'text/html' ... 'application/json' ...
            $type = $response.Headers["Content-Type"] -split ";" | select -First 1 |% { $_ -split "/"} | Select-Object -Last 1
            if ($type -eq "" -or $type -eq "plain") { $type = "txt" }
            $filepath += "." + $type
        }
        
        Write-Debug "Filepath: $filepath"
        
        if ($response.Content.GetType().Name -eq "Byte[]") {
            # save bytes (possibly audio)
            [IO.File]::WriteAllBytes($filepath, $response.Content)
        }
        else {
            # save the text
            $response.Content | Out-File -FilePath $filepath
        }

        $ret = $filepath
    }

    if ($details -eq $true) {
        $ret = if ($ret) { @{ FilePath = $ret } } else { @{} } #filename available
        $ret = $ret +  @{
            Headers = $response.Headers
            Content = $response.Content
            Uri = $uri
        }
    }

    if ($ret) {
        return $ret
    }
    else {
        return $response.Content
    }
}