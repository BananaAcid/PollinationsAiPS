# Ask PollinationsAI for an Image

## Usage

```powershell
Get-PollinationsAiImage "a cat" -save
# C:\Users\<username>\AppData\Local\Temp\00974dda-c60c-4c4f-b6bc-4c6e948616d5.jpg
```

```powershell
Get-PollinationsAiImage -?
Get-PollinationsAiImage [-content] <string> [-settings <hashtable>] [-model <string>] [-assignedModelList <string>] [-POLLINATIONSAI_API_KEY <string>] [-bypassCache]
Get-PollinationsAiImage [-content] <string> -details [-settings <hashtable>] [-model <string>] [-assignedModelList <string>] [-POLLINATIONSAI_API_KEY <string>] [-bypassCache]
Get-PollinationsAiImage [-content] <string> -save [-details] [-settings <hashtable>] [-model <string>] [-assignedModelList <string>] [-POLLINATIONSAI_API_KEY <string>] [-bypassCache]
Get-PollinationsAiImage [-content] <string> -out <string> [-details] [-settings <hashtable>] [-model <string>] [-assignedModelList <string>] [-POLLINATIONSAI_API_KEY <string>] [-bypassCache]
Get-PollinationsAiImage -listModels [-details]
Get-PollinationsAiImage -getSettingsDefault
```

**Yes:** Optional `<CommonParameters>` is always supported.

## Quickly install it (*install, update*)

```powershell
Install-Module -Name PollinationsAiPS -Force
```

> [!NOTE]
> ➡️ Interchangeably use `Get-PollinationsAiImage`, `Get-PAiImg`, `gpai` (aliases)
>
> ⭐ After installation, they can be used globally.

<details>
<summary>only download it into your current folder</summary>

```powershell
Save-Module -Name PollinationsAiPS -Path .\   # this creates a subfolder .\PollinationsAiPS\1.0.0\
```
</details>

### You might want to add your key as environment variable to your profile

