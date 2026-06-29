#Requires AutoHotkey v2.0

#Enter::
{
    home := EnvGet("USERPROFILE")

    ; Alacritty
    ;Run 'alacritty.exe --working-directory "' home '"'

    ; Windows Terminal
    Run 'wt.exe -d "' home '"'
        

    ; WezTerm
    ; Run 'wezterm.exe start --cwd "' home '"'
}
