# PollinationsAi for PowerShell 

**PollinationsAiPS** is a PowerShell library designed to simplify interactions with the [Pollinations.ai](https://pollinations.ai/) ecosystem. It allows developers and sysadmins to leverage a many powerful AI models for image creation, text generation, and audio processing without leaving the terminal.

**Key Features:**
* **Image Generation:** Create visuals from text prompts with customizable parameters.
* **Text Generation:** Interface with LLMs for chat and text completion.
* **Audio/Voice:** Support for text-to-speech and speech-to-text (depending on API availability).
* **Pipeline Friendly:** Designed to work with PowerShell objects and pipes.
* **Easy Integration:** Simple to use in your powershell workflows.

... in pure Powershell 5+ / 7+ (Win, Linux, OSX, Docker, ...) -- PollinationsAI can be used for free (only needs registration, but no moneys)

> [!WARNING]
> PollinationsAI will cache the response to your request indefinitely (possibly the request as well) and the response can be accessed without authentication.
>
> This might be what you are looking for, if you want to get persistent results to a request or want to share the response (the URL visible with `-Debug` is without authentication).
>
> **DO NOT** enter private data (name, address, ...), personal information, information about other people, financial data and other sensetive information. It is not save to use in a corporate environment. **Handle it as if you would post on X / Facebook.**
> 
> See [Discussion](https://github.com/pollinations/pollinations/discussions/7436)

## Quickly install it (*install, update*)

```powershell
Install-Module -Name PollinationsAiPS -Force
```
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


## Example Usage

### Generate a text based on the prompt "a cat"

```powershell
Get-PollinationsAiText "a cat"
# Ah, a cat – these furry little bundles ...
```

### Generate an image based on the prompt "a cat"

```powershell
Get-PollinationsAiImage "a cat" -save
# C:\Users\<username>\AppData\Local\Temp\00974dda-c60c-4c4f-b6bc-4c6e948616d5.jpg
```

### Generate an audio based on the prompt "a cat"

```powershell
Get-PollinationsAiAudio "a cat" -save
# C:\Users\<username>\AppData\Local\Temp\00974dda-c60c-4c4f-b6bc-4c6e948616d5.mp3
```


## Documentation (params, examples)

> [!IMPORTANT]
> ⭐ The specific documentation for each command
> - `Get-PollinationsAiText` -> [/docs/text.md](docs/text.md)
> - `Get-PollinationsAiImage` -> [/docs/image.md](docs/image.md)
> - `Get-PollinationsAiAudio` -> [/docs/audio.md](docs/audio.md)