```powershell
"`n`n`$env:POLLINATIONSAI_API_KEY = `"sk_..............`"" >> $PROFILE.CurrentUserAllHosts
```
... after restarting your powershell console, the key will be available.

## Params

| arg | default | example | desc |
| --- | --- | --- | --- |
| `<string>` <br>or `-content <string>` <br>or `-prompt <string>` | (required) | `"Some Text-Prompt"` | The content to be created. |
| `-model <string>` | `"zimage"` | `"flux"` | The model to use. |
| `-POLLINATIONSAI_API_KEY <string>` <br>or `-key <string>` | `$env:POLLINATIONSAI_API_KEY` | `sk_12345678901234567890` | Use a PollonationsAI API Key - if left set to "", `$env:POLLINATIONSAI_API_KEY` is being checked. **Note: Add the API key to your environment variables.** |
| `-settings <hashtable>` <br>or `-set <hashtable>` | [see below](#file-ask-pollinations_image-ps1-L170-L183) | `@{seed = 2147483647}` | A hashtable of settings passed to the Pollinations AI API. |
| `-bypassCache` <br>or `-nocache` | | | Only bypasses the cloudflare cache, and sets the seed to random, resulting in a newly generated response. Without, the first request will generate the result, each subsequent request will result in the cached response. |
| `-assignedModelList` | | `text` | The endpoint the model is from to use for audio generation (text or audio model list). Set to either `text` or `audio` to prevent 2 extra API calls for checking model lists|
| `-out <string>` | | `acat.jpg` | The local path to save the generated image and returns the path. |
| `-save` | | | Will save to the system temp folder and returns the path. |
| `-details` | | | Does not save the image and returns `@{ Headers; Content; Uri; [FilePath] }` (`FilePath` only if `-save` or `-out` was used)|
| `-getSettingsDefault` <br>or `-get` | | | Get the default settings for the PollinationsAI API. |
| `-listModels` <br>or `-list` | | | Outputs a table of models, that are currently available on PollinationsAI. |
| `-listModels -details` <br>or `-list -details` | | | Outputs a Hashtable of models, to be used in code. |
| `-debug` | | | Outputs the request URI. (This URI does not need authorisation, because it accesses the cached result) |

> [!IMPORTANT]
> Piping into this script, will populate `-content`
> 
> Returns:
> - Default: The generated image as a byte array
> - `-details`: The headers as and content `@{ Headers; Content; Uri; [FilePath]` } (`FilePath` only if `-save` or `-out` was used)
>   - (HTTP-response Headers, Content of the answer, Uri of the cached request)
> - `-save`: The local path to generated file
> - `-out <name.jpg>`: The local path to generated file
>
> **⚠️ Because the comandlet returns the paths or data, you can use it within another script!**

> [!CAUTION]
> on error:
> - throws 
>   ```ps1 
>   @{ StatusCode = <error code>; Message = <error message> }
>   ``` 

> [!NOTE]
> You can always shorten a param (to use `-c` or `-con` instead of `-content`)

        
## Examples

### Look at some models and test a prompt
See discussion https://github.com/pollinations/pollinations/discussions/7415

### Generate an image based on the prompt "a cat"

```powershell
Get-PollinationsAiImage "a cat" -save
# C:\Users\<username>\AppData\Local\Temp\00974dda-c60c-4c4f-b6bc-4c6e948616d5.jpg
```

### Generate an image based on the prompt "a cat" and open it with your default image viewer

`-Debug` shows the used URL and the local file path of the generated image.

```powershell
Get-PollinationsAiImage "a cat" -save -Debug | Invoke-Item
# DEBUG: URI: https://gen.pollinations.ai/image/a%20cat?model=zimage
# DEBUG: Filepath: C:\Users\<username>\AppData\Local\Temp\00974dda-c60c-4c4f-b6bc-4c6e948616d5.jpg
```
        
### Generate an image based on the prompt `"a cat"` using the `flux` model and save it into the local folder as `acat.jpg`

```powershell
Get-PollinationsAiImage -content "a cat" -model flux -out acat
# acat.jpg
```
if .jpg (or .png) is missing, it will be added (depending on the model). 
        
### Generate an Image and save it

```powershell
$c = "England"; Get-PollinationsAiImage "for $c, show the country flag in 3D in the shape of that country with a slight shadow ### DO NOT SHOW ANY PEOPLE" -out .\country_$c
# country_England.jpg
```

### Use different settings

```powershell
PS> $env:POLLINATIONSAI_API_KEY = "sk_..."
PS> $s = Get-PollinationsAiImage -getSettingsDefault  # or: Get-PollinationsAiImage -get
PS> $s
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

PS> $s.width = 512
PS> $s.height = 512
PS> Get-PollinationsAiImage -content "a cat" -settings $s -out acat.jpg
```

1. First set the API key, 
2. then get the default settings, 
3. then output the settings (just by typing $s), 
4. then modify them, 
5. then generate an image based on the prompt "a cat" using the modified settings.

### Generate an image and save it inline in an html file

```powershell
$result = Get-PollinationsAiImage "a cat"
$imgTag = "<center><img src=`"data:image/jpg;base64,{0}`" /></center>" -f [convert]::ToBase64String($result.Content)
$imgTag | Out-File -FilePath test-img.html -Encoding utf8
start test-img.html
```

### Get a list of models and create an image with all of them
```powershell
$models = Get-PollinationsAiImage -list -Details |% {$_.name}
$models |% { Get-PollinationsAiImage "a cat" -model $_ -out imgs\cat_$_.jpg }
# imgs\cat_kontext.jpg
# imgs\cat_turbo.jpg
# ...
```
        
### Tint an image and set as wallpaper
        
1. Get the `Set-Wallpaper` commandlet (choose the updated version) from here: https://www.joseespitia.com/2017/09/15/set-wallpaper-powershell-function/
    - save it as `set-wallpaper.ps1`
    - ⚠️ but **DO NOT** include the last line that says `Set-WallPaper -Image "C:\Wallpaper\Background.jpg" -Style Fit`
        
2. Your script `update.wallpaper.ps1`
    - Prerequisites:
        - Function `Get-PollinationsAiImage` is installed or saved, if saved only, you need to add `Import-Module .\PollinationsAiPS\1.0.0\PollinationsAiPS` after `param`
        - `$env:POLLINATIONSAI_API_KEY = "sk_..."` is set 
    ```ps1
    param ([switch]$Test, [string]$Color)


    $colors = @("green", "blue", "black", "white", "orange", "purple")
    
    # you can check images for image input and outout: `Get-PollinationsAiImage -List`
    $model = "klein-large" # .. is cheaper 0.012/image

    $color = $color ? $color : (Get-Random $colors)

    Write-Output "Setting wallpaper to $color"

    # Only generate if it does not exist, for speed (reduces unnecessary calls and the model takes its time)
    # You can add `width = "3440"; height = "1440";` or whatever you need, to the -Settings to force the output size
    if (-not (Test-path ".\wp_$color.jpg")) {
        Write-Output "Generating new image ..."
        # this might return a cached instance from PollinationsAI without any cost
        $newImage = Get-PollinationsAiImage `
            -Content "change the logo to be in $color with tint in $color" `
            -Settings @{ image = "https://upload.wikimedia.org/wikipedia/en/thumb/8/80/Wikipedia-logo-v2.svg/960px-Wikipedia-logo-v2.svg.png"} `
            -Model $model `
            -Out ".\wp_$color.jpg"
    }
    else {
        $newImage = ".\wp_$color.jpg"
    }

    Write-Output "New image: $newImage"

    # if -Test was used, do not continue
    if ($Test) { return }

    # import the Set-Wallpaper function
    . .\set-wallpaper.ps1

    # set the new wallpaper
    Set-Wallpaper -Image $newImage -Style Center
    ```
    *Logo Reference https://en.wikipedia.org/wiki/File:Wikipedia-logo-v2.svg*
    
> [!NOTE]
> You can test it with (without actually changing the wallpaper):
> ```powershell
> .\update.wallpaper.ps1 -Test
> .\update.wallpaper.ps1 -Test -Color red 
> ```
> And to test changing the wallpaper:
> ```powershell
> .\update.wallpaper.ps1            # random color
> .\update.wallpaper.ps1 -Color red # specifically red color
> ```

3. Use Windows Task Scheduler to set the script to be repeated and be started on system start ...
    <details>
    <summary>example code to manually add it</summary>

    ⚠️ You need to change `pwsh.exe` into `powershell.exe` in the script, if you do not have Powershell 6+ installed.
    ```ps1
    # Define the script path and name for the task
    $scriptPath = "C:\Scripts\update.wallpaper.ps1" # Replace with the actual path to your .ps1 file
    $taskName = "ChangeWallpaperHourlyAtLogon"
    $taskDescription = "Runs update.wallpaper.ps1 every hour after user login"
    
    # Define the action (start powershell.exe with arguments)
    $action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File $scriptPath"
    
    # Define the trigger (at logon, repeating every hour indefinitely)
    # The -AtLogOn trigger doesn't directly support RepetitionInterval in one line
    # We must use a workaround by setting the Repetition properties after creating the task
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    
    # Define the principal (runs as the current user when logged in)
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive
    
    # Register the initial task (without the repetition settings configured directly)
    Register-ScheduledTask -TaskName $taskName -Description $taskDescription -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null
    
    # Retrieve the newly created task object to modify its repetition settings
    $task = Get-ScheduledTask -TaskName $taskName
    
    # Set the repetition interval and duration
    $task.Triggers.Repetition.Interval = (New-TimeSpan -Hours 1)
    $task.Triggers.Repetition.Duration = ([System.TimeSpan]::MaxValue) # Indefinite duration
    
    # Update the task with the modified trigger settings
    $task | Set-ScheduledTask
    ```
    </details>

---
  
License: MIT