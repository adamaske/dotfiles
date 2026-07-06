' SyncTeX inverse search without the console flash.
' SumatraPDF calls:  wscript.exe "<this file>" <line> "<tex file>"
' wscript is a GUI-subsystem app, so nothing pops up, and Run(..., 0)
' starts the headless nvim helper with its window hidden.
Set shell = CreateObject("WScript.Shell")
line = WScript.Arguments(0)
file = WScript.Arguments(1)
shell.Run "nvim --headless -c ""VimtexInverseSearch " & line & " '" & file & "'""", 0, False
