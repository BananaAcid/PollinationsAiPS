# Nabil Redmann - 2026-02-15
# License: MIT

<#
    .SYNOPSIS
    Generate an image using the Pollinations AI API.

    .DESCRIPTION
    Generate an image based on the given prompt using the Pollinations AI API.

    .PARAMETER content
    The prompt for the image.
    Piping into this script, will use this parameter.
    .PARAMETER prompt
    Alternative to content.
    The prompt for the image.

    .PARAMETER settings
    A hashtable of settings passed to the Pollinations AI API.

    .PARAMETER model
    The model to use for image generation. Defaults to 'zimage'.

    .PARAMETER POLLINATIONSAI_API_KEY
    The API key to use for the Pollinations AI API.
    .PARAMETER key
    Alternative to POLLINATIONSAI_API_KEY.
    The API key to use for the Pollinations AI API.

    .PARAMETER bypassCache
    Does bypasses the cloudflare cache, and sets the seed to random, resulting in a newly generated response.

    .PARAMETER out
    The local path to save the generated image.
    
    .PARAMETER save
    Will save to the system temp folder.

    .PARAMETER details
    Will return the details of the generated text (headers + content).

    .PARAMETER getSettingsDefault
    Get the default settings for the Pollinations AI API.

    .PaRAMETER listModels
    Get the list of available models for the Pollinations AI API.

    .EXAMPLE
    PS C:\> Get-PollinationsAiImage -listModels
    PS C:\> Get-PollinationsAiImage -content "a cat" -model "flux" -save

    List the available models, then generate an image based on the prompt "a cat" using the 'flux' model.

    .EXAMPLE
    PS C:\> $env:POLLINATIONSAI_API_KEY = "sk_..."
    PS C:\> $s = Get-PollinationsAiImage -getSettingsDefault
    PS C:\> $s
        Name                           Value
        ----                           -----
        safe                           false
        image
        enhance                        false
        negative_prompt                worst quality, blurry
        transparent                    false
        quality                        medium
        width                          1024
        height                         1024
        seed                           0

    PS C:\> $s.width = 512
    PS C:\> $s.height = 512
    PS C:\> Get-PollinationsAiImage -content "a cat" -settings $s -out acat.jpg

    First set the API key, then get the default settings, then output the settings (just by typing $s), then modify them, then generate an image based on the prompt "a cat" using the modified settings.

    .NOTES
    Use  -Debug  to see the Write-Debug output

    TEST with httpie:
    https GET gen.pollinations.ai/image/a%20cat --verbose -A bearer -a sk_* model==zimage

    .OUTPUTS
    The generated image as a byte array
    OR
    content and headers as @{ Headers; Content; Uri } using: -details
    OR
    The local path to generated file using: -save
    OR
    The local path to generated file using: -out <name.jpg>

    Error:
        throws @{ StatusCode = <error code>; Message = <error message> }
