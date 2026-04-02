# Update-Wallpaper - Periodically recolor your background with AI

Change the windows wallpaper with AI generated images, based on an existing image, colored and tinted to a specific color

Works best with logos. Since most AI models have different output sizes. Set your Desktop background color to the same as in -BackgroundColor.

## Usage

```ps1
# list all available free models that are compatible (some might not work)
.\Update-Wallpaper -List

# Test it with an image from the internet (default prompt: recolor and tint)
.\Update-Wallpaper -Image "https://upload.wikimedia.org/wikipedia/en/thumb/8/80/Wikipedia-logo-v2.svg/960px-Wikipedia-logo-v2.svg.png"


# test it with a custom prompt
$Content = "Make it glow in {Color} and fill background with {BackgroundColor} and show some outerspace but less to the image edges"    # we want to center it on the screen and fill the background with black
$Uri = "https://upload.wikimedia.org/wikipedia/commons/thumb/b/bb/Banana_on_whitebackground.jpg/1280px-Banana_on_whitebackground.jpg"
.\Update-Wallpaper -Color yellow -Content $Content -Image $Uri

# get your image ready
Add-PollinationsAiFile .\myImage.jpg  # shows: https://media.pollinations.ai/dc4e764fed4d7a96
.\Update-Wallpaper -Image "https://media.pollinations.ai/dc4e764fed4d7a96"
```

### If you are ready to set automate it

1. edit `.\wallpaper_config.ps1` and add all your tested `-Param Value` as `$Param = "Value"` to it

2. add to windows task scheduler to always run when you get to your desktop
    ```ps1
    .\Update-Wallpaper -Task Add -Inteval (New-TimeSpan -Minutes 10) -ConfigFile (Path-Resolve .\wallpaper_config.ps1)
    ```

To remove the task later on `.\Update-Wallpaper -Task Remove`

### NOTES
All paths should be absolute, when using -TaskScheduler !!!

If a wallpaper_config.ps1 file is found, it will be used as the config

Logo Reference: https://en.wikipedia.org/wiki/File:Wikipedia-logo-v2.svg
