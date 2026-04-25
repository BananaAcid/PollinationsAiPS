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
Headers  - object, anything the API responed with
Content  - object, the response headers form the API
```

Always: 
```
id    - string, taken from response if possible, usually equal to hash, but PollinationsAI API might change
hash  - string, the file hash
url   - string, the uri used for the REST call
```

Depending on the cmdlet:
```
contentType  - string, only with: Add, Get, Test
duplicate    - boolean, only with: Add
size         - int, only with: add, Get, Test
success      - boolean, only with: Test
deleted      - boolean, only with: Remove
```