#>
Function Get-PollinationsAiImage {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '', Scope = 'Function', Target = '*')]
    [CmdletBinding(DefaultParameterSetName="None")]
    param (
        [string]
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName='None', Position=0, HelpMessage="Prompt for the image")]
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName='WithOut', Position=0, HelpMessage="Prompt for the image")]
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName='WithSave', Position=0, HelpMessage="Prompt for the image")]
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName='WithDetails', Position=0, HelpMessage="Prompt for the image")]
        [Alias("prompt")]
        $content,

        [hashtable]
        [Parameter(Mandatory=$false, ParameterSetName='None', HelpMessage="A hashtable of settings passed to the Pollinations AI API, see https://enter.pollinations.ai/api/docs#tag/genpollinationsai/GET/image/{prompt}")]
        [Parameter(Mandatory=$false, ParameterSetName='WithOut', HelpMessage="A hashtable of settings passed to the Pollinations AI API, see https://enter.pollinations.ai/api/docs#tag/genpollinationsai/GET/image/{prompt}")]
        [Parameter(Mandatory=$false, ParameterSetName='WithSave', HelpMessage="A hashtable of settings passed to the Pollinations AI API, see https://enter.pollinations.ai/api/docs#tag/genpollinationsai/GET/image/{prompt}")]
        [Parameter(Mandatory=$false, ParameterSetName='WithDetails', HelpMessage="A hashtable of settings passed to the Pollinations AI API, see https://enter.pollinations.ai/api/docs#tag/genpollinationsai/GET/image/{prompt}")]
        $settings = @{},
        
        [string]
        [Parameter(Mandatory=$false, ParameterSetName='None', HelpMessage="The model to use for image generation. Defaults to 'zimage'. See https://enter.pollinations.ai/api/docs#tag/genpollinationsai/GET/image/{prompt}.query.model")]
        [Parameter(Mandatory=$false, ParameterSetName='WithOut', HelpMessage="The model to use for image generation. Defaults to 'zimage'. See https://enter.pollinations.ai/api/docs#tag/genpollinationsai/GET/image/{prompt}.query.model")]
        [Parameter(Mandatory=$false, ParameterSetName='WithSave', HelpMessage="The model to use for image generation. Defaults to 'zimage'. See https://enter.pollinations.ai/api/docs#tag/genpollinationsai/GET/image/{prompt}.query.model")]
        [Parameter(Mandatory=$false, ParameterSetName='WithDetails', HelpMessage="The model to use for image generation. Defaults to 'zimage'. See https://enter.pollinations.ai/api/docs#tag/genpollinationsai/GET/image/{prompt}.query.model")]
        $model = "zimage",
        
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
        $bypassCache = $false,  # does bypasses the cloudflare cache, and sets the seed to random, resulting in a newly generated response.

        [string]
        [Parameter(Mandatory=$true, ParameterSetName='WithOut')]
        $out = "",
        
        [switch]
        [Parameter(Mandatory=$true, ParameterSetName='WithSave')]
        $save = $false,                                                     # save a file with `-out <name.jpg>` or `-save` to save it with a provided name to the sys temp

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
    https://enter.pollinations.ai/api/docs#tag/genpollinationsai/GET/image/{prompt}
    #>
    $defaultSettingsByApi = @{
        width = 1024            # models have different min and max (1024 should always work)
        height = 1024
        seed = 0                # -1 == random, min 0, max 2147483647
        enhance = "false"
        negative_prompt = "worst quality, blurry"
        safe = "false"
        quality = "medium"      # gptimage only
        image = ""              # Reference image URL(s). Comma/pipe separated for multiple.
        transparent = "false"   # gptimage only

        # video models
        duration = ""           # video models only, veo: 4, 6, or 8. seedance: 2-10
        aspectRatio = ""        # video models only, veo, seedance: 16:9 or 9:16
        audio = "false"         # veo only
    }


    if ($getSettingsDefault) {
        return $defaultSettingsByApi
    }


    if ($listModels -eq $true) {
        $response = Invoke-WebRequest -Uri "https://gen.pollinations.ai/image/models" -Method Get -UseBasicParsing
        $list = $response.content | ConvertFrom-Json |? {$_.output_modalities -Contains "image"}
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
        "model" = if (-not $model) { "zimage" } else { $model }
    } + $settings

    # bypasses cloudflare cache
    if ($bypassCache) {
        $querySettings["cacheBuster"] = [string](Get-Date).Ticks + (Get-Random)
        $querySettings["seed"] = -1
    }

    $headers = @{
        "Authorization" = "Bearer $POLLINATIONSAI_API_KEY"
    }

    $baseUrl= "https://gen.pollinations.ai/image"

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
    elseif ($response.Headers["Content-Type"] -like "text/*" -or $response.Headers["Content-Type"] -like "application/*") {
        Write-Error $response.Content

        # set error code
        $global:LASTEXITCODE = 200
        throw [PSCustomObject]@{ StatusCode = $response.StatusCode; Message = $response.Content }
    }


    $ret = ""
    # save the image
    if ($out -ne "" -or $save -eq $true) {

        if ($out -eq "") {
            # filename from header, extract filename from within filename arg (might be empty and might have quotes or not)
            #  e.g. 'Content-Disposition' = 'attachment; filename="acat.jpg"' -> acat.jpg
            $targetFilename = $response.Headers["Content-Disposition"] -split "filename=" | Select-Object -Last 1 |% { $_.Trim('"') }
            if ($targetFilename -eq "") { $targetFilename = $response.Headers["X-Request-ID"].Trim() }
            
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
        # png and others, like video
        if ($Null -eq (Split-Path $filepath -Leaf).Split(".")[1]) { #PWSH 6+ "" -eq (Split-Path $filepath -Leaf | Split-Path -Extension)
            $type = $response.Headers["Content-Type"] -split ";" | select -First 1 |% { $_ -split "/"} | Select-Object -Last 1
            $filepath += "." + $type
        }
        
        Write-Debug "Filepath: $filepath"
        
        # save the image
        [IO.File]::WriteAllBytes($filepath, $response.Content)

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
