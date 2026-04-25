# Fix for -> Write-Error: Failed to generate the compressed file for module 'Cannot index into a null array.'.
$env:DOTNET_CLI_UI_LANGUAGE="en_US"


Test-ModuleManifest -Path ".\PollinationsAiPS\PollinationsAiPS.psd1"

Test-ModuleManifest -Path ".\PollinationsAiPS\PollinationsAiPS.psd1" | Select-Object -expandproperty exportedcommands | format-table

Write-Host "`n"
Write-Host "1. DID I UPDATE THE: version number IN THE MANIFEST?" -ForegroundColor Yellow
Write-Host "`n"
Write-Host "2. DID I UPDATE THE: changelog url in the README?" -ForegroundColor Yellow
Write-Host "`n"
Write-Host "3. DID I ADD: a new version tag IN THE REPO?" -ForegroundColor Yellow
Write-Host "`n"

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
New-ModuleManifest -Path ".\PollinationsAiPS\PollinationsAiPS.psd1" `
    -RootModule "PollinationsAiPS.psm1" `
    -Author "Nabil Redmann (BananaAcid)" `
    -Description "Power up your PowerShell scripts with AI! A seamless interface for Pollinations.ai to generate images, text, and audio. 🤖" `
    -CompanyName "Nabil Redmann" `
    -ModuleVersion "1.0.0" `
    -FunctionsToExport "*" `
    -PowerShellVersion "5.1"
#>