# PollinationsAi for PowerShell 

**PollinationsAiPS** is a PowerShell library designed to simplify interactions with the [Pollinations.ai](https://enter.pollinations.ai/) ecosystem. It allows developers and sysadmins to leverage a many powerful AI models for image creation, text generation, and audio processing without leaving the terminal.

**Key Features:**
* **Image Generation:** Create visuals from text prompts with customizable parameters.
* **Text Generation:** Interface with LLMs for chat and text completion.
* **Image to Text:** Talk about any image with your favorite LLM.
* **Audio/Voice:** Support for text-to-speech and speech-to-text (depending on API availability).
* **Pipeline Friendly:** Designed to work with PowerShell objects and pipes.
* **Easy Integration:** Simple to use in your powershell workflows (.NET Framework and .NET Core) and Azure.
* **Cross Platform:** Just runs on Windows, macOS, and Linux. And Docker / Podman. And more.
* **Media Storage:** Supports Pollinations native media storage for image-to-image or image-to-text.

... in pure Powershell 5+ / 7+ (Win, Linux, OSX, Docker, ...) -- PollinationsAI can be used for free (only needs registration, but no moneys)

> [!WARNING]
> PollinationsAI will cache the response to your request indefinitely (possibly the request as well) and the response can be accessed without authentication.
>
> This might be what you are looking for, if you want to get persistent results to a request or want to share the response (the URL visible with `-Debug` is without authentication).
>
> **DO NOT** enter private data (name, address, ...), personal information, information about other people, financial data and other sensetive information. It is not save to use in a corporate environment. **Handle it as if you would post on X / Facebook.**
> 
> See [Discussion](https://github.com/pollinations/pollinations/discussions/7436)

## Just go for it
```powershell
Install-Module -Name PollinationsAiPS -Force ; Import-Module -Name PollinationsAiPS ; Get-PollinationsAiByok -Add | Out-Null

gpat "a cat"
# ... a text about a cat ...

gpai "a cat" -save
# an url to file with a cat
```


## Quickly install it (*install, update*)

```powershell
Install-Module -Name PollinationsAiPS -Force
```
### then make it available in the current session (for immediate use, or start a new shell)
```powershell
Import-Module -Name PollinationsAiPS
```

<details>
<summary>only download it into your current folder</summary>

```powershell
Save-Module -Name PollinationsAiPS -Path .\   # this creates a subfolder .\PollinationsAiPS\1.0.0\
```
</details>

### You might want to add your key as environment variable to your profile

#### [Bring-Your-Own-Key](https://enter.pollinations.ai/api/docs#tag/-bring-your-own-pollen) method - opens a popup for you to accept to generate a temporary key and adds it to your profile (persists)
```powershell
Get-PollinationsAiByok -Add
```

#### [Bring-Your-Own-Key](https://enter.pollinations.ai/api/docs#tag/-bring-your-own-pollen), but only temporary (until you close the terminal/session)
```powershell
Get-PollinationsAiByok -Init
```


#### or manually:
 -  ```powershell
    "`n`n`$env:POLLINATIONSAI_API_KEY = `"sk_..............`"" >> $PROFILE.CurrentUserAllHosts
    ```
    ... after restarting your powershell console, the key will be available. (`sk_...` is the API key you created at [Pollinations.ai](https://enter.pollinations.ai/))

## Documentation (params, examples)

> [!IMPORTANT]
> ⭐ The specific documentation for each command
> - `Get-PollinationsAiText` -> [/docs/text.md](https://github.com/BananaAcid/PollinationsAiPS/blob/main/docs/text.md) (single line input text, but all model lists)
> - `Get-PollinationsAiTextEx` -> [/docs/textEx.md](https://github.com/BananaAcid/PollinationsAiPS/blob/main/docs/textEx.md) (for multiline texts and image to text)
> - `Get-PollinationsAiImage` -> [/docs/image.md](https://github.com/BananaAcid/PollinationsAiPS/blob/main/docs/image.md)
> - `Get-PollinationsAiAudio` -> [/docs/audio.md](https://github.com/BananaAcid/PollinationsAiPS/blob/main/docs/audio.md)
> - `Add-PollinationsAiFile`, ... -> [/docs/files.md](https://github.com/BananaAcid/PollinationsAiPS/blob/main/docs/files.md) (PollinationsAI Storage)
> - `ConvertFrom-PollinationsAIAnsiEscapedString`
> - `Get-PollinationsAiByok`, **Alias**: `Get-PAByok`, `Get-PollinationsAiDeviceToken`
> - `Get-PollinationsAiByokWeb` (Old method, but can be used to redirect to a website that receives the confirmation/apikey)
> ---
> ### Update-Wallpaper - Periodically recolor your desktop wallpaper with AI
> - Is a fully working example project
> - Change the windows wallpaper with AI generated images, based on an existing image, colored and tinted to a specific color
> - [/examples/Update-Wallpaper.ps1](https://github.com/BananaAcid/PollinationsAiPS/blob/main/examples/Update-Wallpaper.README.md)

## Example Usage

### Generate a text based on the prompt "a cat"

```powershell
Get-PollinationsAiText "a cat"
# Ah, a cat – these furry little bundles ...
```
- Aliases: `Get-PollinationsAiText`, `Get-PAiTxt`, `gpat`

### Generate a text based on the prompt "a cat", and show it with cli colors / cli formatting

```powershell
Get-PollinationsAiText "a cat." -colors
# Ah, a cat – these furry little bundles ...
```
- Aliases: `Get-PollinationsAiText`, `Get-PAiTxt`, `gpat`

### Generate a text based on a multiline prompt

```powershell
Get-Content somefile.txt | Get-PollinationsAiTextEx
# ...
Get-PollinationsAiTextEx (Get-Content somefile.txt)
# ...
Get-PollinationsAiTextEx @("line 1", "line 2")
# ...
Get-PollinationsAiTextEx "line 1 `n line 2"
# ...
```
- Aliases: `Get-PollinationsAiTextEx`, `Get-PAiTxtX`, `gpatx`


### Generate an image based on the prompt "a cat"

```powershell
Get-PollinationsAiImage "a cat" -save
# C:\Users\<username>\AppData\Local\Temp\00974dda-c60c-4c4f-b6bc-4c6e948616d5.jpg
```
- Aliases: `Get-PollinationsAiImage`, `Get-PAiImg`, `gpai`

### Generate an audio based on the prompt "a cat"

```powershell
Get-PollinationsAiAudio "a cat" -save
# C:\Users\<username>\AppData\Local\Temp\00974dda-c60c-4c4f-b6bc-4c6e948616d5.mp3
```
- Aliases: `PollinationsAiAudio`, `Get-PAiAud`, `gpaa`

### List models

```powershell
Get-PollinationsAiImage -List
```
All types support `-List`

#### Filter for free and with image-url as input
```powershell
Get-PollinationsAiImage -List -Details |? paid_only -eq $false |? input_modalities -contains image | Format-Table 
```

#### Do some image-to-text with a local image

```powershell
# show a list of models supporting images, to choose from, like gemini-fast
Get-PollinationsAiTextEx -List -Details -available |? input_modalities -contains image | Select paid_only,name,pricing  | Format-Table

# upload local image to PollinationsAI media storage
$imageUrl = Add-PollinationsAiFile .\image.jpg

# use a model that allows image input, and add the image or images
Get-PollinationsAiTextEx "What is on this image?" -Model "gemini-fast" -Image $imageUrl
```