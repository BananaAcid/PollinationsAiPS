# Ask PollinationsAI for a File

You can add a file, like an image, to the [PollinationsAI Storage](https://enter.pollinations.ai/api/docs#tag/-media-storage) to get an URL to be used for example in image-to-image or image-to-text and so on.

## Usage

```powershell
PS> Add-PollinationsAiFile image.jpg
https://media.pollinations.ai/98dxd8x473x9ex21

PS> Remove-PollinationsAiFile 98dxd8x473x9ex21 
True
```

### You might want to add your key as environment variable to your profile

```powershell
Get-PollinationsAiByok -Add

# or manually:

"`n`n`$env:POLLINATIONSAI_API_KEY = `"sk_..............`"" >> $PROFILE.CurrentUserAllHosts
```
... after restarting your powershell console, the key will be available.

**For different options see [Readme > Bring-Your-Own-Key](https://github.com/BananaAcid/PollinationsAiPS?tab=readme-ov-file#you-might-want-to-add-your-key-as-environment-variable-to-your-profile)**


## Functions

| Command | Alias | Returns | Description |
| --- | --- | --- | --- |
| `Add-PollinationsAiFile <file> [-Details] [-POLLINATIONSAI_API_KEY <key>]` | `Add-PAFile`, `cpaf` | "URL" | Upload a file and return the url of the uploaded file for use. Using `-Details` get the an object with details (Content-Type, Content-Length, Hash, ...) |
| `Get-PollinationsAiFile <hash> [-Details] [-POLLINATIONSAI_API_KEY <key>]` | `Get-PAFile`, `gpaf` | File-Content | Download/retrieve file content by hash. Using `-Details` get the an object with details (Content-Type, Content-Length, Hash, ...) |
| `Test-PollinationsAiFile <hash> [-Details] [-POLLINATIONSAI_API_KEY <key>]` | `Test-PAFile`, `tpaf` | Boolean | Test if a file exists on the server |
| `Remove-PollinationsAiFile <hash> [-Details] [-POLLINATIONSAI_API_KEY <key>]` | `Remove-PAFile`, `rpaf` | Boolean | Delete a file from the server by hash |
| `Export-PollinationsAiFile <hash> [-Details] [-POLLINATIONSAI_API_KEY <key>]` | `Export-PAFile`, `epaf` | unknown | Get metadata information for a file |
| `Get-PollinationsAiEncodedImage [-Path] <string>  [-Details] [-POLLINATIONSAI_API_KEY <key>]` | `Get-PAEncImg`, `gpaei` | Content-Type-prefix+Base64 | Encode local image (PNG/JPEG only) to Base64 with content type prefix, for use as image URI (like `Get-PollinationsAiTextEx -Image $ImageUri` ) |
| `Measure-PollinationsAiFile [-Details] [-POLLINATIONSAI_API_KEY <key>]` | `Measure-PAFile` | | Test all file operations (upload, retrieve, delete) |

## `-Details` returns

Always, raw from the REST call
```
Headers     - object, anything the API responed with
Content     - object, the response headers form the API
StatusCode  - int, the status code of the response. Only useful, if you use `-ErrorAction SilentlyContinue`
                   like: `gc .\many_hashes.txt | Get-PollinationsAiFile -Save -Details -ErrorAction SilentlyContinue |% { Write-Host "$($_.hash) -> $( if ($_.error) {$_.error.message} else {$_.filePath} )" }`
```

Always: 
```
id    - string, taken from response if possible, usually equal to hash, but PollinationsAI API might change
hash  - string, the file hash
uri   - string, the uri used for the REST call
```

Depending on the cmdlet:
```
contentType  - string, only with: Add, Get, Test
duplicate    - boolean, only with: Add
size         - int, only with: Add, Get, Test
filePath     - string, only with: Get
success      - boolean, only with: Test
deleted      - boolean, only with: Remove
error        - {Message, StatusCode, Uri, ResponseInstance}, only exists in case of an error, only with Add, Get
```

# `Get-PollinationsAiFile`
```ps1
Get-PollinationsAiFile [-Hash] <string> [-POLLINATIONSAI_API_KEY <string>]
Get-PollinationsAiFile [-Hash] <string> -Details [-POLLINATIONSAI_API_KEY <string>]
Get-PollinationsAiFile [-Hash] <string> -Save [-POLLINATIONSAI_API_KEY <string>] [-Details]
Get-PollinationsAiFile [-Hash] <string> -Out <string> [-POLLINATIONSAI_API_KEY <string>] [-Details]
```

| arg | default | example | desc |
| --- | --- | --- | --- |
| `-Hash <string>` | | `98dxd8x473x9ex21` | The Hash (ID) of the file to refer to |
| `-POLLINATIONSAI_API_KEY <string>` <br>or `-key <string>` | `$env:POLLINATIONSAI_API_KEY` | `sk_12345678901234567890` | Use a PollonationsAI API Key - if left set to "", `$env:POLLINATIONSAI_API_KEY` is being checked. **Note: Add the API key to your environment variables.** |
| `-Out <string>` | | `acat.jpg` | The local path to save the generated image and returns the path. |
| `-Save` | | | Will save to the system temp folder and returns the path. |
| `-Details` | | | Does not save the file and returns `@{ Headers; Content; uri; [filePath] ... }` (`filePath` only if `-save` or `-out` was used)|


