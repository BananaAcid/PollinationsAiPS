# Ask PollinationsAI for a Text

## Usage

```powershell
Get-PollinationsAiText "a cat"
# Ah, a cat – these furry little bundles ...
```

```powershell
Get-PollinationsAiText -?
Get-PollinationsAiText [-content] <string> [-settings <hashtable>] [-model <string>] [-assignedModelList <string>] [-POLLINATIONSAI_API_KEY <string>] [-bypassCache]
Get-PollinationsAiText [-content] <string> -details [-settings <hashtable>] [-model <string>] [-assignedModelList <string>] [-POLLINATIONSAI_API_KEY <string>] [-bypassCache]
Get-PollinationsAiText [-content] <string> -save [-details] [-settings <hashtable>] [-model <string>] [-assignedModelList <string>] [-POLLINATIONSAI_API_KEY <string>] [-bypassCache]
Get-PollinationsAiText [-content] <string> -out <string> [-details] [-settings <hashtable>] [-model <string>] [-assignedModelList <string>] [-POLLINATIONSAI_API_KEY <string>] [-bypassCache]
Get-PollinationsAiText -listModels [-details]
Get-PollinationsAiText -getSettingsDefault
```

**Yes:** Optional `<CommonParameters>` is always supported.

## Quickly install it (*install, update*)

```powershell
Install-Module -Name PollinationsAiPS -Force
```

> [!NOTE]
> ➡️ Interchangeably use `Get-PollinationsAiText`, `Get-PAiTxt`, `gpat` (aliases)
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
| `-model <string>` | `"nova-fast"` | `"gemini"` | The model to use. [Currently available on PollinationsAI](https://enter.pollinations.ai/api/docs#tag/genpollinationsai/GET/image/{prompt}.query.model). |
| `-POLLINATIONSAI_API_KEY <string>` <br>or `-key <string>` | `$env:POLLINATIONSAI_API_KEY` | `sk_12345678901234567890` | Use a PollonationsAI API Key - if left set to "", `$env:POLLINATIONSAI_API_KEY` is being checked. **Note: Add the API key to your environment variables.** |
| `-settings <hashtable>` <br>or `-set <hashtable>` | [see below](#file-ask-pollinations_text-ps1-L159-L162) | `@{seed = 1234567890}` | A hashtable of settings passed to the Pollinations AI API. |
| `-bypassCache` <br>or `-nocache` | | | Only bypasses the cloudflare cache, resulting in a newly generated response. Without, the first request will generate the result, each subsequent request will result in the cached response. |
| `-assignedModelList` | | `text` | The endpoint the model is from to use for audio generation (text or audio model list). Set to either `text` or `audio` to prevent 2 extra API calls for checking model lists|
| `-out <string>` | | `answer.txt` | The local path to save the generated text and returns the path. |
| `-save` | | | Will save to the system temp folder and returns the path. |
| `-details` | | | Does not save but and returns `@{ Headers; Content; Uri; [FilePath]` } (`FilePath` only if `-save` or `-out` was used) |
| `-getSettingsDefault` <br>or `-get` | | | Get the default settings for the PollinationsAI API. |
| `-listModels` <br>or `-list` | | | Outputs a table of models, that are [currently available on PollinationsAI](https://enter.pollinations.ai/api/docs#tag/genpollinationsai/GET/image/{prompt}.query.model). |
| `-listModels -details` <br>or `-list -details` | | | Outputs a Hashtable of models, to be used in code. |
| `-debug` | | | Outputs the request URI. (This URI does not need authorisation, because it accesses the cached result) |

> [!IMPORTANT]
> Piping into this script, will populate `-content`
> 
> Returns:
> - Default: The generated text
> - `-details`: The headers as and content `@{ Headers; Content; Uri; [FilePath]` } (`FilePath` only if `-save` or `-out` was used)
>   - (HTTP-response Headers, Content of the answer, Uri of the cached request)
> - `-save`: The local path to generated file
> - `-out <name.txt>`: The local path to generated file
>
> 🗒️ **Textg:** There are some models listed at PollinationsAI with the text models list and some in the audio models list. This module is geared towards text file generation.
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

### Generate a text based on the prompt "a cat"

```powershell
Get-PollinationsAiText "a cat"
# Ah, a cat – these furry little bundles ...
```

### Look at some models and test a prompt

See discussion https://github.com/pollinations/pollinations/discussions/7423