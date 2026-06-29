#Requires AutoHotkey v2.0.2+
#SingleInstance Force
SendMode("Input")

; =============================================================================
;  komorebi.ahk  —  hotkey daemon for komorebi (mirrors the Hyprland binds)
;
;  Modifier legend (AutoHotkey):  # = Windows key (SUPER)   + = Shift   ! = Alt
;  Launched by `komorebic start --ahk`, or by start-komorebi.ps1 at login.
;  Reload after edits with  SUPER+SHIFT+R  (also reloads komorebi config).
; =============================================================================

Home := EnvGet("USERPROFILE")

; Run a komorebic command without flashing a console window.
Komorebic(cmd) {
    RunWait("komorebic-no-console.exe " cmd, , "Hide")
}

; Watchdog: keep komorebi alive. If the process ever dies (crash, etc.), restart
; it within ~15s so the WM and Win+arrow/move binds never silently stop working.
; (Win+Shift+Q now PAUSES rather than stops, so this never fights an intentional
; toggle — the process stays alive when paused.)
SetTimer(KeepKomorebiAlive, 15000)
KeepKomorebiAlive() {
    if !ProcessExist("komorebi.exe") {
        cfg := EnvGet("USERPROFILE") "\.config\komorebi\komorebi.json"
        Run('komorebic-no-console.exe start --config "' cfg '"', , "Hide")
    }
}

; --- App launches  (Hyprland exec binds) -------------------------------------
#q::Run("wezterm-gui.exe")                              ; SUPER+Q  terminal  (kitty -> wezterm)
#k::Run("wezterm-gui.exe")                              ; SUPER+K  plain terminal
#Enter::Run('wezterm-gui.exe start --cwd "' Home '"')   ; SUPER+ENTER  terminal at home (old terminal.ahk)
#e::Run("explorer.exe")                                  ; SUPER+E  files  (dolphin -> explorer)
#f::Run("https://www.google.com")                        ; SUPER+F  browser (firefox not installed -> default)
#Space::Send("!{Space}")                                 ; SUPER+SPACE  launcher (rofi -> PowerToys Run)
#r::Send("!{Space}")                                     ; SUPER+R  menu     (hyprlauncher -> PowerToys Run)

; --- psmux session launcher: Win+T leader, then a mnemonic ------------------
;   Win+T then:  d = dev   dc = .config   nw = nirwizard
;                ce = cedanirs   ae = askeengineering
;   ('d' alone waits ~0.6s to see whether 'c' follows for 'dc'.)
#t::WsLeader()

; Win+Shift+T -> admin (elevated) wezterm
#+t::Run('*RunAs "C:\Program Files\WezTerm\wezterm-gui.exe"')

; Win+Shift+H -> launch herdr (agent multiplexer) in a WezTerm window  [trial]
#+h::Run('wezterm-gui.exe start -- "C:\Users\adama\AppData\Local\Programs\Herdr\bin\herdr.exe"')

; --- Window management --------------------------------------------------------
#c::WinClose("A")                       ; SUPER+C        close window
#v::Komorebic("toggle-float")           ; SUPER+V        toggle floating
#+m::Komorebic("manage")                ; SUPER+SHIFT+M  force-manage focused window (e.g. Claude Desktop)
#p::Komorebic("toggle-monocle")         ; SUPER+P        pseudo -> monocle (fullscreen-ish)
#j::Komorebic("cycle-layout next")      ; SUPER+J        togglesplit -> cycle layout
#+Enter::Komorebic("promote")           ; SUPER+SHIFT+E  promote window to main (master)

; --- Focus  (SUPER + arrows) --------------------------------------------------
#Left::Komorebic("focus left")
#Right::Komorebic("focus right")
#Up::Komorebic("focus up")
#Down::Komorebic("focus down")

; --- Move window in layout  (SUPER + SHIFT + arrows) -------------------------
#+Left::Komorebic("move left")
#+Right::Komorebic("move right")
#+Up::Komorebic("move up")
#+Down::Komorebic("move down")

; --- Switch workspace  (SUPER + 1..0  ->  0-indexed komorebi workspaces) -----
#1::Komorebic("focus-workspace 0")
#2::Komorebic("focus-workspace 1")
#3::Komorebic("focus-workspace 2")
#4::Komorebic("focus-workspace 3")
#5::Komorebic("focus-workspace 4")
#6::Komorebic("focus-workspace 5")
#7::Komorebic("focus-workspace 6")
#8::Komorebic("focus-workspace 7")
#9::Komorebic("focus-workspace 8")
#0::Komorebic("focus-workspace 9")

; --- Move window to workspace  (SUPER + SHIFT + 1..0) ------------------------
#+1::Komorebic("move-to-workspace 0")
#+2::Komorebic("move-to-workspace 1")
#+3::Komorebic("move-to-workspace 2")
#+4::Komorebic("move-to-workspace 3")
#+5::Komorebic("move-to-workspace 4")
#+6::Komorebic("move-to-workspace 5")
#+7::Komorebic("move-to-workspace 6")
#+8::Komorebic("move-to-workspace 7")
#+9::Komorebic("move-to-workspace 8")
#+0::Komorebic("move-to-workspace 9")

; --- Daemon control -----------------------------------------------------------
#+r::Reload_()                          ; SUPER+SHIFT+R  reload komorebi + this script
#+q::Komorebic("toggle-pause")          ; SUPER+SHIFT+Q  pause/unpause (was 'stop' — too easy to kill the WM by accident)

Reload_() {
    Komorebic("reload-configuration")
    Reload()
}

; Win+T leader: capture a short mnemonic, then open a WezTerm + herdr workspace.
WsLeader() {
    static names := Map(
        "d",  "dev",
        "dc", "config",
        "nw", "nirwizard",
        "ce", "cedanirs",
        "ae", "askeengineering")
    ToolTip("  herd ▸  d · dc · nw · ce · ae")
    ih := InputHook("L2 T1.5")
    ih.Start()
    ih.Wait()
    ToolTip()
    seq := StrLower(ih.Input)
    name := ""
    if names.Has(seq)
        name := names[seq]
    else if names.Has(SubStr(seq, 1, 1))
        name := names[SubStr(seq, 1, 1)]
    if (name != "")
        Run('wezterm-gui.exe start -- pwsh -NoExit -Command "herd ' name '"')
}

; --- Mouse: SUPER+drag to move (LMB) / resize (RMB) --------------------------
;     Hyprland mod+drag. Works on any window; best on floating ones
;     (use SUPER+V to float a tiled window first).
#LButton:: {
    MouseGetPos(&x0, &y0, &win)
    if !win
        return
    WinGetPos(&wx, &wy, , , win)
    while GetKeyState("LButton", "P") {
        MouseGetPos(&x1, &y1)
        WinMove(wx + (x1 - x0), wy + (y1 - y0), , , win)
    }
}
#RButton:: {
    MouseGetPos(&x0, &y0, &win)
    if !win
        return
    WinGetPos(&wx, &wy, &ww, &wh, win)
    while GetKeyState("RButton", "P") {
        MouseGetPos(&x1, &y1)
        WinMove(wx, wy, Max(150, ww + (x1 - x0)), Max(100, wh + (y1 - y0)), win)
    }
}
