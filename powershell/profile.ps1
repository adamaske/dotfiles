Invoke-Expression (&starship init powershell)

Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -MaximumHistoryCount 10000
Set-PSReadLineOption -HistoryNoDuplicates
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

Set-Alias -Name cat -Value bat -Option AllScope -Force
del alias:ls
function ls { eza --icons --group-directories-first $args }
# Optional: for long format by default
# function ll { eza -la --icons --group-directories-first $args }

function cdf {
    $dir = Get-ChildItem -Directory | Select-Object -ExpandProperty Name | fzf --layout=reverse --height=40% --border

    if ($dir) { 
        Set-Location $dir  # <--- Remove the 'f' that was here
    }
}

fastfetch --logo scientific
Write-Host ""

