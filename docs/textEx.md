# Ask PollinationsAI with large input Texts and Images

> [!Important]
> ## When to use this? (The difference to `Get-PollinationsAiText`)
>
>`Get-PollinationsAiText` works across any model list (text, audio, video) by using the URL format for Pollination's simple-Endpoints.
>
>`Get-PollinationsAiTextEx` **to support large texts and large texts from files**, it only works for text, images and audio (text to text, image to text, text to speech), using the respective PollinationAi's OpenAI compatible endpoints.

## Usage

```powershell
Get-PollinationsAiTextEx "a cat"
# Ah, a cat – these furry little bundles ...
```

```powershell
Get-PollinationsAiTextEx -?
Get-PollinationsAiTextEx [-content] <string> [-images <string|string[]>] [-settings <hashtable>] [-model <string>] [-assignedModelList <string>] [-POLLINATIONSAI_API_KEY <string>] [-bypassCache] [-colors]
Get-PollinationsAiTextEx [-content] <string> -details [-images <string|string[]>] [-settings <hashtable>] [-model <string>] [-assignedModelList <string>] [-POLLINATIONSAI_API_KEY <string>] [-bypassCache] [-colors]
Get-PollinationsAiTextEx [-content] <string> -save [-images <string|string[]>] [-details] [-settings <hashtable>] [-model <string>] [-assignedModelList <string>] [-POLLINATIONSAI_API_KEY <string>] [-bypassCache]
Get-PollinationsAiTextEx [-content] <string> -out <string> [-images <string|string[]>] [-details] [-settings <hashtable>] [-model <string>] [-assignedModelList <string>] [-POLLINATIONSAI_API_KEY <string>] [-bypassCache]
Get-PollinationsAiTextEx -listModels [-details] [-availableOnlyList] [-POLLINATIONSAI_API_KEY <String>]
Get-PollinationsAiTextEx -getSettingsDefault
```

**Yes:** Optional `<CommonParameters>` is always supported.

## Quickly install it (*install, update*)

```powershell
Install-Module -Name PollinationsAiPS -Force
```

> [!NOTE]
> ➡️ Interchangeably use `Get-PollinationsAiTextEx`, `Get-PAiTxtX`, `gpatx` (aliases)
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
Get-PollinationsAiByok -Add

# or manually:

"`n`n`$env:POLLINATIONSAI_API_KEY = `"sk_..............`"" >> $PROFILE.CurrentUserAllHosts
```
... after restarting your powershell console, the key will be available.

**For different options see [Readme > Bring-Your-Own-Key](https://github.com/BananaAcid/PollinationsAiPS?tab=readme-ov-file#you-might-want-to-add-your-key-as-environment-variable-to-your-profile)**

## Params

> [!IMPORTANT]
> Multi line text input is possible as prompt. But **only text and audio/speech** model lists can be used as long as the selected model has text as input modality.
>
> For all model lists use:
>
> `Get-PollinationsAiText` -> [/docs/textEx.md](https://github.com/BananaAcid/PollinationsAiPS/blob/main/docs/text.md)

| Arg, or Alias | Default | Example | Description |
| --- | --- | --- | --- |
| `<string>` <br>or `-content <string>` <br>or `-prompt <string>` | (required) | `"Some Text-Prompt"` | The **multi line** prompt for the content to be created. |
| `-image <string>` <br>or `-images <string[]>` | | `"https://some_url"`<br>`"https://some_url","https://some_url"` | The images to used with the text prompt. You can provide a base64 encoded image, with the prefix `data:image/png;base64,` or  `data:image/jpeg;base64,` |
| `-model <string>` | `"nova-fast"` | `"gemini"` | The model to use. [Currently available on PollinationsAI](https://enter.pollinations.ai/api/docs#tag/genpollinationsai/GET/image/{prompt}.query.model). |
| `-POLLINATIONSAI_API_KEY <string>` <br>or `-key <string>` | `$env:POLLINATIONSAI_API_KEY` | `sk_12345678901234567890` | Use a PollonationsAI API Key - if left set to "", `$env:POLLINATIONSAI_API_KEY` is being checked. **Note: Add the API key to your environment variables.** |
| `-settings <hashtable>` <br>or `-set <hashtable>` | [see below](#file-ask-pollinations_text-ps1-L159-L162) | `@{seed = 1234567890}` | A hashtable of settings passed to the Pollinations AI API. |
| `-bypassCache` <br>or `-nocache` | | | Only bypasses the cloudflare cache, resulting in a newly generated response. Without, the first request will generate the result, each subsequent request will result in the cached response. |
| `-colors` <br>or `-ansi` | `$env:POLLINATIONSAIPS_COLORS`\|`$false` | | Get colored console output. (Adds a string to the prompt to request ANSI formatting instead of Markdown.) || `-assignedModelList` | | `text` | The endpoint the model is from to use for audio generation (text or audio model list). Set to either `text` or `audio` to prevent 2 extra API calls for checking model lists|
| `-out <string>` | | `answer.txt` | The local path to save the generated text and returns the path. |
| `-save` | | | Will save to the system temp folder and returns the path. |
| `-details` | | | Does not save but and returns `@{ Headers; Content; Uri; [FilePath;] [FormattedContent]` } (`FilePath` only if `-save` or `-out` was used, `FormattedContent` only if `-colors` was used) |
| `-getSettingsDefault` <br>or `-get` | | | Get the default settings for the PollinationsAI API. |
| `-listModels` <br>or `-list` | | | Outputs a table of models, that are [currently available on PollinationsAI](https://enter.pollinations.ai/api/docs#tag/genpollinationsai/GET/image/{prompt}.query.model). |
| `-listModels -details` <br>or `-list -details` | | | Outputs a Hashtable of models, to be used in code. |
| `-availableOnlyList` <br>or `-available` | | | Only get the list of available models available to the Pollinations AI API KEY. |
| `-debug` | | | Outputs the request URI. (This URI does not need authorisation, because it accesses the cached result) |

> [!IMPORTANT]
> Piping into this script, will populate `-content`
> 
> Returns:
> - Default: The generated text
> - `-details`: The headers as and content `@{ Headers; Content; Uri; [FilePath;] [FormattedContent] }`
>   - (`FilePath` only if `-save` or `-out` was used, `FormattedContent` only if `-colors` was used)
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
Get-PollinationsAiTextEx "a cat"
# Ah, a cat – these furry little bundles ...
```

### Generate a text based a file

```powershell
$prompt = Get-Content .\somefile.txt
Get-PollinationsAiTextEx $prompt
```

### Generate a text based a file with a question

```powershell
$prompt = "Summarize the following content in 1 paragraph:" + "`n`n`n" + $(gc .\somefile.txt)
Get-PollinationsAiTextEx $prompt
```

### Get a list of free models, that support input images with `-images`

```powershell
Get-PollinationsAiTextEx -List -Details |? paid_only -eq $false |? input_modalities -contains image | Format-Table
```

### Do some image-to-text with a local image

```powershell
# upload local image to PollinationsAI media storage
$image = Add-PollinationsAiFile .\image.jpg

# use a model that allows image input, and add the image or images
Get-PollinationsAiTextEx "What is on this image?" -Model openai -Image $image

# about 2 at once
$image2 = Add-PollinationsAiFile .\image2.jpg
Get-PollinationsAiTextEx "What is on this images?" -Model openai -Images $image,$image2
```


### Look at some models and test a prompt

See discussion https://github.com/pollinations/pollinations/discussions/7423
