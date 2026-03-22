function ConvertFrom-AnsiEscapedString {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true, Position=0)]
        [string]$InputValObject
    )

    begin {
        $escChar = [char]27

        function Convert-Escapes {
            param([string]$s)
            if ($null -eq $s) { return $s }

            # Protect fenced triple-backtick blocks first
            $literals = New-Object System.Collections.Generic.List[string]
            $tokenIndex = 0

            # newlines and returns
            $s = $s -replace '(?<!\\)\\n', "`n"
            $s = $s -replace '(?<!\\)\\r', "`r"

            # new lines are messed up
            # # Protect ```...``` (multiline, non-greedy)
            # $s = [Regex]::Replace($s, '```([\s\S]*?)```', {
            #     param($m)
            #     $literals.Add($m.Value)            # store the whole fenced block including backticks
            #     $token = "___ANSI_LITERAL_{0}___" -f $tokenIndex
            #     $tokenIndex++
            #     return $token
            # })

            # Then protect single-backtick inline spans `...` (no newlines)
            $s = [Regex]::Replace($s, '`([^`\r\n]*)`', {
                param($m)
                $literals.Add($m.Value)            # store with backticks
                $token = "___ANSI_LITERAL_{0}___" -f $tokenIndex
                $tokenIndex++
                return $token
            })

            # \x5c033 -> ESC
            $s = $s -replace '\\x5c0*33', $escChar

            # common escape forms
            $s = $s -replace '\\033', $escChar
            $s = $s -replace '\\e', $escChar
            $s = $s -replace '\\x1b', $escChar
            $s = $s -replace '\\x1B', $escChar


            # replace generic \xHH sequences safely
            while ($s -match '\\x([0-9A-Fa-f]{2})') {
                $hex = $matches[1]
                $char = [char]([Convert]::ToInt32($hex,16))
                $s = [Regex]::Replace($s, "\\x$hex", [Regex]::Escape($char), 1)
                $s = $s -replace [Regex]::Escape($char), $char
            }

            # Restore literal spans (tokens replaced with original stored values)
            for ($i = 0; $i -lt $literals.Count; $i++) {
                $token = "___ANSI_LITERAL_{0}___" -f $i
                $orig = $literals[$i]
                # Use Regex::Replace with escaped token -> escaped original, then unescape inserted original
                $s = [Regex]::Replace($s, [Regex]::Escape($token), [Regex]::Escape($orig))
                $s = $s -replace [Regex]::Escape($orig), $orig
            }

            return $s
        }

        $collected = ""
    }

    process {
        $inputVal = $InputValObject
        if ($inputVal -is [System.Array]) {
            $inputVal = ($inputVal -join "`n")
        } elseif ($null -ne $inputVal -and $inputVal -isnot [string]) {
            $inputVal = $inputVal.ToString()
        }

        $out = Convert-Escapes -s $inputVal

        # if ($null -ne $out) {
        #     Write-Host $out  -noNewline
        #     if ($out -match "(`r`n|`n)$") { Write-Host "" }
        # }

        $collected += $out
    }

    end {
        return $collected
    }
}
