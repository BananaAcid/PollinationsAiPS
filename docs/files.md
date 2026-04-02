# Ask PollinationsAI for a File

You can copy a file, like an image, to the [PollinationsAI Storage](https://enter.pollinations.ai/api/docs#tag/-media-storage) to get an URL to be used for example in image-to-image or image-to-text and so on.

Using PollinationsAiPS, you automagically get a drive `PollinationsAI:` enabled, where you can copy a file to and will get the Hash and URL of the uploaded file.

## Usage

```
> copy image.jpg PollinationsAI:\flowers.jpg
Uploading image.jpg to PollinationsAi: as flowers.jpg...
Done! Hash: 98dxd8x473x9ex21 | Url: https://media.pollinations.ai/98dxd8x473x9ex21 
```


## Possibilities

file item = hash and url, filesize, width and height, content-type

- `cd` into the drive `PollinationsAI:`
- `dir` or `ls` any file
    - `ls | select *` will show all file items and their properties
- `gi` any file, to get the file item
- `cp` or `copy` into or out of the drive
- `rm` or `del` any file

<!-- - `mv` or `rename` any file -->

| command | alias | description
| --- | --- | --- |
`Enable-PollinationsAiDrive [-Name <string>]` | `Set-PADrive [-Name <string>]` | will reconnect the drive, optionally with another name (e.g. 'Polly' because its shorter)
`Get-PollinationsAiDrive` | `Get-PADrive` | will get the current PSDrive object
`Add-PollinationsAiFile <file>`  | `Copy-PAFile <file>` or<br> `cpaf <file>` | will upload it, returns the file item
