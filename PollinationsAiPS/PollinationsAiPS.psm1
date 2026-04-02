<#
.SYNOPSIS
    PollinationsAiPS - A seamless interface for Pollinations.ai to generate images, text, and audio
    
.DESCRIPTION
    Copyright (c) 2026 Nabil Redmann
    Licensed under the MIT License.
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files.
#>

# This is the Root Module that loads all components

. $PSScriptRoot\utils.ps1
Set-Alias -Name Get-PAByok -Value Get-PollinationsAiByok
Set-Alias -Name Get-PollinationsAiDeviceToken -Value Get-PollinationsAiByok

. $PSScriptRoot\image.ps1
Set-Alias -Name Get-PAImg -Value Get-PollinationsAiImage

. $PSScriptRoot\text.ps1
Set-Alias -Name Get-PATxt -Value Get-PollinationsAiText

. $PSScriptRoot\textEx.ps1
Set-Alias -Name Get-PATxtX -Value Get-PollinationsAiTextEx

. $PSScriptRoot\audio.ps1
Set-Alias -Name Get-PAAud -Value Get-PollinationsAiAudio

Export-ModuleMember `
    -Function 'Get-PollinationsAiImage', 'Get-PollinationsAiText', 'Get-PollinationsAiTextEx', 'Get-PollinationsAiAudio', `
        'ConvertFrom-AnsiEscapedString', 'Get-PollinationsAiByok', 'Get-PollinationsAiByokWeb' `
    -Alias 'Get-PAImg', 'Get-PATxt',  'Get-PATxtX', 'Get-PAAud', 'Get-PAByok', 'Get-PollinationsAiDeviceToken'

# only export alias, if not already used by some other module
if (-not (test-path Function:gpai)) {
    Set-Alias -Name gpai -Value Get-PollinationsAiImage
    Export-ModuleMember -Alias gpai 
}
if (-not (test-path Function:gpat)) {
    Set-Alias -Name gpat -Value Get-PollinationsAiText
    Export-ModuleMember -Alias gpat
}
if (-not (test-path Function:gpatx)) {
    Set-Alias -Name gpatx -Value Get-PollinationsAiTextEx
    Export-ModuleMember -Alias gpatx
}
if (-not (test-path Function:gpaa)) {
    Set-Alias -Name gpaa -Value Get-PollinationsAiAudio
    Export-ModuleMember -Alias gpaa
}

. $PSScriptRoot\files.ps1
Set-Alias -Name Add-PAFile -Value Add-PollinationsAiFile
Set-Alias -Name Get-PAFile -Value Get-PollinationsAiFile
Set-Alias -Name Test-PAFile -Value Test-PollinationsAiFile
Set-Alias -Name Remove-PAFile -Value Remove-PollinationsAiFile
Set-Alias -Name Export-PAFile -Value Export-PollinationsAiFile
Set-Alias -Name Measure-PAFile -Value Measure-PollinationsAiFile

Export-ModuleMember `
 -Function 'Add-PollinationsAiFile', 'Get-PollinationsAiFile', 'Test-PollinationsAiFile', 'Remove-PollinationsAiFile', 'Export-PollinationsAiFile', 'Measure-PollinationsAiFile' `
 -Alias 'Add-PAFile', 'Get-PAFile', 'Test-PAFile', 'Remove-PAFile', 'Export-PAFile', 'Measure-PAFile', 'apaf', 'gpaf', 'tpaf', 'rpaf', 'epaf'

if (-not (test-path Function:apaf)) {
    Set-Alias -Name apaf -Value Add-PollinationsAiFile
    Export-ModuleMember -Alias apaf
}
if (-not (test-path Function:gpaf)) {
    Set-Alias -Name gpaf -Value Get-PollinationsAiFile
    Export-ModuleMember -Alias gpaf
}
if (-not (test-path Function:tpaf)) {
    Set-Alias -Name tpaf -Value Test-PollinationsAiFile
    Export-ModuleMember -Alias tpaf
}
if (-not (test-path Function:rpaf)) {
    Set-Alias -Name rpaf -Value Remove-PollinationsAiFile
    Export-ModuleMember -Alias rpaf
}
if (-not (test-path Function:epaf)) {
    Set-Alias -Name epaf -Value Export-PollinationsAiFile
    Export-ModuleMember -Alias epaf
}
