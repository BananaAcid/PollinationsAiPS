# Ask PollinationsAI for a File

You can add a file, like an image, to the [PollinationsAI Storage](https://enter.pollinations.ai/api/docs#tag/-media-storage) to get an URL to be used for example in image-to-image or image-to-text and so on.

## Usage

```powershell
PS> Add-PollinationsAiFile image.jpg
https://media.pollinations.ai/98dxd8047309ex21

PS> Get-PollinationsAiTextEx "Describe this image" -Image https://media.pollinations.ai/98dxd8047309ex21
This image contains ...


PS> Get-PollinationsAiFile 98dxd8047309ex21 -save
C:\Users\someuser\AppData\Local\Temp\98dxd8047309ex21.jpg

PS> Remove-PollinationsAiFile 98dxd8047309ex21 
True

PS> Test-PollinationsAiFile 98dxd8047309ex21 
False
```

### You might want to add your key as environment variable to your profile

```powershell
Get-PollinationsAiByok -Add

# or manually:

"`n`n`$env:POLLINATIONSAI_API_KEY = `"sk_..............`"" >> $PROFILE.CurrentUserAllHosts
```
... after restarting your powershell console, the key will be available.

**For different options see [Readme > Bring-Your-Own-Key](https://github.com/BananaAcid/PollinationsAiPS?tab=readme-ov-file#you-might-want-to-add-your-key-as-environment-variable-to-your-profile)**


## Commandlets

| Command | Alias | Returns | Description | PollinationsAI Docs, Status Codes |
| --- | --- | --- | --- | --- |
| `Add-PollinationsAiFile <file> [-Details] [-POLLINATIONSAI_API_KEY <key>]` | `Add-PAFile`, `cpaf` | `"URL"`\|`$null`(error) | Upload a file and return the url of the uploaded file for use. Returns an url with a hash, based on the content. Using `-Details` get the an object with details (Content-Type, Content-Length, Hash, ...) | [Upload media](https://enter.pollinations.ai/api/docs#tag/-media-storage/POST/upload) |
| `Get-PollinationsAiFile <hash> [-Save] [-Out <string>] [-Details] [-POLLINATIONSAI_API_KEY <key>]` | `Get-PAFile`, `gpaf` | `Bytes[]`\|`"FilePath"`\|`$null`(error) | Download/retrieve file content by hash. Using `-Details` get the an object with details (Content-Type, Content-Length, Hash, ...) | [Retrieve media](https://enter.pollinations.ai/api/docs#tag/-media-storage/GET/{hash}) |
| `Test-PollinationsAiFile <hash> [-Details] [-POLLINATIONSAI_API_KEY <key>]` | `Test-PAFile`, `tpaf` | `Boolean`\|`$null`(error) | Test if a file exists on the server | [Check if media exists](https://enter.pollinations.ai/api/docs#tag/-media-storage/HEAD/{hash}) |
| `Remove-PollinationsAiFile <hash> [-Details] [-POLLINATIONSAI_API_KEY <key>]` | `Remove-PAFile`, `rpaf` | `Boolean`\|`$null`(error) | Delete a file from the server by hash | [Delete media](https://enter.pollinations.ai/api/docs#tag/-media-storage/DELETE/{hash}) |
| `Export-PollinationsAiFile <hash> [-Details] [-POLLINATIONSAI_API_KEY <key>]` | `Export-PAFile`, `epaf` | `{size, type, dimensions}`\|`$null`(error) | Get metadata information for a file | [Media Storage - Metadata](https://enter.pollinations.ai/api/docs#tag/-media-storage) |
| `Get-PollinationsAiEncodedImage [-Path] <string>  [-Details]` | `Get-PAEncImg`, `gpaei` | Content-Type-prefix + Base64-encoded-file-content, e.g. `data:image/jpeg;base64,/9j/4QMY...` | Encode local image (PNG/JPEG/BMP only) to Base64 with content type prefix, for use as image URI (like with `Get-PollinationsAiTextEx -Image $ImageUri` )<br>⚠️ Using an image encoded this way, doubles the required tokens because of Base64. Using and uploaded images url is reducing the required tokens by a lot. | |
| `Measure-PollinationsAiFile [-Details] [-POLLINATIONSAI_API_KEY <key>]` | `Measure-PAFile` | | Test all file operations (upload, retrieve, delete) | |

**Note:** `-POLLINATIONSAI_API_KEY` alias: `-Key`

> [!IMPORTANT]
> On an error, you can check `$global:LASTEXITCODE` for the HTTP Status code of the last request to the PollinationsAI REST API endpoint.
>
> To not stop on batch actions (piping multiple hashes or files onto the commands), you can use the param `-ErrorAction SilentlyContinue` or in short `-EA:Si` - this will allow you to continue and handle `$null` or the `-Details` returned object `$_.error` (see the examples below)

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
error        - {Message, StatusCode, Uri, ResponseInstance{Content,Headers,..}}, only exists in case of an error
```

Depending on the cmdlet:
```
contentType  - string, only with: Add, Get, Test
duplicate    - boolean, only with: Add
size         - int, only with: Add, Get, Test
filePath     - string, only with: Get
success      - boolean, only with: Test
deleted      - boolean, only with: Remove
data         - object, only with: Export
```

# `Get-PollinationsAiFile`

Mind the different mutually exclusive params:

```ps1
Get-PollinationsAiFile [-Hash] <string> [-Details] [-POLLINATIONSAI_API_KEY <string>]
Get-PollinationsAiFile [-Hash] <string> -Save [-Details] [-POLLINATIONSAI_API_KEY <string>]
Get-PollinationsAiFile [-Hash] <string> -Out <string> [-Details] [-POLLINATIONSAI_API_KEY <string>]
```

| arg | default | example | desc |
| --- | --- | --- | --- |
| `-Hash <string>` | | `98dxd8047309ex21` | The Hash (ID) of the file to refer to |
| `-POLLINATIONSAI_API_KEY <string>` <br>or `-key <string>` | `$env:POLLINATIONSAI_API_KEY` | `sk_12345678901234567890` | Use a PollonationsAI API Key - if left set to "", `$env:POLLINATIONSAI_API_KEY` is being checked. **Note: Add the API key to your environment variables.** |
| `-Out <string>` | | `acat.jpg` | The local path to save the generated image and returns the path. If file extension is omitted, it will try to detect and add it. |
| `-Save` | | | Will save to the system temp folder and returns the path. |
| `-Details` | | | Does not save the file and returns `@{ Headers; Content; uri; [filePath] ... }` (`filePath` only if `-save` or `-out` was used)|



# Examples

## Download 1 image.

```ps1
Get-PAFile 7d6465c83c3371bb -Out image1.jpg

C:\current_folder_name\image1.jpg
```

## Download 3 images. Will output the local file paths in the temp folder.

```ps1
"5a86f1d64c228085", "9f57b28c9d6248bd", "7d6465c83c3371bb" | Get-PAFile -save

C:\Users\someuser\AppData\Local\Temp\5a86f1d64c228085.jpg
C:\Users\someuser\AppData\Local\Temp\9f57b28c9d6248bd.jpg
C:\Users\someuser\AppData\Local\Temp\7d6465c83c3371bb.jpg
```

## Download 3 images. To the current folder with the hashnames (and extension is detected and will be added)

```ps1
"5a86f1d64c228085", "9f57b28c9d6248bd", "7d6465c83c3371bb" |% { Get-PAFile -Hash $_ -Out .\$_ }

C:\current_folder_name\5a86f1d64c228085.jpg
C:\current_folder_name\9f57b28c9d6248bd.jpg
C:\current_folder_name\7d6465c83c3371bb.jpg
```

## Download a bunch of images by getting the hashes from a file. Will output the local file paths in the temp folder.

- `-ErrorAction SilentlyContinue` will prevent aborting if a file was not found and continue (`.error` will be set).
- `-Details` is needed to be able to dig into the error info
- `|%` is `| Foreach-Object` in short

```ps1
Get-Content .\many_hashes.txt | Get-PAFile -Save -Details -ErrorAction SilentlyContinue |% { Write-Host "$($_.hash) -> $( if ($_.error) {$_.error.message} else {$_.filePath} )" }

5a86f1d64c228085 -> C:\Users\someuser\AppData\Local\Temp\5a86f1d64c228085.jpg
9f57b28c9d6248bd -> File not Found
5a86f1d64c228085 -> C:\Users\someuser\AppData\Local\Temp\5a86f1d64c228085.jpg
00a011100000000009 -> Invalid hash format 
```

### Powershell 7+ and shortened
- `??` requires PS7+
```ps1
gc .\many_hashes.txt | gpaf -S -D -EA:Si |% { echo "$($_.hash) -> $( $_.error.message ?? $_.filePath )" }
```

## Add all JPEG images from a folder. Will output the URLs they can be accessed with.

```ps1
dir .\images\*.jpg | Add-PollinationsAiFile

https://media.pollinations.ai/0a90000000000000
https://media.pollinations.ai/0a90000000000000
https://media.pollinations.ai/0a90000000000000
```
