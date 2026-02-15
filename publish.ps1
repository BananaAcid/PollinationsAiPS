# Fix for -> Write-Error: Failed to generate the compressed file for module 'Cannot index into a null array.'.
$env:DOTNET_CLI_UI_LANGUAGE="en_US"


Test-ModuleManifest -Path ".\PollinationsAiPS\PollinationsAiPS.psd1"
pause
Publish-Module -Path ".\PollinationsAiPS" -NuGetApiKey $env:NUGET_API_KEY -Verbose

<#
# find module
Find-Module PollinationsAiPS

# install test
Install-Module PollinationsAiPS -Scope CurrentUser

# Import test
Import-Module PollinationsAiPS
#>



<# 
New-ModuleManifest -Path ".\PollinationsAiPS\PollinationsAiPS.psd1" `                                                                                                                                                                                                 in pwsh at 18:03:46
    -RootModule "PollinationsAiPS.psm1" `
    -Author "Nabil Redmann (BananaAcid)" `
    -Description "Power up your PowerShell scripts with AI! A seamless interface for Pollinations.ai to generate images, text, and audio. 🤖" `
    -CompanyName "Nabil Redmann" `
    -ModuleVersion "1.0.0" `
    -FunctionsToExport "*" `
    -PowerShellVersion "5.1"
#>