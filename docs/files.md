# Ask PollinationsAI for a File

You can add a file, like an image, to the [PollinationsAI Storage](https://enter.pollinations.ai/api/docs#tag/-media-storage) to get an URL to be used for example in image-to-image or image-to-text and so on.

## Usage

```
> Add-PollinationsAiFile image.jpg
Uploading image.jpg to PollinationsAi
Done! Hash: 98dxd8x473x9ex21 | Url: https://media.pollinations.ai/98dxd8x473x9ex21 
```


## Functions

| command | alias | description
| --- | --- | --- |
`Add-PollinationsAiFile <file>`  | `Copy-PAFile <file>` or<br> `cpaf <file>` | will upload it, returns the file item
