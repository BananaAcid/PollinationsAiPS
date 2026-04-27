param([switch]$test)

if (-not $test) {
    
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

}
else {
    
    Write-Host "--------------------------------------"
    Write-Host "Unloading ..."
    Write-Host "--------------------------------------"
    Remove-Module -Name "PollinationsAiPS" -Force | Out-Null
    Remove-Module -Name "PollinationsAiPS Test" -Force | Out-Null

    Get-Module # only list currently loaded

    Write-Host "--------------------------------------"
    Write-Host "Loading ..."
    Write-Host "--------------------------------------"

    $newRoot = $PSScriptRoot + "\PollinationsAIPS"
    New-Module -Name "PollinationsAiPS Test" -ScriptBlock ([Scriptblock]::Create("`$PSScriptRoot = '$newRoot' `n" + (Get-Content .\PollinationsAIPS\PollinationsAIPS.psm1 -raw))) 

    Get-Module # only list currently loaded

    Write-Host "@me Test new functions now, as if they were installed!"

}



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