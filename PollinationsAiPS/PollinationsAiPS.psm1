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

. $PSScriptRoot\image.ps1
Set-Alias -Name Get-PAImg -Value Get-PollinationsAiImage

. $PSScriptRoot\text.ps1
Set-Alias -Name Get-PATxt -Value Get-PollinationsAiText

. $PSScriptRoot\audio.ps1
Set-Alias -Name Get-PAAud -Value Get-PollinationsAiAudio

Export-ModuleMember -Function 'Get-PollinationsAiImage', 'Get-PollinationsAiText', 'Get-PollinationsAiAudio' -Alias 'Get-PAImg', 'Get-PATxt', 'Get-PAAud'


# only export alias, if not already used by some other module
if (-not (test-path Function:gpai)) {
    Set-Alias -Name gpai -Value Get-PollinationsAiImage
    Export-ModuleMember -Alias gpai 
}
if (-not (test-path Function:gpat)) {
    Set-Alias -Name gpat -Value Get-PollinationsAiText
    Export-ModuleMember -Alias gpat
}
if (-not (test-path Function:gpaa)) {
    Set-Alias -Name gpaa -Value Get-PollinationsAiAudio
    Export-ModuleMember -Alias gpaa
}